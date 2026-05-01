import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../services/firestore_service.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

class AdminController extends GetxController {
  static AdminController get to => Get.find();

  // -- States --
  final RxMap<String, int> stats = {'users': 0, 'posts': 0, 'matches': 0, 'reports': 0}.obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isCreatingUser = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadStats();
  }

  Future<void> loadStats() async {
    isLoading.value = true;
    try {
      final s = await FirestoreService.getStats();
      stats.assignAll(s);
    } catch (e) {
      print("Error loading admin stats: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Stream<QuerySnapshot> get usersStream => FirestoreService.getAllUsersStream();

  // -- Actions --
  Future<void> banUser(String uid, String reason) async {
    try {
      await FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).update({
        'isBanned': true,
        'banReason': reason,
      });
      AppHelpers.showSuccess("Da cam tai khoan");
    } catch (e) {
      AppHelpers.showError("Loi khi cam user");
    }
  }

  Future<void> unbanUser(String uid) async {
    try {
      await FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).update({
        'isBanned': false,
        'banReason': '',
      });
      AppHelpers.showSuccess("Da bo cam");
    } catch (e) {
      AppHelpers.showError("Loi khi bo cam");
    }
  }

  Future<void> deleteUser(String uid) async {
    final confirmed = await AppHelpers.confirm(
      title: "Xoa nguoi dung",
      message: "Hanh dong nay khong the hoan tac. Tiep tuc?"
    );
    if (!confirmed) return;

    try {
      await FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).delete();
      AppHelpers.showSuccess("Da xoa nguoi dung");
      loadStats();
    } catch (e) {
      AppHelpers.showError("Loi khi xoa user");
    }
  }

  void logout() => AuthController.to.logout();

  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
  }) async {
    isCreatingUser.value = true;
    try {
      // Logic tao user (Admin thuong tao user qua Firebase Admin SDK nhung o day gia lap qua AuthController neu can)
      // Tam thoi de trong hoac goi dang ky
      AppHelpers.showSuccess("Tính năng đang được cập nhật");
    } catch (e) {
      AppHelpers.showError("Loi: $e");
    } finally {
      isCreatingUser.value = false;
    }
  }

  Future<void> resolveReport(String reportId) async {
    try {
      await FirebaseFirestore.instance.collection(AppConstants.colReports).doc(reportId).update({
        'isResolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
      });
      AppHelpers.showSuccess("Da xu ly bao cao");
      loadStats();
    } catch (e) {
      AppHelpers.showError("Loi khi xu ly");
    }
  }

  Future<void> clearFakeUsers() async {
    final confirmed = await AppHelpers.confirm(
      title: "Don dep",
      message: "Xoa tat ca tai khoan thu nghiem?"
    );
    if (!confirmed) return;

    await FirestoreService.deleteAllFakeUsers();
    loadStats();
    AppHelpers.showSuccess("He thong da sach se");
  }
}
