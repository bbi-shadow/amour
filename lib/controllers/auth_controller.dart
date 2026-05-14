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
  final RxBool isReady = false.obs; // Cờ báo hiệu app đã load xong dữ liệu ban đầu
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
      // Load song song profile và quyền admin để tối ưu tốc độ
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
      default: return 'Đã có lỗi xảy ra. Thử lại sau!';
    }
  }
  
  // Các hàm khác giữ nguyên...
}
