import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

class ProfileDetailController extends GetxController {
  final UserModel user;
  ProfileDetailController({required this.user});

  final RxBool isMatched = false.obs;
  final RxString conversationId = ''.obs;
  final RxInt currentPhotoIndex = 0.obs;

  String get myId => AuthController.to.currentUid ?? '';

  @override
  void onInit() {
    super.onInit();
    checkMatchStatus();
  }

  Future<void> checkMatchStatus() async {
    if (myId.isEmpty) return;
    final matchId = ([myId, user.uid]..sort()).join('_');
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.colMatches)
          .doc(matchId)
          .get();
      if (doc.exists) {
        isMatched.value = true;
        conversationId.value = matchId;
      }
    } catch (e) {
      print("Error checking match: $e");
    }
  }

  Future<bool> handleSwipe() async {
    final success = await FirestoreService.recordSwipe(targetUid: user.uid, isLike: true);
    if (success) {
      await checkMatchStatus();
      return isMatched.value;
    } else {
      Get.back();
      AppHelpers.showSuccess("Da thich ${user.name}");
      return false;
    }
  }

  Future<void> initiateCall({required bool isVideo}) async {
    if (conversationId.value.isEmpty) return;

    await FirebaseFirestore.instance.collection(AppConstants.colCalls).doc(conversationId.value).set({
      'callerId': myId,
      'receiverId': user.uid,
      'status': 'ringing',
      'type': isVideo ? 'video' : 'voice',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
