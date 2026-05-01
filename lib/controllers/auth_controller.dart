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
  final RxBool isLoading = false.obs;
  final RxBool isGoogleLoading = false.obs;

  String? get currentUid => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
    ever(firebaseUser, _onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    if (user != null) {
      _loadCurrentUser(user.uid);
    } else {
      currentUser.value = null;
    }
  }

  Future<void> _loadCurrentUser(String uid) async {
    currentUser.value = await _userRepo.getById(uid);
  }

  // Kiem tra quyen Admin
  Future<bool> checkIsAdmin(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('admins').doc(uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  // Dang nhap Email
  Future<Result<bool>> loginWithEmail(String email, String password) async {
    if (email.isEmpty || password.isEmpty) return Result.failure('Vui lòng nhập đầy đủ thông tin');
    
    isLoading.value = true;
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      bool isAdmin = await checkIsAdmin(credential.user!.uid);
      Get.offAllNamed(isAdmin ? AppRoutes.admin : AppRoutes.home);
      return Result.success(true);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_translateError(e.code));
    } finally {
      isLoading.value = false;
    }
  }

  // Dang nhap Google
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

      // Neu chua co data trong Firestore thi tao moi
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

      bool isAdmin = await checkIsAdmin(user.uid);
      Get.offAllNamed(isAdmin ? AppRoutes.admin : AppRoutes.home);
      return Result.success(true);
    } catch (e) {
      return Result.failure('Lỗi Google: ${e.toString()}');
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // Dang ky
  Future<Result<bool>> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required int age,
    required String gender,
    required String city,
    String bio = '',
  }) async {
    isLoading.value = true;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      final newUser = UserModel(
        uid: credential.user!.uid,
        name: name.trim(),
        email: email.trim(),
        age: age,
        gender: gender,
        city: city,
        bio: bio.trim(),
        photoUrl: '',
        createdAt: DateTime.now(),
      );
      
      await _userRepo.create(newUser);
      Get.offAllNamed(AppRoutes.home);
      return Result.success(true);
    } on FirebaseAuthException catch (e) {
      return Result.failure(_translateError(e.code));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await _userRepo.setOnlineStatus(isOnline: false);
    await _googleSignIn.signOut();
    await _auth.signOut();
    currentUser.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  Future<Result<void>> forgotPassword(String email) async {
    if (email.trim().isEmpty) return Result.failure('Vui lòng nhập email');
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return Result.success(null);
    } catch (e) {
      return Result.failure('Không thể gửi email đặt lại mật khẩu');
    }
  }

  String _translateError(String code) {
    switch (code) {
      case 'user-not-found': return 'Email không tồn tại';
      case 'wrong-password': return 'Sai mật khẩu';
      case 'email-already-in-use': return 'Email này đã được sử dụng';
      case 'invalid-email': return 'Email không hợp lệ';
      case 'user-disabled': return 'Tài khoản đã bị vô hiệu hóa';
      default: return 'Đã có lỗi xảy ra. Thử lại sau!';
    }
  }
}
