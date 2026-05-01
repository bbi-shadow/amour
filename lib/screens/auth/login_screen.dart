import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/app_constants.dart';
import '../../themes/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscurePass = true;

  final authController = AuthController.to;

  Future<void> _login() async {
    final result = await authController.loginWithEmail(
      _email.text.trim(),
      _pass.text.trim(),
    );
    if (result.isFailure) {
      AppHelpers.showError(result.error!);
    }
  }

  Future<void> _loginWithGoogle() async {
    final result = await authController.loginWithGoogle();
    if (result.isFailure) {
      AppHelpers.showError(result.error!);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    final subColor = isDark ? Colors.white38 : Colors.grey;
    final inputBg = isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF8F8F8);
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // -- App Icon/Logo --
                  Hero(
                    tag: 'app_logo',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite_rounded, size: 48, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Amour',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Hen ho va ket noi',
                    style: TextStyle(fontSize: 14, color: subColor),
                  ),

                  const SizedBox(height: 48),

                  _buildInputField(
                    controller: _email,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    isDark: isDark,
                    inputBg: inputBg,
                    borderColor: borderColor,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 14),

                  _buildInputField(
                    controller: _pass,
                    label: 'Mat khau',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscurePass,
                    isDark: isDark,
                    inputBg: inputBg,
                    borderColor: borderColor,
                    textColor: textColor,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: subColor,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => authController.forgotPassword(_email.text),
                      child: const Text(
                        'Quen mat khau?',
                        style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Login Button
                  Obx(() => SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: authController.isLoading.value ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: authController.isLoading.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Dang nhap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )),
                  const SizedBox(height: 24),

                  Row(children: [
                    Expanded(child: Divider(color: borderColor)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('hoac', style: TextStyle(color: subColor, fontSize: 13))),
                    Expanded(child: Divider(color: borderColor)),
                  ]),
                  const SizedBox(height: 24),

                  // Google Button
                  Obx(() => SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: authController.isGoogleLoading.value ? null : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: authController.isGoogleLoading.value
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 28),
                                const SizedBox(width: 8),
                                Text('Tiep tuc voi Google', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                              ],
                            ),
                    ),
                  )),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Chua co tai khoan? ', style: TextStyle(color: subColor)),
                      GestureDetector(
                        onTap: () => Get.to(() => RegisterScreen()),
                        child: const Text('Dang ky ngay', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
    required bool isDark,
    required Color inputBg,
    required Color borderColor,
    required Color textColor,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
        prefixIcon: Icon(icon, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: inputBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}
