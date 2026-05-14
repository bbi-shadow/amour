import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/app_bindings.dart';
import 'controllers/auth_controller.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/premium/premium_screen.dart';
import 'screens/notifications_screen.dart';
import 'services/fcm_service.dart';
import 'themes/app_theme.dart';
import 'utils/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khoá màn hình dọc — tránh lỗi xoay tròn trên emulator/device
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('vi', null); 
  await FCMService.init();

  runApp(const AmourApp());
}

class AmourApp extends StatelessWidget {
  const AmourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Amour',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialBinding: AppBindings(),
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      getPages: [
        GetPage(name: AppRoutes.splash,       page: () => const AuthGate()),
        GetPage(name: AppRoutes.login,        page: () => const LoginScreen()),
        GetPage(name: AppRoutes.register,     page: () => RegisterScreen()),
        GetPage(name: AppRoutes.home,         page: () => const HomeScreen()),
        GetPage(name: AppRoutes.admin,        page: () => const AdminScreen()),
        GetPage(name: AppRoutes.chatDetail,   page: () => ChatDetailScreen(
          conversationId: Get.arguments?['conversationId'] ?? '',
          otherUserId:    Get.arguments?['otherUserId'] ?? '',
          otherUserName:  Get.arguments?['otherUserName'] ?? '',
        )),
        GetPage(name: AppRoutes.editProfile,  page: () => const EditProfileScreen()),
        GetPage(name: AppRoutes.premium,      page: () => const PremiumScreen()),
        GetPage(name: AppRoutes.notifications, page: () => const NotificationsScreen()),
      ],
    );
  }
}

class AuthGate extends GetView<AuthController> {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 1. Nếu hệ thống chưa sẵn sàng (đang tải profile/role) -> Hiện màn hình chờ có Logo
      if (!controller.isReady.value) {
        return const SplashScreen();
      }

      // 2. Nếu chưa đăng nhập -> Đưa về màn Login
      if (controller.firebaseUser.value == null) {
        return const LoginScreen();
      }

      // 3. Đã đăng nhập -> Vào Admin hoặc Home dựa trên role đã được cache sẵn
      return controller.isAdmin.value ? const AdminScreen() : const HomeScreen();
    });
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hiển thị logo chính giữa màn hình splash
            Hero(
              tag: 'app_logo',
              child: Image.asset(
                'assets/image/logo.png',
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.favorite_rounded, size: 80, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
