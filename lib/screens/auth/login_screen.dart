import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../home_screen.dart';
import '../admin/admin_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;
  bool _obscurePass = true;

  Future<void> _login() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập email và mật khẩu!',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _loading = true);
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );

      await _redirectUser(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      String msg = 'Email hoặc mật khẩu sai';
      if (e.code == 'user-not-found') msg = 'Email không tồn tại';
      if (e.code == 'wrong-password') msg = 'Sai mật khẩu';
      if (e.code == 'user-disabled') msg = 'Tài khoản đã bị vô hiệu hóa';
      Get.snackbar('Lỗi', msg,
          backgroundColor: Colors.red, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Lỗi', 'Đăng nhập thất bại: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
    setState(() => _loading = false);
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() => _googleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'name': user.displayName ?? 'Người dùng',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'age': 0,
          'gender': '',
          'bio': '',
          'city': '',
          'createdAt': DateTime.now(),
        });

        Get.offAll(() => HomeScreen());
        Get.snackbar('👋 Chào mừng!', 'Hãy cập nhật hồ sơ của bạn nhé!',
            backgroundColor: Color(0xFFFF4B6E),
            colorText: Colors.white,
            duration: Duration(seconds: 3));
      } else {
        await _redirectUser(user.uid);
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Đăng nhập Google thất bại: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
    setState(() => _googleLoading = false);
  }

  // ✅ FIX: check isBanned + check admin
  Future<void> _redirectUser(String uid) async {
    // Kiểm tra tài khoản bị ban
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      if (data['isBanned'] == true) {
        // Đăng xuất ngay
        await FirebaseAuth.instance.signOut();
        final banReason = data['banReason']?.toString() ?? 'Vi phạm tiêu chuẩn cộng đồng';
        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Row(children: [
              Icon(Icons.block, color: Colors.red),
              SizedBox(width: 8),
              Text('Tài khoản bị khoá',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
            ]),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tài khoản của bạn đã bị khoá.'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Text('Lý do: $banReason',
                      style: const TextStyle(
                          color: Colors.red, fontSize: 13)),
                ),
                const SizedBox(height: 8),
                const Text(
                    'Nếu bạn cho rằng đây là nhầm lẫn, vui lòng liên hệ hỗ trợ.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red),
                child: const Text('Đóng',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        return;
      }
    }

    // Kiểm tra admin
    final adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(uid)
        .get();

    if (adminDoc.exists) {
      Get.offAll(() => AdminScreen());
    } else {
      Get.offAll(() => HomeScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF4B6E), Color(0xFFFF8E9B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('💕', style: TextStyle(fontSize: 48)),
                ),
                const SizedBox(height: 16),
                const Text('Amour',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const Text('Tìm kiếm tình yêu của bạn',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 40),

                _buildTextField(_email, 'Email', Icons.email),
                const SizedBox(height: 16),

                // ✅ Thêm toggle show/hide password
                TextField(
                  controller: _pass,
                  obscureText: _obscurePass,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon:
                    const Icon(Icons.lock, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePass
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.white70),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFFFF4B6E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(
                        color: Color(0xFFFF4B6E))
                        : const Text('Đăng nhập',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),

                Row(children: [
                  Expanded(
                      child: Divider(color: Colors.white54, thickness: 1)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('HOẶC',
                        style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                  Expanded(
                      child: Divider(color: Colors.white54, thickness: 1)),
                ]),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _googleLoading ? null : _loginWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: _googleLoading
                        ? const CircularProgressIndicator(
                        color: Color(0xFFFF4B6E))
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://www.google.com/favicon.ico',
                          width: 24, height: 24,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.g_mobiledata,
                              color: Colors.red,
                              size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Text('Đăng nhập bằng Google',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => Get.to(() => RegisterScreen()),
                  child: const Text('Chưa có tài khoản? Đăng ký ngay',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon,
      {bool isPass = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }
}