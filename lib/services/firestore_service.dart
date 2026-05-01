import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/notification_model.dart';
import '../models/match_model.dart';
import '../models/call_model.dart';
import '../utils/app_constants.dart';
import 'recommendation_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  static final RecommendationService _recommendationService = RecommendationService();

  // -- USER PROFILE --
  static Future<UserModel?> getUser(String uid) async {
    if (uid.isEmpty) return null;
    final doc = await _db.collection(AppConstants.colUsers).doc(uid).get();
    if (doc.exists) return UserModel.fromFirestore(doc);
    return null;
  }

  static Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection(AppConstants.colUsers).doc(uid).set(data, SetOptions(merge: true));
  }

  static Future<void> updateActivityStatus(bool online) async {
    if (_uid.isEmpty) return;
    await _db.collection(AppConstants.colUsers).doc(_uid).set({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot> getAllUsersStream() {
    return _db.collection(AppConstants.colUsers).snapshots();
  }

  // -- CHAT SYSTEM --
  static Stream<QuerySnapshot> getConversationsStream() {
    return _db
        .collection(AppConstants.colConversations)
        .where('participants', arrayContains: _uid)
        .snapshots();
  }

  static Future<void> markMessagesAsSeen(String conversationId) async {
    if (_uid.isEmpty) return;
    final batch = _db.batch();
    final unreadMsgs = await _db
        .collection(AppConstants.colConversations)
        .doc(conversationId)
        .collection(AppConstants.colMessages)
        .where('senderId', isNotEqualTo: _uid)
        .where('seen', isEqualTo: false)
        .get();

    for (var doc in unreadMsgs.docs) {
      batch.update(doc.reference, {'seen': true});
    }
    batch.update(
      _db.collection(AppConstants.colConversations).doc(conversationId),
      {'unreadCount.$_uid': 0},
    );
    await batch.commit();
  }

  // -- RECOMMENDATION & DISCOVERY --
  static Future<List<UserModel>> getDiscoveryProfiles() async {
    final myDoc = await _db.collection(AppConstants.colUsers).doc(_uid).get();
    if (!myDoc.exists) return [];
    final me = UserModel.fromFirestore(myDoc);

    final allUsersSnap = await _db.collection(AppConstants.colUsers).limit(50).get();
    final candidates = allUsersSnap.docs
        .where((doc) => doc.id != _uid)
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();

    return await _recommendationService.getRecommendations(me, candidates);
  }

  static Future<bool> recordSwipe({
    required String targetUid,
    required bool isLike,
  }) async {
    await _db
        .collection(AppConstants.colSwipes)
        .doc(_uid)
        .collection('actions')
        .doc(targetUid)
        .set({
      'isLike': isLike,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (isLike) {
      final otherSwipe = await _db
          .collection(AppConstants.colSwipes)
          .doc(targetUid)
          .collection('actions')
          .doc(_uid)
          .get();
      if (otherSwipe.exists && otherSwipe.data()?['isLike'] == true) {
        // MATCH FOUND
        final matchId = ([_uid, targetUid]..sort()).join('_');
        await _db.collection(AppConstants.colMatches).doc(matchId).set({
          'users': [_uid, targetUid],
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        
        // Create conversation
        await _db.collection(AppConstants.colConversations).doc(matchId).set({
          'participants': [_uid, targetUid],
          'lastMessage': 'Ban da match voi nhau!',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {_uid: 0, targetUid: 0},
        });
        
        return true; 
      }
    }
    return false;
  }

  // -- CALLS --
  static Stream<QuerySnapshot> incomingCallStream() {
    return _db
        .collection(AppConstants.colCalls)
        .where('receiverId', isEqualTo: _uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots();
  }

  static Future<void> updateCallStatus(String callId, String status, {int? duration}) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (duration != null) data['duration'] = duration;
    await _db.collection(AppConstants.colCalls).doc(callId).set(data, SetOptions(merge: true));
  }

  static Stream<DocumentSnapshot> watchCall(String callId) {
    return _db.collection(AppConstants.colCalls).doc(callId).snapshots();
  }

  // -- FEED SYSTEM --
  static Future<bool> createPost({required String content, String? imageUrl}) async {
    if (_uid.isEmpty) return false;
    final user = await getUser(_uid);
    if (user == null) return false;

    try {
      await _db.collection(AppConstants.colPosts).add({
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
      return true;
    } catch (e) {
      return false;
    }
  }

  static Stream<List<PostModel>> getFeedStream() {
    return _db.collection(AppConstants.colPosts)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  static Future<void> toggleLikePost(PostModel post, bool isLiked) async {
    final ref = _db.collection(AppConstants.colPosts).doc(post.id);
    if (isLiked) {
      await ref.update({'likes': FieldValue.arrayRemove([_uid])});
    } else {
      await ref.update({'likes': FieldValue.arrayUnion([_uid])});
    }
  }

  static Future<void> addComment(String postId, String content) async {
    final user = await getUser(_uid);
    if (user == null) return;
    await _db.collection(AppConstants.colPosts).doc(postId).collection('comments').add({
      'authorId': _uid,
      'authorName': user.name,
      'authorPhoto': user.photoUrl,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection(AppConstants.colPosts).doc(postId).update({
      'commentCount': FieldValue.increment(1)
    });
  }

  static Stream<List<CommentModel>> getComments(String postId) {
    return _db.collection(AppConstants.colPosts).doc(postId).collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => CommentModel.fromFirestore(doc)).toList());
  }

  static Future<void> repost(String postId) async {
    await _db.collection(AppConstants.colPosts).doc(postId).update({
      'reposts': FieldValue.arrayUnion([_uid])
    });
  }

  static Future<void> toggleBookmark(String postId, bool isBookmarked) async {
    final ref = _db.collection(AppConstants.colPosts).doc(postId);
    if (isBookmarked) {
      await ref.update({'bookmarks': FieldValue.arrayRemove([_uid])});
    } else {
      await ref.update({'bookmarks': FieldValue.arrayUnion([_uid])});
    }
  }

  // -- NOTIFICATIONS --
  static Stream<QuerySnapshot> getNotificationsStream() {
    return _db.collection(AppConstants.colUsers).doc(_uid).collection('notifications')
        .orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> markNotificationRead(String id) async {
    await _db.collection(AppConstants.colUsers).doc(_uid).collection('notifications').doc(id).update({'isRead': true});
  }

  static Future<void> markAllNotificationsRead() async {
    final snap = await _db.collection(AppConstants.colUsers).doc(_uid).collection('notifications').where('isRead', isEqualTo: false).get();
    final batch = _db.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // -- ADMIN --
  static Future<Map<String, int>> getStats() async {
    final users = await _db.collection(AppConstants.colUsers).count().get();
    final posts = await _db.collection(AppConstants.colPosts).count().get();
    final matches = await _db.collection(AppConstants.colMatches).count().get();
    final reports = await _db.collection(AppConstants.colReports).count().get();
    
    return {
      'users': users.count ?? 0,
      'posts': posts.count ?? 0,
      'matches': matches.count ?? 0,
      'reports': reports.count ?? 0,
    };
  }

  static Future<void> deleteAllFakeUsers() async {
    final snap = await _db.collection(AppConstants.colUsers)
        .where('email', isGreaterThanOrEqualTo: 'fake_')
        .get();
    final batch = _db.batch();
    for (var doc in snap.docs) { batch.delete(doc.reference); }
    await batch.commit();
  }
}
