import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../controllers/auth_controller.dart';

class SwipeController extends GetxController {
  static SwipeController get to => Get.find();

  final RxList<UserModel> profiles = <UserModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSwiping = false.obs;

  String get uid => AuthController.to.currentUid ?? '';

  @override
  void onInit() {
    super.onInit();
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    isLoading.value = true;
    try {
      final list = await FirestoreService.getDiscoveryProfiles();
      profiles.assignAll(list);
      currentIndex.value = 0;
    } catch (e) {
      print("Error loading swipe profiles: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Handles the swipe logic. 
  /// Returns a Future<bool> that resolves to true if it's a match.
  Future<bool> handleSwipe(bool like) async {
    if (currentIndex.value >= profiles.length || isSwiping.value) return false;
    
    final target = profiles[currentIndex.value];
    isSwiping.value = true;

    // Optimistic update: move to next card immediately
    final oldIndex = currentIndex.value;
    currentIndex.value++;
    isSwiping.value = false;

    try {
      // Perform network call in background
      final isMatch = await FirestoreService.recordSwipe(
        targetUid: target.uid, 
        isLike: like
      );
      return isMatch;
    } catch (e) {
      print("Error swiping: $e");
      // Optional: rollback if absolutely necessary, but usually we just log error
      return false;
    }
  }

  UserModel? get currentProfile => 
      currentIndex.value < profiles.length ? profiles[currentIndex.value] : null;

  UserModel? get nextProfile => 
      (currentIndex.value + 1) < profiles.length ? profiles[currentIndex.value + 1] : null;

  void undo() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
    }
  }
}
