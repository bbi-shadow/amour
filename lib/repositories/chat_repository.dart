import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/base_repository.dart';
import '../core/result.dart';
import '../models/message_model.dart';
import '../utils/app_constants.dart';

/// ══════════════════════════════════════════════════════════════════
/// ChatRepository v2 — All Firestore operations for chat
///   - Pagination support
///   - Delivered status update
///   - Reactions
///   - Unsend / deleteForMe
///   - Image messages
/// ══════════════════════════════════════════════════════════════════
class ChatRepository extends BaseRepository {
  ChatRepository({super.db, super.auth});

  CollectionReference<Map<String, dynamic>> get _conversations =>
      db.collection(AppConstants.colConversations);

  CollectionReference<Map<String, dynamic>> _messages(String convId) =>
      _conversations.doc(convId).collection(AppConstants.colMessages);

  // ── Conversations ──────────────────────────────────────────────

  Stream<List<ConversationModel>> watchConversations() {
    final uid = currentUid;
    if (uid == null) return Stream.value([]);

    return _conversations
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ConversationModel.fromFirestore(d))
          .where((c) => !c.isBlocked)
          .toList();
      list.sort((a, b) =>
          (b.lastMessageTime ?? DateTime(0)).compareTo(a.lastMessageTime ?? DateTime(0)));
      return list;
    }).handleError((e) {
      print('ChatRepo.watchConversations error: $e');
      return <ConversationModel>[];
    });
  }

  Future<Result<void>> createConversation({
    required String conversationId,
    required String user1Id,
    required String user2Id,
  }) async {
    return safeRunOr(
          () async {
        final doc = _conversations.doc(conversationId);
        final snap = await doc.get();
        if (snap.exists) return Result.success(null); // Already exists

        await doc.set({
          'participants': [user1Id, user2Id],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': '',
          'unreadCount': {user1Id: 0, user2Id: 0},
          'isBlocked': false,
          'typing': {user1Id: false, user2Id: false},
          'createdAt': FieldValue.serverTimestamp(),
        });
        return Result.success(null);
      },
      Result.failure('Không thể tạo cuộc trò chuyện'),
    );
  }

  // ── Messages (Realtime) ────────────────────────────────────────

  Stream<List<MessageModel>> watchMessages(String conversationId, {int limit = 30}) {
    return _messages(conversationId)
        .orderBy('timestamp', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => MessageModel.fromFirestore(d)).toList();
    }).handleError((e) {
      print('ChatRepo.watchMessages error: $e');
      return <MessageModel>[];
    });
  }

  /// Load older messages for pagination
  Future<List<MessageModel>> loadOlderMessages(
      String conversationId, {
        required DocumentSnapshot afterDocument,
        int limit = 30,
      }) async {
    try {
      final snap = await _messages(conversationId)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(afterDocument)
          .limit(limit)
          .get();
      final list = snap.docs.map((d) => MessageModel.fromFirestore(d)).toList();
      list.sort((a, b) => (a.timestamp ?? DateTime(0)).compareTo(b.timestamp ?? DateTime(0)));
      return list;
    } catch (e) {
      print('loadOlderMessages error: $e');
      return [];
    }
  }

  // ── Send Messages ──────────────────────────────────────────────

  Future<Result<void>> sendTextMessage({
    required String conversationId,
    required String text,
    required String receiverId,
    String? replyToMessageId,
    String? replyToText,
    String? replyToSenderId,
  }) async {
    final uid = currentUid;
    if (uid == null) return Result.failure('Chưa đăng nhập');

    return safeRunOr(
          () async {
        final batch = db.batch();
        final msgRef = _messages(conversationId).doc();

        batch.set(msgRef, {
          'conversationId': conversationId,
          'senderId': uid,
          'text': text,
          'type': 'text',
          'mediaUrl': null,
          'seen': false,
          'delivered': false,
          'isDeleted': false,
          'deletedFor': {},
          'reaction': {},
          'timestamp': FieldValue.serverTimestamp(),
          if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
          if (replyToText != null) 'replyToText': replyToText,
          if (replyToSenderId != null) 'replyToSenderId': replyToSenderId,
        });

        final convRef = _conversations.doc(conversationId);
        batch.update(convRef, {
          'lastMessage': text,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': uid,
          'unreadCount.$receiverId': FieldValue.increment(1),
        });

        await batch.commit();
        return Result.success(null);
      },
      Result.failure('Không thể gửi tin nhắn'),
    );
  }

  Future<Result<void>> sendImageMessage({
    required String conversationId,
    required String mediaUrl,
    required String receiverId,
  }) async {
    final uid = currentUid;
    if (uid == null) return Result.failure('Chưa đăng nhập');

    return safeRunOr(
          () async {
        final batch = db.batch();
        final msgRef = _messages(conversationId).doc();

        batch.set(msgRef, {
          'conversationId': conversationId,
          'senderId': uid,
          'text': '📷 Ảnh',
          'type': 'image',
          'mediaUrl': mediaUrl,
          'seen': false,
          'delivered': false,
          'isDeleted': false,
          'deletedFor': {},
          'reaction': {},
          'timestamp': FieldValue.serverTimestamp(),
        });

        batch.update(_conversations.doc(conversationId), {
          'lastMessage': '📷 Ảnh',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': uid,
          'unreadCount.$receiverId': FieldValue.increment(1),
        });

        await batch.commit();
        return Result.success(null);
      },
      Result.failure('Không thể gửi ảnh'),
    );
  }

  // ── Message Status ─────────────────────────────────────────────

  /// Mark incoming messages as seen + update unread to 0
  Future<void> markAllAsSeen(String conversationId) async {
    final uid = currentUid;
    if (uid == null) return;

    await safeRun(() async {
      final batch = db.batch();
      final unread = await _messages(conversationId)
          .where('senderId', isNotEqualTo: uid)
          .where('seen', isEqualTo: false)
          .get();

      for (final doc in unread.docs) {
        batch.update(doc.reference, {
          'seen': true,
          'seenAt': FieldValue.serverTimestamp(),
        });
      }

      batch.update(_conversations.doc(conversationId), {
        'unreadCount.$uid': 0,
      });

      await batch.commit();
    });
  }

  /// Mark my messages as delivered (when other user opens chat)
  Future<void> markAsDelivered(String conversationId, String senderId) async {
    await safeRun(() async {
      final batch = db.batch();
      final undelivered = await _messages(conversationId)
          .where('senderId', isEqualTo: senderId)
          .where('delivered', isEqualTo: false)
          .where('seen', isEqualTo: false)
          .get();

      for (final doc in undelivered.docs) {
        batch.update(doc.reference, {'delivered': true});
      }

      await batch.commit();
    });
  }

  // ── Reactions ──────────────────────────────────────────────────

  Future<void> reactToMessage({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    await safeRun(() async {
      await _messages(conversationId).doc(messageId).update({
        'reaction.$uid': emoji,
      });
    });
  }

  Future<void> removeReaction({
    required String conversationId,
    required String messageId,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    await safeRun(() async {
      await _messages(conversationId).doc(messageId).update({
        'reaction.$uid': FieldValue.delete(),
      });
    });
  }

  // ── Delete / Unsend ────────────────────────────────────────────

  /// Thu hồi — cả 2 bên đều thấy "tin nhắn đã thu hồi"
  Future<void> unsendMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await safeRun(() async {
      await _messages(conversationId).doc(messageId).update({
        'isDeleted': true,
        'text': 'Tin nhắn đã được thu hồi',
        'mediaUrl': FieldValue.delete(),
      });
    });
  }

  /// Xoá phía tôi — chỉ ẩn với người dùng hiện tại
  Future<void> deleteForMe({
    required String conversationId,
    required String messageId,
  }) async {
    final uid = currentUid;
    if (uid == null) return;

    await safeRun(() async {
      await _messages(conversationId).doc(messageId).update({
        'deletedFor.$uid': true,
      });
    });
  }
}