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
  final _pass  = TextEditingController();
  bool _loading       = false;
  bool _googleLoading = false;
  bool _obscurePass   = true;

  Future<void> _login() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      _showError('Vui lòng nhập email và mật khẩu!');
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
      _showError(msg);
    } catch (e) {
      _showError('Đăng nhập thất bại: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      await GoogleSignIn().signOut();
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) { setState(() => _googleLoading = false); return; }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user!;

      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? 'Người dùng',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'age': 0, 'gender': '', 'bio': '', 'city': '',
          'createdAt': DateTime.now(),
        });
        Get.offAll(() => HomeScreen());
      } else {
        await _redirectUser(user.uid);
      }
    } catch (e) {
      _showError('Đăng nhập Google thất bại: $e');
    }
    setState(() => _googleLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: Colors.red[400],
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _redirectUser(String uid) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users').doc(uid).get();

    if (userDoc.exists) {
      final data = userDoc.data()!;
      if (data['isBanned'] == true) {
        await FirebaseAuth.instance.signOut();
        final banReason = data['banReason']?.toString() ?? 'Vi phạm tiêu chuẩn cộng đồng';
        Get.dialog(AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('Tài khoản bị khoá',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min,
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
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Đóng', style: TextStyle(color: Colors.white)),
            ),
          ],
        ));
        return;
      }
    }

    final adminDoc = await FirebaseFirestore.instance
        .collection('admins').doc(uid).get();
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
            colors: [Color(0xFFFF4B6E), Color(0xFFFF8E9B), Color(0xFFFFB3C6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),

                  // ── Logo ──────────────────────────────
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('💕', style: TextStyle(fontSize: 40)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Amour',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      )),
                  const SizedBox(height: 4),

                  const SizedBox(height: 20),

                  // ── Card ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 28, 24, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text ('Đăng nhập',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 4),
                          Text('Chào mừng trở lại! 👋',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[500])),
                          const SizedBox(height: 24),

                          // Email field
                          _buildInputField(
                            controller: _email,
                            label: 'Email',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 14),

                          // Password field
                          _buildInputField(
                            controller: _pass,
                            label: 'Mật khẩu',
                            icon: Icons.lock_outline_rounded,
                            obscure: _obscurePass,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Quên mật khẩu
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                if (_email.text.isNotEmpty) {
                                  await FirebaseAuth.instance
                                      .sendPasswordResetEmail(
                                      email: _email.text.trim());
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text('Đã gửi email đặt lại mật khẩu'),
                                    backgroundColor: Color(0xFF4CAF50),
                                  ));
                                } else {
                                  _showError('Nhập email trước nhé!');
                                }
                              },
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero),
                              child: const Text('Quên mật khẩu?',
                                  style: TextStyle(
                                      color: Color(0xFFFF4B6E),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Nút đăng nhập
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF4B6E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                                  : const Text('Đăng nhập',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Divider
                          Row(children: [
                            Expanded(
                                child: Divider(
                                    color: Colors.grey[200], thickness: 1)),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('hoặc',
                                  style: TextStyle(
                                      color: Colors.grey[400], fontSize: 13)),
                            ),
                            Expanded(
                                child: Divider(
                                    color: Colors.grey[200], thickness: 1)),
                          ]),
                          const SizedBox(height: 20),

                          // Google button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed:
                              _googleLoading ? null : _loginWithGoogle,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: Colors.grey[200]!, width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _googleLoading
                                  ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Color(0xFFFF4B6E),
                                      strokeWidth: 2.5))
                                  : Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://www.google.com/favicon.ico',
                                    width: 20, height: 20,
                                    errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.g_mobiledata,
                                        color: Colors.red, size: 24),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text('Tiếp tục với Google',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Đăng ký
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Chưa có tài khoản?',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14)),
                      TextButton(
                        onPressed: () => Get.to(() => RegisterScreen()),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.only(left: 6)),
                        child: const Text('Đăng ký ngay',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF4B6E), width: 1.5),
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