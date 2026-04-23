import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../utils/app_constants.dart';
import 'recommendation_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── USER PROFILE & ACTIVITY ──
  static Future<UserModel?> getUser(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  static Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.colUsers).doc(uid).update(data);
  }

  static Future<void> updateActivityStatus(bool showActivity) async {
    if (_uid.isEmpty) return;
    await _db.collection(AppConstants.colUsers).doc(_uid).update({
      'isOnline': showActivity,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot> getAllUsersStream({String? searchQuery}) {
    return _db.collection(AppConstants.colUsers).orderBy('createdAt', descending: true).snapshots();
  }

  // ── CHAT SYSTEM (MESSENGER STYLE) ──

  static Stream<QuerySnapshot> getConversationsStream() {
    return _db.collection(AppConstants.colConversations)
        .where('participants', arrayContains: _uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  static Future<void> markMessagesAsSeen(String conversationId) async {
    if (_uid.isEmpty) return;
    final batch = _db.batch();
    final unreadMsgs = await _db.collection(AppConstants.colConversations)
        .doc(conversationId).collection(AppConstants.colMessages)
        .where('senderId', isNotEqualTo: _uid)
        .where('seen', isEqualTo: false)
        .get();

    for (var doc in unreadMsgs.docs) {
      batch.update(doc.reference, {'seen': true});
    }
    batch.update(_db.collection(AppConstants.colConversations).doc(conversationId), {
      'unreadCount.$_uid': 0,
    });
    await batch.commit();
  }

  static Stream<QuerySnapshot> getMessagesStream(String conversationId) {
    return _db.collection(AppConstants.colConversations)
        .doc(conversationId).collection(AppConstants.colMessages)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // ── FEED & POSTS (THREADS STYLE) ──

  static Stream<List<PostModel>> getFeedStream() {
    return _db.collection('posts').orderBy('createdAt', descending: true).snapshots()
        .map((snap) => snap.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  static Future<void> createPost({required String content, String? imageUrl}) async {
    final user = await getUser(_uid);
    if (user == null) return;
    await _db.collection('posts').add({
      'authorId': _uid,
      'authorName': user.name,
      'authorPhoto': user.photoUrl,
      'content': content,
      'imageUrl': imageUrl,
      'likes': [],
      'reposts': [],
      'bookmarks': [],
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<bool> toggleLikePost(PostModel post, bool isCurrentlyLiked) async {
    final postRef = _db.collection('posts').doc(post.id);
    if (isCurrentlyLiked) {
      await postRef.update({'likes': FieldValue.arrayRemove([_uid])});
      return false;
    } else {
      await postRef.update({'likes': FieldValue.arrayUnion([_uid])});
      return await recordSwipe(targetUid: post.authorId, isLike: true);
    }
  }

  static Future<void> repost(String postId) async {
    await _db.collection('posts').doc(postId).update({
      'reposts': FieldValue.arrayUnion([_uid])
    });
  }

  static Future<void> toggleBookmark(String postId, bool isBookmarked) async {
    final ref = _db.collection('posts').doc(postId);
    if (isBookmarked) {
      await ref.update({'bookmarks': FieldValue.arrayRemove([_uid])});
    } else {
      await ref.update({'bookmarks': FieldValue.arrayUnion([_uid])});
    }
  }

  // ── COMMENTS ──
  static Stream<List<CommentModel>> getComments(String postId) {
    return _db.collection('posts').doc(postId).collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
  }

  static Future<void> addComment(String postId, String content) async {
    final user = await getUser(_uid);
    if (user == null) return;
    final batch = _db.batch();
    final postRef = _db.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc();

    batch.set(commentRef, {
      'authorId': _uid,
      'authorName': user.name,
      'authorPhoto': user.photoUrl,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(postRef, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
  }

  // ── DISCOVERY & MATCHING ──

  static Future<List<UserModel>> getDiscoveryProfiles() async {
    final myDoc = await _db.collection(AppConstants.colUsers).doc(_uid).get();
    if (!myDoc.exists) return [];
    final me = UserModel.fromFirestore(myDoc);
    
    final allUsersSnap = await _db.collection(AppConstants.colUsers).limit(50).get();
    var candidates = allUsersSnap.docs
        .where((doc) => doc.id != _uid)
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
    return await RecommendationService.getRecommendations(me, candidates);
  }

  static Future<bool> recordSwipe({required String targetUid, required bool isLike}) async {
    return await RecommendationService.recordSwipe(targetUid: targetUid, isLike: isLike);
  }

  // ── CALLS & NOTIFICATIONS ──

  static Stream<QuerySnapshot> incomingCallStream() {
    return _db.collection(AppConstants.colCalls)
        .where('receiverId', isEqualTo: _uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots();
  }

  static Stream<DocumentSnapshot> watchCall(String callId) {
    return _db.collection(AppConstants.colCalls).doc(callId).snapshots();
  }

  static Future<void> updateCallStatus(String callId, String status, {int? duration}) async {
    final data = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (duration != null) data['duration'] = duration;
    await _db.collection(AppConstants.colCalls).doc(callId).set(data, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot> getNotificationsStream() {
    return _db.collection(AppConstants.colNotifications)
        .where('userId', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> markNotificationRead(String docId) async {
    await _db.collection(AppConstants.colNotifications).doc(docId).update({'isRead': true});
  }

  // ── ADMIN ──
  static Future<Map<String, int>> getStats() async {
    final u = await _db.collection(AppConstants.colUsers).count().get();
    final m = await _db.collection(AppConstants.colMatches).count().get();
    final p = await _db.collection('posts').count().get();
    return {'users': u.count ?? 0, 'matches': m.count ?? 0, 'posts': p.count ?? 0, 'reports': 0};
  }

  static Future<void> deleteAllFakeUsers() async {
    final users = await _db.collection(AppConstants.colUsers).get();
    final batch = _db.batch();
    for (var doc in users.docs) {
      if (doc.id.startsWith('fake_')) batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
