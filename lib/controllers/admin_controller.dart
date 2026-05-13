import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

/// ══════════════════════════════════════════════════════════════
/// AdminController — Quản lý hệ thống từ Admin Panel
///
/// FIX [FEATURE]: createUser() trước chỉ là stub "đang cập nhật".
///   Giờ dùng Firebase Auth REST API (sign-up) + tạo Firestore document.
///
/// Lưu ý kiến trúc:
///   Admin tạo user qua Firebase Admin SDK (server-side) là cách lý tưởng.
///   Tuy nhiên từ Flutter client, cách hợp lệ là:
///   1. Gọi signInAnonymously tạm để có auth context
///   2. Dùng secondary FirebaseAuth instance để tạo user mà không logout admin
///   Cách dưới đây dùng secondary instance để tránh logout admin hiện tại.
/// ══════════════════════════════════════════════════════════════
class AdminController extends GetxController {
  static AdminController get to => Get.find();

  // -- States --
  final RxMap<String, int> stats =
      {'users': 0, 'posts': 0, 'matches': 0, 'reports': 0}.obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isCreatingUser = false.obs;

  // Cities
  final RxList<String> cities = <String>[].obs;
  final RxBool isLoadingCities = false.obs;

  // Lỗi/thành công khi tạo user (dùng cho UI)
  final RxString createUserError = ''.obs;
  final RxString createUserSuccess = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadStats();
    loadCities();
  }

  Future<void> loadCities() async {
    isLoadingCities.value = true;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.colCities)
          .orderBy('name')
          .get();
      cities.value = snap.docs
          .map((d) => d.data()['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error loading cities: $e');
    } finally {
      isLoadingCities.value = false;
    }
  }

  Future<void> loadStats() async {
    isLoading.value = true;
    try {
      final s = await FirestoreService.getStats();
      stats.assignAll(s);
    } catch (e) {
      print('Error loading admin stats: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Stream<QuerySnapshot> get usersStream => FirestoreService.getAllUsersStream();

  // -- User Management --
  Future<void> banUser(String uid, String reason) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(uid)
          .update({'isBanned': true, 'banReason': reason});
      AppHelpers.showSuccess('Đã cấm tài khoản');
    } catch (e) {
      AppHelpers.showError('Lỗi khi cấm user');
    }
  }

  Future<void> unbanUser(String uid) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(uid)
          .update({'isBanned': false, 'banReason': ''});
      AppHelpers.showSuccess('Đã bỏ cấm');
    } catch (e) {
      AppHelpers.showError('Lỗi khi bỏ cấm');
    }
  }

  Future<void> deleteUser(String uid) async {
    final confirmed = await AppHelpers.confirm(
        title: 'Xoá người dùng',
        message: 'Hành động này không thể hoàn tác. Tiếp tục?');
    if (!confirmed) return;

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(uid)
          .delete();
      AppHelpers.showSuccess('Đã xoá người dùng');
      loadStats();
    } catch (e) {
      AppHelpers.showError('Lỗi khi xoá user');
    }
  }

  // ── FIX [FEATURE]: createUser — đã hoàn thiện logic ─────────

  /// Tạo tài khoản mới mà KHÔNG logout admin đang đăng nhập.
  ///
  /// Kỹ thuật: Tạo secondary FirebaseApp instance độc lập,
  /// dùng instance đó để register user, sau đó delete app phụ.
  /// Admin session trên app chính hoàn toàn không bị ảnh hưởng.
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String bio = '',
    String city = '',
  }) async {
    createUserError.value = '';
    createUserSuccess.value = '';

    // Validate input
    if (email.trim().isEmpty || password.trim().isEmpty || name.trim().isEmpty) {
      createUserError.value = 'Vui lòng điền đầy đủ email, mật khẩu và tên';
      return;
    }
    if (!AppHelpers.isValidEmail(email.trim())) {
      createUserError.value = 'Email không hợp lệ';
      return;
    }
    if (password.length < 6) {
      createUserError.value = 'Mật khẩu tối thiểu 6 ký tự';
      return;
    }
    if (age < 18 || age > 99) {
      createUserError.value = 'Tuổi phải từ 18 đến 99';
      return;
    }

    isCreatingUser.value = true;

    try {
      // Tạo secondary FirebaseApp để không ảnh hưởng admin session
      final secondaryApp = await Firebase.initializeApp(
        name: 'admin_create_user_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options, // Dùng cùng config
      );

      try {
        final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

        // Đăng ký user mới qua secondary instance
        final credential = await secondaryAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password.trim(),
        );

        final newUid = credential.user!.uid;

        // Tạo Firestore document
        final newUser = UserModel(
          uid: newUid,
          name: name.trim(),
          email: email.trim(),
          age: age,
          gender: gender,
          city: city.trim(),
          bio: bio.trim(),
          photoUrl: '',
          createdAt: DateTime.now(),
        );

        await FirebaseFirestore.instance
            .collection(AppConstants.colUsers)
            .doc(newUid)
            .set(newUser.toMap());

        createUserSuccess.value =
        'Tạo tài khoản thành công: ${name.trim()} (${email.trim()})';
        AppHelpers.showSuccess('Đã tạo tài khoản: ${name.trim()}');
        loadStats();
      } finally {
        // Xoá secondary app dù thành công hay thất bại
        await secondaryApp.delete();
      }
    } on FirebaseAuthException catch (e) {
      createUserError.value = _translateAuthError(e.code);
      AppHelpers.showError(createUserError.value);
    } catch (e) {
      createUserError.value = 'Lỗi: ${e.toString()}';
      AppHelpers.showError(createUserError.value);
    } finally {
      isCreatingUser.value = false;
    }
  }

  String _translateAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      case 'operation-not-allowed':
        return 'Tính năng đăng ký bị vô hiệu hoá trên Firebase Console';
      default:
        return 'Lỗi: $code';
    }
  }

  // -- Reports --
  Future<void> resolveReport(String reportId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colReports)
          .doc(reportId)
          .update({
        'isResolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': AuthController.to.currentUid,
      });
      AppHelpers.showSuccess('Đã xử lý báo cáo');
      loadStats();
    } catch (e) {
      AppHelpers.showError('Lỗi khi xử lý');
    }
  }

  Future<void> clearFakeUsers() async {
    final confirmed = await AppHelpers.confirm(
        title: 'Dọn dẹp',
        message: 'Xoá tất cả tài khoản thử nghiệm (email bắt đầu bằng fake_)?');
    if (!confirmed) return;

    await FirestoreService.deleteAllFakeUsers();
    loadStats();
    AppHelpers.showSuccess('Hệ thống đã sạch sẽ');
  }

  // -- Premium management --
  Future<void> confirmPendingPayment(String paymentId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pending_payments')
          .doc(paymentId)
          .get();

      if (!doc.exists) {
        AppHelpers.showError('Không tìm thấy payment');
        return;
      }

      final data = doc.data()!;
      final userId = data['userId'] as String;
      final plan = data['plan'] as String;
      final days = (data['durationDays'] as num?)?.toInt() ?? 30;
      final endDate = DateTime.now().add(Duration(days: days));

      // Batch: cập nhật cả user lẫn payment status
      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(userId),
        {
          'isPremium': true,
          'premiumPlan': plan,
          'premiumExpiry': Timestamp.fromDate(endDate),
        },
      );

      batch.update(
        FirebaseFirestore.instance.collection('pending_payments').doc(paymentId),
        {
          'status': 'confirmed',
          'confirmedAt': FieldValue.serverTimestamp(),
          'confirmedBy': AuthController.to.currentUid,
        },
      );

      await batch.commit();
      AppHelpers.showSuccess('Đã xác nhận thanh toán — Premium kích hoạt cho $userId');
    } catch (e) {
      AppHelpers.showError('Lỗi: $e');
    }
  }

  // -- City Management --
  Future<void> addCity(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      AppHelpers.showError('Tên thành phố không được trống');
      return;
    }
    final exists = cities.any((c) => c.toLowerCase() == trimmed.toLowerCase());
    if (exists) {
      AppHelpers.showError('Thành phố "$trimmed" đã tồn tại');
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colCities)
          .add({'name': trimmed, 'createdAt': FieldValue.serverTimestamp()});
      await loadCities();
      AppHelpers.showSuccess('Đã thêm: $trimmed');
    } catch (e) {
      AppHelpers.showError('Lỗi khi thêm thành phố');
    }
  }

  Future<void> deleteCity(String docId, String name) async {
    final confirmed = await AppHelpers.confirm(
      title: 'Xoá thành phố',
      message: 'Xoá "$name" khỏi danh sách? Không thể hoàn tác.',
    );
    if (!confirmed) return;
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colCities)
          .doc(docId)
          .delete();
      await loadCities();
      AppHelpers.showSuccess('Đã xoá: $name');
    } catch (e) {
      AppHelpers.showError('Lỗi khi xoá thành phố');
    }
  }

  Stream<QuerySnapshot> get citiesStream => FirebaseFirestore.instance
      .collection(AppConstants.colCities)
      .orderBy('name')
      .snapshots();

  void logout() => AuthController.to.logout();
}
// NOTE: City methods appended below (replacing logout above in final file)