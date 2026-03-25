import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart'; // Thêm dòng này

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Amour',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFFF4B6E),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFF4B6E)),
        useMaterial3: true,
      ),
      // Đổi home thành LoginScreen
      home: LoginScreen(),
    );
  }
}