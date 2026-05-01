import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return Obx(() {
            final auth = AuthController.to;
            // Cho load profile tu Firestore
            if (auth.currentUser.value == null) return const SplashScreen();
            
            return FutureBuilder<bool>(
              future: auth.checkIsAdmin(snapshot.data!.uid),
              builder: (context, adminSnap) {
                if (adminSnap.connectionState == ConnectionState.waiting) return const SplashScreen();
                return (adminSnap.data == true) ? const AdminScreen() : const HomeScreen();
              },
            );
          });
        }
        return const LoginScreen();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
