import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_settings_model.dart';
import '../models/post_model.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  // -- States (Reactive) --
  final RxMap<String, dynamic> userData = <String, dynamic>{}.obs;
  final RxInt matchCount = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSettingsLoading = false.obs;
  final Rx<UserSettingsModel> settings = UserSettingsModel().obs;
  final RxList<PostModel> myPosts = <PostModel>[].obs;
  
  StreamSubscription? _userSub;
  StreamSubscription? _postsSub;

  String get uid => AuthController.to.currentUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void onInit() {
    super.onInit();
    if (uid.isNotEmpty) {
      _listenToProfile();
      _listenToMyPosts();
      loadMatchCount();
    }
  }

  @override
  void onClose() {
    _userSub?.cancel();
    _postsSub?.cancel();
    super.onClose();
  }

  // -- Logic: Real-time Listening --
  void _listenToProfile() {
    _userSub = FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null) {
        userData.value = doc.data()!;
        settings.value = UserSettingsModel.fromMap(userData.value);
      }
      isLoading.value = false;
    });
  }

  void _listenToMyPosts() {
    _postsSub = FirebaseFirestore.instance
        .collection(AppConstants.colPosts)
        .where('authorId', isEqualTo: uid)
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((d) => PostModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      myPosts.value = list;
    });
  }

  Future<void> loadMatchCount() async {
    try {
      final m = await FirebaseFirestore.instance
          .collection(AppConstants.colMatches)
          .where('users', arrayContains: uid).get();
      matchCount.value = m.docs.length;
    } catch (_) {}
  }

  // -- Data Operations --
  Future<void> updateSetting(String key, dynamic value) async {
    try {
      // Optimistic update local state
      final currentMap = settings.value.toMap();
      currentMap[key] = value;
      settings.value = UserSettingsModel.fromMap(currentMap);
      
      await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(uid)
          .update({key: value});
    } catch (e) {
      print("Error saving $key: $e");
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection(AppConstants.colPosts).doc(postId).delete();
      AppHelpers.showSuccess("Da xoa bai dang");
    } catch (e) {
      AppHelpers.showError("Loi khi xoa");
    }
  }

  Future<void> updatePostContent(String postId, String content) async {
    try {
      await FirebaseFirestore.instance.collection(AppConstants.colPosts).doc(postId).update({'content': content});
      AppHelpers.showSuccess("Da cap nhat bai dang");
    } catch (e) {
      AppHelpers.showError("Loi khi cap nhat: $e");
    }
  }

  Future<void> deleteAccount() async {
    final confirmed = await AppHelpers.confirm(
      title: "Xoa tai khoan",
      message: "Hanh dong nay khong the hoan tac. Moi du lieu se bi xoa vinh vien."
    );
    if (!confirmed) return;

    try {
      isLoading.value = true;
      await FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).delete();
      await FirebaseAuth.instance.currentUser?.delete();
      Get.offAllNamed(AppRoutes.login);
      AppHelpers.showSuccess("Da xoa tai khoan");
    } catch (e) {
      AppHelpers.showError("Loi khi xoa tai khoan. Vui long dang nhap lai roi thu lai.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    await loadMatchCount();
    isLoading.value = false;
  }

  void logout() => AuthController.to.logout();
}
