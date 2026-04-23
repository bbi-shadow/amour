import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

/// ══════════════════════════════════════════════════════════════
/// AuthController — GetX Controller quản lý toàn bộ Authentication
/// - Email/Password login & register
/// - Google Sign In
/// - Forgot password
/// - Phone OTP (Firebase Phone Auth)
/// - Session management
/// - Ban check
/// ══════════════════════════════════════════════════════════════
class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables
  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isGoogleLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Phone auth
  String _verificationId = '';
  final RxBool otpSent = false.obs;
  final RxBool isPhoneLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Lắng nghe trạng thái auth thay đổi
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _handleAuthStateChange);
  }

  void _handleAuthStateChange(User? user) {
    if (user != null) {
      _loadCurrentUser(user.uid);
    } else {
      currentUser.value = null;
    }
  }

  Future<void> _loadCurrentUser(String uid) async {
    try {
      final doc = await _firestore.collection(AppConstants.colUsers).doc(uid).get();
      if (doc.exists) {
        currentUser.value = UserModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
    }
  }

  // ── Refresh current user data ──────────────────────────────
  Future<void> refreshUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) await _loadCurrentUser(uid);
  }

  // ══════════════════════════════════════════════════════════
  // EMAIL / PASSWORD LOGIN
  // ══════════════════════════════════════════════════════════
  Future<bool> loginWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      AppHelpers.showError('Vui lòng nhập đầy đủ thông tin!');
      return false;
    }
    if (!AppHelpers.isValidEmail(email)) {
      AppHelpers.showError('Email không hợp lệ!');
      return false;
    }

    isLoading.value = true;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return await _postLoginCheck(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      AppHelpers.showError(_authErrorMessage(e.code));
      return false;
    } catch (e) {
      AppHelpers.showError('Đăng nhập thất bại. Thử lại sau!');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // EMAIL / PASSWORD REGISTER
  // ══════════════════════════════════════════════════════════
  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required int age,
    required String gender,
    required String city,
    String bio = '',
  }) async {
    // Validation
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      AppHelpers.showError('Vui lòng điền đầy đủ thông tin!');
      return false;
    }
    if (age < 18) {
      AppHelpers.showError('Bạn phải đủ 18 tuổi để sử dụng ứng dụng!');
      return false;
    }
    final passError = AppHelpers.validatePassword(password);
    if (passError != null) {
      AppHelpers.showError(passError);
      return false;
    }

    isLoading.value = true;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Cập nhật display name
      await credential.user!.updateDisplayName(name.trim());

      final uid = credential.user!.uid;
      final newUser = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        age: age,
        gender: gender,
        bio: bio.trim(),
        photoUrl: '',
        city: city,
        createdAt: DateTime.now(),
      );

      // Lưu vào Firestore
      await _firestore.collection(AppConstants.colUsers).doc(uid).set(newUser.toMap());

      // Gửi email xác thực
      await credential.user!.sendEmailVerification();

      currentUser.value = newUser;
      return true;
    } on FirebaseAuthException catch (e) {
      AppHelpers.showError(_authErrorMessage(e.code));
      return false;
    } catch (e) {
      AppHelpers.showError('Đăng ký thất bại. Thử lại sau!');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // GOOGLE SIGN IN
  // ══════════════════════════════════════════════════════════
  Future<bool> loginWithGoogle() async {
    isGoogleLoading.value = true;
    try {
      // Đảm bảo logout trước để tránh cache
      await GoogleSignIn().signOut();
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Kiểm tra user đã tồn tại chưa
      final doc = await _firestore.collection(AppConstants.colUsers).doc(user.uid).get();
      if (!doc.exists) {
        // Tạo mới
        final newUser = UserModel(
          uid: user.uid,
          name: user.displayName ?? 'Người dùng',
          email: user.email ?? '',
          age: 18,
          bio: '',
          photoUrl: user.photoURL ?? '',
          city: '',
          createdAt: DateTime.now(),
        );
        await _firestore.collection(AppConstants.colUsers).doc(user.uid).set(newUser.toMap());
        currentUser.value = newUser;
      }

      return await _postLoginCheck(user.uid);
    } catch (e) {
      AppHelpers.showError('Đăng nhập Google thất bại. Thử lại!');
      return false;
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // PHONE AUTH — Gửi OTP
  // ══════════════════════════════════════════════════════════
  Future<void> sendOTP(String phoneNumber) async {
    isPhoneLoading.value = true;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verify trên Android
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          AppHelpers.showError('Không thể gửi OTP: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          otpSent.value = true;
          AppHelpers.showSuccess('Đã gửi mã OTP!');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      AppHelpers.showError('Lỗi gửi OTP!');
    } finally {
      isPhoneLoading.value = false;
    }
  }

  // Xác minh OTP
  Future<bool> verifyOTP(String otp) async {
    isPhoneLoading.value = true;
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: otp,
      );
      final result = await _auth.signInWithCredential(credential);
      return await _postLoginCheck(result.user!.uid);
    } on FirebaseAuthException {
      AppHelpers.showError('Mã OTP không đúng hoặc đã hết hạn!');
      return false;
    } finally {
      isPhoneLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // FORGOT PASSWORD
  // ══════════════════════════════════════════════════════════
  Future<bool> forgotPassword(String email) async {
    if (!AppHelpers.isValidEmail(email)) {
      AppHelpers.showError('Email không hợp lệ!');
      return false;
    }
    isLoading.value = true;
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      AppHelpers.showSuccess('Đã gửi email đặt lại mật khẩu!');
      return true;
    } catch (e) {
      AppHelpers.showError('Không tìm thấy email này!');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════
  // LOGOUT
  // ══════════════════════════════════════════════════════════
  Future<void> logout() async {
    try {
      // Cập nhật trạng thái offline
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection(AppConstants.colUsers).doc(uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      await GoogleSignIn().signOut();
      await _auth.signOut();
      currentUser.value = null;
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      AppHelpers.showError('Lỗi đăng xuất!');
    }
  }

  // ══════════════════════════════════════════════════════════
  // HELPERS PRIVATE
  // ══════════════════════════════════════════════════════════

  /// Kiểm tra sau login: banned? admin? → điều hướng
  Future<bool> _postLoginCheck(String uid) async {
    final doc = await _firestore.collection(AppConstants.colUsers).doc(uid).get();

    // Kiểm tra bị ban
    if (doc.exists) {
      final data = doc.data()!;
      if (data['isBanned'] == true) {
        await _auth.signOut();
        final reason = data['banReason']?.toString() ?? 'Vi phạm tiêu chuẩn cộng đồng';
        _showBannedDialog(reason);
        return false;
      }
    }

    // Cập nhật online status
    await _firestore.collection(AppConstants.colUsers).doc(uid).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });

    // Kiểm tra admin
    final adminDoc = await _firestore.collection(AppConstants.colAdmins).doc(uid).get();
    if (adminDoc.exists) {
      Get.offAllNamed(AppRoutes.admin);
    } else {
      Get.offAllNamed(AppRoutes.home);
    }
    return true;
  }

  void _showBannedDialog(String reason) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.block, color: Colors.red, size: 24),
          SizedBox(width: 10),
          Text('Tài khoản bị khoá', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tài khoản của bạn đã bị khoá.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Text('Lý do: $reason',
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
            const SizedBox(height: 8),
            const Text('Liên hệ support nếu bạn cho rằng đây là lỗi.',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đóng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'Email không tồn tại!';
      case 'wrong-password': return 'Sai mật khẩu!';
      case 'invalid-credential': return 'Email hoặc mật khẩu sai!';
      case 'email-already-in-use': return 'Email này đã được sử dụng!';
      case 'weak-password': return 'Mật khẩu quá yếu!';
      case 'invalid-email': return 'Email không hợp lệ!';
      case 'user-disabled': return 'Tài khoản đã bị vô hiệu hoá!';
      case 'too-many-requests': return 'Quá nhiều yêu cầu. Thử lại sau!';
      default: return 'Đăng nhập thất bại. Thử lại!';
    }
  }

  // Getters tiện ích
  bool get isLoggedIn => _auth.currentUser != null;
  String? get currentUid => _auth.currentUser?.uid;
  bool get isPremium => currentUser.value?.isPremium ?? false;
}
