import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/base_repository.dart';
import '../core/result.dart';
import '../models/message_model.dart';
import '../utils/app_constants.dart';

/// ══════════════════════════════════════════════════════════════
/// ChatRepository — Quản lý toàn bộ thao tác chat
/// ══════════════════════════════════════════════════════════════
class ChatRepository extends BaseRepository {
  ChatRepository({super.db, super.auth});

  CollectionReference<Map<String, dynamic>> get _conversations =>
      db.collection(AppConstants.colConversations);

  CollectionReference<Map<String, dynamic>> _messages(String convId) =>
      _conversations.doc(convId).collection(AppConstants.colMessages);

  // ── CONVERSATIONS ───────────────────────────────────────────

  Stream<List<ConversationModel>> watchConversations() {
    final uid = currentUid;
    if (uid == null) return Stream.value([]);

    return _conversations
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ConversationModel.fromFirestore(d))
          .toList();
      list.sort((a, b) =>
          (b.lastMessageTime ?? DateTime(0))
              .compareTo(a.lastMessageTime ?? DateTime(0)));
      return list;
    }).handleError((e) {
      print("ChatRepo Error: $e");
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
        await _conversations.doc(conversationId).set({
          'participants': [user1Id, user2Id],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderId': '',
          'unreadCount': {user1Id: 0, user2Id: 0},
          'isBlocked': false,
        });
        return Result.success(null);
      },
      Result.failure('Không thể tạo cuộc trò chuyện'),
    );
  }

  // ── MESSAGES ────────────────────────────────────────────────

  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _messages(conversationId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => MessageModel.fromFirestore(d))
          .toList();
      list.sort((a, b) =>
          (a.timestamp ?? DateTime(0)).compareTo(b.timestamp ?? DateTime(0)));
      return list;
    }).handleError((e) {
      print("MessageRepo Error: $e");
      return <MessageModel>[];
    });
  }

  Future<Result<void>> sendMessage({
    required String conversationId,
    required String text,
    required String receiverId,
    MessageType type = MessageType.text,
    String? mediaUrl,
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
          'type': type.name,
          'mediaUrl': mediaUrl,
          'seen': false,
          'isDeleted': false,
          'timestamp': FieldValue.serverTimestamp(),
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
        batch.update(doc.reference, {'seen': true});
      }

      batch.update(_conversations.doc(conversationId), {
        'unreadCount.$uid': 0,
      });

      await batch.commit();
    });
  }
}
