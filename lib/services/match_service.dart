import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Xử lý khi người dùng like ai đó
  Future<void> likeUser(String likedUserId) async {
    final currentUid = _auth.currentUser!.uid;

    // Lưu like vào Firestore
    await _firestore
        .collection('likes')
        .doc(currentUid)
        .collection('likedUsers')
        .doc(likedUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});

    // Kiểm tra người kia có like mình không
    final theyLikedMe = await _firestore
        .collection('likes')
        .doc(likedUserId)
        .collection('likedUsers')
        .doc(currentUid)
        .get();

    // Nếu 2 người cùng like → tạo match
    if (theyLikedMe.exists) {
      await _createMatch(currentUid, likedUserId);
    }
  }

  // Tạo match khi 2 người cùng like
  Future<void> _createMatch(String uid1, String uid2) async {
    final matchId = uid1.compareTo(uid2) < 0
        ? '${uid1}_${uid2}'
        : '${uid2}_${uid1}';

    await _firestore.collection('matches').doc(matchId).set({
      'users': [uid1, uid2],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageTime': null,
    });
  }

  // Lấy danh sách match của mình
  Stream<QuerySnapshot> getMyMatches() {
    final currentUid = _auth.currentUser!.uid;
    return _firestore
        .collection('matches')
        .where('users', arrayContains: currentUid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}