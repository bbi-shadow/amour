import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/premium/premium_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/safety_screen.dart';
import 'screens/help_screen.dart';
import 'screens/discovery/discovery_screen.dart';
import 'services/fcm_service.dart';
import 'services/firestore_service.dart'; // ✅ Thêm
import 'controllers/auth_controller.dart';
import 'themes/app_theme.dart';
import 'utils/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  Get.put(AuthController());
  await FCMService.init();

  runApp(const AmourApp());
}

class AmourApp extends StatefulWidget {
  const AmourApp({super.key});

  @override
  State<AmourApp> createState() => _AmourAppState();
}

class _AmourAppState extends State<AmourApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnlineStatus(false);
    super.dispose();
  }

  // ✅ Messenger Logic: Tự động đổi trạng thái khi ẩn/hiện App
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnlineStatus(true);
    } else {
      _setOnlineStatus(false);
    }
  }

  void _setOnlineStatus(bool online) {
    FirestoreService.updateActivityStatus(online);
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Amour',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      getPages: [
        GetPage(name: AppRoutes.splash,      page: () => const AuthGate()),
        GetPage(name: AppRoutes.login,       page: () => LoginScreen()),
        GetPage(name: AppRoutes.register,    page: () => RegisterScreen()),
        GetPage(name: AppRoutes.home,        page: () => const HomeScreen()),
        GetPage(name: AppRoutes.admin,       page: () => const AdminScreen()),
        GetPage(name: AppRoutes.chatDetail,  page: () => ChatDetailScreen(
          conversationId: Get.arguments?['conversationId'] ?? '',
          otherUserId:    Get.arguments?['otherUserId'] ?? '',
          otherUserName:  Get.arguments?['otherUserName'] ?? '',
        )),
        GetPage(name: AppRoutes.editProfile, page: () => const EditProfileScreen()),
        GetPage(name: AppRoutes.settings,    page: () => const SettingsScreen()),
        GetPage(name: AppRoutes.premium,     page: () => const PremiumScreen()),
        GetPage(name: AppRoutes.notifications, page: () => const NotificationsScreen()),
        GetPage(name: AppRoutes.safety,      page: () => const SafetyScreen()),
        GetPage(name: AppRoutes.help,        page: () => const HelpScreen()),
        GetPage(name: AppRoutes.discovery,   page: () => const DiscoveryScreen()),
      ],
      home: const AuthGate(),
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
        if (snapshot.connectionState == ConnectionState.waiting) return const SplashScreen();
        if (snapshot.hasData && snapshot.data != null) return const HomeScreen();
        return LoginScreen();
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFF4B6E), Color(0xFFFF8E9B)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(scale: _scaleAnimation, child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle), child: ClipOval(child: Image.asset('assets/image/logo.png', errorBuilder: (_,__,___) => const Icon(Icons.favorite, size: 80, color: Colors.white))))),
              const SizedBox(height: 30),
              const Text('Amour', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 50),
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}
