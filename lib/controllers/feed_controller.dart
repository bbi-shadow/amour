import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../services/upload_service.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

class FeedController extends GetxController {
  static FeedController get to => Get.find();

  // -- States --
  final RxList<PostModel> posts = <PostModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isPosting = false.obs;
  final Rx<XFile?> selectedImage = Rx<XFile?>(null);
  // FIX: danh sách uid mà user đang follow, dùng cho tab "Theo dõi"
  final RxList<String> followingIds = <String>[].obs;

  String get currentUid => AuthController.to.currentUid ?? '';

  @override
  void onInit() {
    super.onInit();
    listenToFeed();
    _loadFollowingIds();
  }

  void listenToFeed() {
    FirestoreService.getFeedStream().listen((list) {
      posts.assignAll(list);
      isLoading.value = false;
    });
  }

  // Load danh sách người đang theo dõi từ Firestore
  Future<void> _loadFollowingIds() async {
    if (currentUid.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(currentUid)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final List<dynamic> ids = data['following'] ?? [];
        followingIds.assignAll(ids.cast<String>());
      }
    } catch (e) {
      print('Error loading followingIds: $e');
    }
  }

  // Theo dõi / Bỏ theo dõi một user
  Future<void> toggleFollow(String targetUid) async {
    if (currentUid.isEmpty || targetUid == currentUid) return;
    final isFollowing = followingIds.contains(targetUid);
    final batch = FirebaseFirestore.instance.batch();
    final myRef = FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(currentUid);
    final theirRef = FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(targetUid);

    if (isFollowing) {
      batch.update(myRef, {'following': FieldValue.arrayRemove([targetUid])});
      batch.update(theirRef, {'followers': FieldValue.arrayRemove([currentUid])});
      followingIds.remove(targetUid);
    } else {
      batch.update(myRef, {'following': FieldValue.arrayUnion([targetUid])});
      batch.update(theirRef, {'followers': FieldValue.arrayUnion([currentUid])});
      followingIds.add(targetUid);
    }
    await batch.commit();
  }

  // Xóa một người khỏi danh sách followers của mình
  Future<void> removeFollower(String followerUid) async {
    if (currentUid.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    final myRef = FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(currentUid);
    final theirRef = FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(followerUid);
    batch.update(myRef, {'followers': FieldValue.arrayRemove([followerUid])});
    batch.update(theirRef, {'following': FieldValue.arrayRemove([currentUid])});
    await batch.commit();
    AppHelpers.showSuccess('Đã xóa khỏi danh sách người theo dõi');
  }


  Future<void> pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 70);
      if (picked != null) selectedImage.value = picked;
    } catch (e) {
      AppHelpers.showError("Khong the truy cap anh");
    }
  }

  void clearSelectedImage() => selectedImage.value = null;

  Future<bool> createPost(String content) async {
    if (content.trim().isEmpty && selectedImage.value == null) return false;
    if (isPosting.value) return false; // chống double-tap

    isPosting.value = true;
    try {
      String? imageUrl;

      // Upload ảnh nếu có, với timeout 30s
      if (selectedImage.value != null) {
        imageUrl = await UploadService.uploadImage(File(selectedImage.value!.path))
            .timeout(const Duration(seconds: 30), onTimeout: () {
          AppHelpers.showError("Upload ảnh quá thời gian, thử lại");
          return null;
        });
        // Nếu upload thất bại, hỏi user có muốn đăng không ảnh không
        if (imageUrl == null) {
          isPosting.value = false;
          return false;
        }
      }

      // Lưu Firestore với timeout 15s
      final success = await FirestoreService.createPost(
        content: content.trim(),
        imageUrl: imageUrl,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        AppHelpers.showError("Mạng chậm, thử lại sau");
        return false;
      });

      if (success) {
        clearSelectedImage();
        AppHelpers.showSuccess("Đã đăng bài viết");
        return true;
      } else {
        AppHelpers.showError("Không thể đăng bài, thử lại");
      }
    } catch (e) {
      print("createPost error: $e");
      AppHelpers.showError("Đã xảy ra lỗi, thử lại");
    } finally {
      // QUAN TRỌNG: luôn reset isPosting dù success hay fail
      isPosting.value = false;
    }
    return false;
  }

  Future<void> toggleLike(PostModel post) async {
    if (currentUid.isEmpty) return;
    final bool isCurrentlyLiked = post.likes.contains(currentUid);
    await FirestoreService.toggleLikePost(post, isCurrentlyLiked);
  }

  Future<void> deletePost(String postId) async {
    final confirmed = await AppHelpers.confirm(
        title: "Xoa bai viet",
        message: "Ban co chac chan muon xoa bai viet nay?"
    );
    if (!confirmed) return;

    try {
      await FirebaseFirestore.instance.collection(AppConstants.colPosts).doc(postId).delete();
      AppHelpers.showSuccess("Da xoa bai viet");
    } catch (e) {
      AppHelpers.showError("Khong the xoa bai viet");
    }
  }

  Future<void> addComment(String postId, String content) async {
    if (content.trim().isEmpty) return;
    await FirestoreService.addComment(postId, content.trim());
  }

  Stream<List<CommentModel>> getComments(String postId) {
    return FirestoreService.getComments(postId);
  }
}