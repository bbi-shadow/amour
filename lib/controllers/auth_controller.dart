import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/result.dart';
import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../utils/app_constants.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final UserRepository _userRepo;
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthController({
    UserRepository? userRepo,
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _userRepo = userRepo ?? UserRepository(),
        _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final Rx<User?> firebaseUser = Rx<User?>(null);
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isAdmin = false.obs;
  final RxBool isReady = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isGoogleLoading = false.obs;

  String? get currentUid => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) async {
    if (user != null) {
      isReady.value = false;
      final results = await Future.wait([
        _userRepo.getById(user.uid),
        checkIsAdmin(user.uid),
      ]);
      currentUser.value = results[0] as UserModel?;
      isAdmin.value = results[1] as bool;
      isReady.value = true;
    } else {
      currentUser.value = null;
      isAdmin.value = false;
      isReady.value = true;
    }
  }

  Future<bool> checkIsAdmin(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  // ── Đăng nhập email ────────────────────────────────────────────────────────
  Future<Result<bool>> loginWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return Result.failure('Vui lòng nhập đầy đủ thông tin');
    isLoading.value = true;
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
      return Result.success(true);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_translateError(e.code));
    } finally {
      isLoading.value = false;
    }
  }

  // ── Đăng ký email ──────────────────────────────────────────────────────────
  Future<Result<bool>> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required int age,
    required String gender,
    required String city,
    required String bio,
  }) async {
    isLoading.value = true;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name);

      final newUser = UserModel(
        uid: user.uid,
        name: name,
        email: email.trim(),
        age: age,
        bio: bio,
        photoUrl: '',
        city: city,
        createdAt: DateTime.now(),
      );
      await _userRepo.create(newUser);
      return Result.success(true);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_translateError(e.code));
    } catch (e) {
      return Result.failure('Đăng ký thất bại: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Quên mật khẩu ─────────────────────────────────────────────────────────
  Future<void> forgotPassword(String email) async {
    if (email.trim().isEmpty) {
      AppHelpers.showError('Vui lòng nhập email trước');
      return;
    }
    if (!AppHelpers.isValidEmail(email.trim())) {
      AppHelpers.showError('Email không hợp lệ');
      return;
    }
    isLoading.value = true;
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      AppHelpers.showSuccess('Đã gửi email đặt lại mật khẩu!\nKiểm tra hộp thư của bạn.');
    } on FirebaseAuthException catch (e) {
      AppHelpers.showError(_translateError(e.code));
    } catch (e) {
      AppHelpers.showError('Lỗi: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Đăng nhập Google ───────────────────────────────────────────────────────
  Future<Result<bool>> loginWithGoogle() async {
    isGoogleLoading.value = true;
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        isGoogleLoading.value = false;
        return Result.failure('Đã hủy đăng nhập');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user!;

      if (!await _userRepo.exists(user.uid)) {
        final newUser = UserModel(
          uid: user.uid,
          name: user.displayName ?? 'Người dùng',
          email: user.email ?? '',
          age: 18, bio: '', photoUrl: user.photoURL ?? '', city: '',
          createdAt: DateTime.now(),
        );
        await _userRepo.create(newUser);
      }
      return Result.success(true);
    } catch (e) {
      return Result.failure('Lỗi Google: ${e.toString()}');
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // ── Đăng xuất ─────────────────────────────────────────────────────────────
  Future<void> logout() async {
    isReady.value = false;
    await _userRepo.setOnlineStatus(isOnline: false);
    await _googleSignIn.signOut();
    await _auth.signOut();
    currentUser.value = null;
    isAdmin.value = false;
  }

  String _translateError(String code) {
    switch (code) {
      case 'user-not-found': return 'Email không tồn tại';
      case 'wrong-password': return 'Sai mật khẩu';
      case 'email-already-in-use': return 'Email đã được sử dụng';
      case 'weak-password': return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)';
      case 'invalid-email': return 'Email không hợp lệ';
      case 'too-many-requests': return 'Quá nhiều lần thử. Vui lòng thử lại sau';
      default: return 'Đã có lỗi xảy ra. Thử lại sau!';
    }
  }
}