import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser!.uid;

  /// Swipe phải: lưu like, kiểm tra match
  /// Trả về thông tin user nếu match, null nếu chưa
  Future<Map<String, dynamic>?> swipeRight(String targetUserId) async {
    final batch = _firestore.batch();

    // Lưu like của mình
    final myLikeRef = _firestore
        .collection('likes')
        .doc(currentUserId)
        .collection('liked')
        .doc(targetUserId);
    batch.set(myLikeRef, {'timestamp': FieldValue.serverTimestamp()});
    await batch.commit();

    // Kiểm tra đối phương đã like mình chưa
    final theirLike = await _firestore
        .collection('likes')
        .doc(targetUserId)
        .collection('liked')
        .doc(currentUserId)
        .get();

    if (theirLike.exists) {
      // Đã match! Tạo conversation
      final matchId = _generateMatchId(currentUserId, targetUserId);
      await _createMatch(matchId, currentUserId, targetUserId);

      // Lấy thông tin user đối phương
      final targetUser = await _firestore
          .collection('users')
          .doc(targetUserId)
          .get();

      return {
        'matchId': matchId,
        'userId': targetUserId,
        ...?targetUser.data(),
      };
    }

    return null; // Chưa match
  }

  /// Swipe trái: lưu dislike
  Future<void> swipeLeft(String targetUserId) async {
    await _firestore
        .collection('dislikes')
        .doc(currentUserId)
        .collection('disliked')
        .doc(targetUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }

  /// Tạo match và conversation giữa 2 người
  Future<void> _createMatch(
      String matchId, String user1Id, String user2Id) async {
    final batch = _firestore.batch();

    // Tạo match document
    final matchRef = _firestore.collection('matches').doc(matchId);
    batch.set(matchRef, {
      'users': [user1Id, user2Id],
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Tạo conversation (dùng cho chat)
    final convRef = _firestore.collection('conversations').doc(matchId);
    batch.set(convRef, {
      'participants': [user1Id, user2Id],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': '',
      'unreadCount': {user1Id: 0, user2Id: 0},
    });

    await batch.commit();
  }

  /// Lấy danh sách conversations của user hiện tại
  Stream<QuerySnapshot> getConversations() {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Lấy tin nhắn trong một conversation
  Stream<QuerySnapshot> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Gửi tin nhắn
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required String receiverId,
  }) async {
    final batch = _firestore.batch();

    // Thêm tin nhắn vào subcollection
    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
    });

    // Cập nhật lastMessage của conversation
    final convRef =
    _firestore.collection('conversations').doc(conversationId);
    batch.update(convRef, {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': currentUserId,
      'unreadCount.$receiverId': FieldValue.increment(1),
    });

    await batch.commit();
  }

  /// Đánh dấu tin nhắn đã xem
  Future<void> markAsSeen(String conversationId) async {
    final batch = _firestore.batch();

    // Reset unread count
    final convRef =
    _firestore.collection('conversations').doc(conversationId);
    batch.update(convRef, {
      'unreadCount.$currentUserId': 0,
    });

    // Đánh dấu các tin nhắn chưa đọc là đã xem
    final unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('seen', isEqualTo: false)
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'seen': true});
    }

    await batch.commit();
  }

  /// Kiểm tra 2 user đã match chưa
  Future<bool> isMatched(String targetUserId) async {
    final matchId = _generateMatchId(currentUserId, targetUserId);
    final match =
    await _firestore.collection('matches').doc(matchId).get();
    return match.exists;
  }

  /// Tạo matchId duy nhất từ 2 userId (sort để tránh trùng)
  String _generateMatchId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}