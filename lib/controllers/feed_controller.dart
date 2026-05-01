import 'dart:io';
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

  String get currentUid => AuthController.to.currentUid ?? '';

  @override
  void onInit() {
    super.onInit();
    listenToFeed();
  }

  void listenToFeed() {
    FirestoreService.getFeedStream().listen((list) {
      posts.assignAll(list);
      isLoading.value = false;
    });
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
    
    isPosting.value = true;
    try {
      String? imageUrl;
      if (selectedImage.value != null) {
        imageUrl = await UploadService.uploadImage(File(selectedImage.value!.path));
      }

      final success = await FirestoreService.createPost(
        content: content.trim(),
        imageUrl: imageUrl,
      );

      if (success) {
        clearSelectedImage();
        AppHelpers.showSuccess("Da dang bai viet");
        return true;
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isPosting.value = false;
    }
    return false;
  }

  Future<void> toggleLike(PostModel post) async {
    if (currentUid.isEmpty) return;
    final bool isCurrentlyLiked = post.likes.contains(currentUid);
    await FirestoreService.toggleLikePost(post, isCurrentlyLiked);
  }
}
