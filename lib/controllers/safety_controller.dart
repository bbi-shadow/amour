import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

class SafetyController extends GetxController {
  static SafetyController get to => Get.find();

  final String myUid = AuthController.to.currentUid ?? '';
  final RxList<String> blockedUids = <String>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    if (myUid.isNotEmpty) {
      _listenToBlockedList();
    }
  }

  void _listenToBlockedList() {
    FirebaseFirestore.instance
        .collection('blocks')
        .doc(myUid)
        .collection('blocked')
        .snapshots()
        .listen((snap) {
      blockedUids.value = snap.docs.map((doc) => doc.id).toList();
      isLoading.value = false;
    });
  }

  Future<void> blockUser(String targetUid) async {
    try {
      await FirebaseFirestore.instance
          .collection('blocks')
          .doc(myUid)
          .collection('blocked')
          .doc(targetUid)
          .set({'timestamp': FieldValue.serverTimestamp()});
      AppHelpers.showSuccess("Da chan nguoi dung");
    } catch (e) {
      AppHelpers.showError("Loi khi chan nguoi dung");
    }
  }

  Future<void> unblockUser(String targetUid) async {
    try {
      await FirebaseFirestore.instance
          .collection('blocks')
          .doc(myUid)
          .collection('blocked')
          .doc(targetUid)
          .delete();
      AppHelpers.showSuccess("Da bo chan");
    } catch (e) {
      AppHelpers.showError("Loi khi bo chan");
    }
  }

  Future<void> sendReport(String reason) async {
    // Gia lap gui bao cao
    AppHelpers.showSuccess("Da gui bao cao: $reason");
  }
}
