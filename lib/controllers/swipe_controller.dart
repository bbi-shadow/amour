import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

class SwipeController extends GetxController {
  static SwipeController get to => Get.find();

  final RxList<UserModel> profiles = <UserModel>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = true.obs;
  final RxBool isLiked = false.obs;

  // Thêm getter uid bị thiếu
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

  Future<bool> handleSwipe(bool like) async {
    if (currentIndex.value >= profiles.length) return false;
    
    final target = profiles[currentIndex.value];
    isLiked.value = like;

    try {
      final isMatch = await FirestoreService.recordSwipe(
        targetUid: target.uid, 
        isLike: like
      );
      
      currentIndex.value++;
      return isMatch;
    } catch (e) {
      print("Error swiping: $e");
      return false;
    } finally {
      isLiked.value = false;
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
