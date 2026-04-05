import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(AmourApp());
}

class AmourApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Amour',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFFF4B6E),
        fontFamily: 'Roboto',
      ),
      // ── Điểm khởi đầu: kiểm tra session ──
      home: AuthGate(),
    );
  }
}

/// Tự động chuyển màn hình dựa trên trạng thái đăng nhập.
/// Firebase Auth lưu session cục bộ — không cần làm gì thêm.
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Stream này phát ra ngay lập tức với user hiện tại (null nếu chưa đăng nhập)
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Đang khởi động / kiểm tra session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        // Đã đăng nhập → vào HomeScreen
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen();
        }

        // Chưa đăng nhập → LoginScreen
        return LoginScreen();
      },
    );
  }
}

/// Màn hình splash hiện trong lúc Firebase kiểm tra session
class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF4B6E), Color(0xFFFF8E9B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, size: 72, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Amour',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 32),
              CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}