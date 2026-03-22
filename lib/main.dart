// Import thư viện Flutter cơ bản (bắt buộc)
import 'package:flutter/material.dart';

// Import Firebase Core để khởi động Firebase
import 'package:firebase_core/firebase_core.dart';

// Import GetX để quản lý navigation và state dễ hơn
import 'package:get/get.dart';

// File tự động tạo bởi flutterfire configure - chứa thông tin kết nối Firebase
import 'firebase_options.dart';

// Hàm main là điểm bắt đầu của mọi app Flutter
void main() async {
  // Đảm bảo Flutter khởi động xong trước khi chạy code async
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi động Firebase - phải làm trước khi dùng bất kỳ tính năng Firebase nào
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Lấy config đúng theo nền tảng (Android/iOS/Web)
  );

  // Chạy app
  runApp(MyApp());
}

// Widget gốc của toàn bộ app
// StatelessWidget = widget không thay đổi trạng thái
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // GetMaterialApp thay thế MaterialApp thông thường
    // Cho phép dùng Get.to(), Get.back(), Get.snackbar()...
    return GetMaterialApp(
      title: 'Amour',               // Tên app hiện trên taskbar
      debugShowCheckedModeBanner: false, // Tắt banner "DEBUG" góc trên phải

      // Cài màu sắc chủ đạo cho toàn app
      theme: ThemeData(
        primaryColor: Color(0xFFFF4B6E), // Màu hồng chủ đạo
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFF4B6E)),
        useMaterial3: true, // Dùng Material Design 3 (phiên bản mới nhất)
      ),

      // Màn hình đầu tiên hiện ra khi mở app
      home: Scaffold(
        body: Center(
          child: Text(
            '💕 Amour',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}