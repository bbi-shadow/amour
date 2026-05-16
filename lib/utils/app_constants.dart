import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../themes/app_theme.dart';

class AppConstants {
  static const appName    = 'Amour';
  static const appVersion = '1.0.0';

  // ── Zego Cloud credentials (thay Agora) ──────────────────────────────────
  // Lấy tại: https://console.zegocloud.com → Project → AppID & AppSign
  static const int zegoAppId      = 571811223;
  static const String zegoAppSign = 'd944a475a15f7d8255b72de34357fc374f4b4bae8a4d26b5e4214afc095e6587';
  // Firestore Collections
  static const colUsers         = 'users';
  static const colAdmins        = 'admins';
  static const colCities        = 'cities';
  static const colPosts         = 'posts';
  static const colConversations = 'conversations';
  static const colMessages      = 'messages';
  static const colNotifications = 'notifications';
  static const colCalls         = 'calls';
  static const colSwipes        = 'swipes';
  static const colMatches       = 'matches';
  static const colReports       = 'reports';

  // Discovery Options
  static const List<Map<String, dynamic>> interestOptions = [
    {'icon': Icons.music_note, 'label': 'Âm nhạc'},
    {'icon': Icons.movie_outlined, 'label': 'Phim ảnh'},
    {'icon': Icons.fitness_center, 'label': 'Gym'},
    {'icon': Icons.flight_takeoff, 'label': 'Du lịch'},
    {'icon': Icons.menu_book_outlined, 'label': 'Đọc sách'},
    {'icon': Icons.restaurant_outlined, 'label': 'Nấu ăn'},
    {'icon': Icons.videogame_asset_outlined, 'label': 'Gaming'},
    {'icon': Icons.pets_outlined, 'label': 'Thú cưng'},
    {'icon': Icons.palette_outlined, 'label': 'Nghệ thuật'},
    {'icon': Icons.coffee_outlined, 'label': 'Cà phê'},
    {'icon': Icons.beach_access_outlined, 'label': 'Biển'},
    {'icon': Icons.self_improvement, 'label': 'Yoga'},
    {'icon': Icons.camera_alt_outlined, 'label': 'Nhiếp ảnh'},
    {'icon': Icons.sports_soccer, 'label': 'Thể thao'},
    {'icon': Icons.directions_run, 'label': 'Chạy bộ'},
  ];
}

class AppRoutes {
  static const splash       = '/';
  static const login        = '/login';
  static const register     = '/register';
  static const home         = '/home';
  static const admin        = '/admin';
  static const chatDetail   = '/chat-detail';
  static const editProfile  = '/edit-profile';
  static const settings     = '/settings';
  static const premium      = '/premium';
  static const notifications= '/notifications';
  static const discovery    = '/discovery';
}

class AppHelpers {
  static bool isValidEmail(String email) =>
      RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);

  static String? validatePassword(String pass) {
    if (pass.length < 6) return 'Mật khẩu ít nhất 6 ký tự';
    if (!pass.contains(RegExp(r'[A-Z]'))) return 'Cần ít nhất 1 chữ hoa';
    if (!pass.contains(RegExp(r'[0-9]'))) return 'Cần ít nhất 1 chữ số';
    return null;
  }

  static String timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatPrice(num price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(price);
  }

  static void showSuccess(String msg) => Get.snackbar(
    'Thành công', msg,
    backgroundColor: Colors.green, colorText: Colors.white,
    snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(16),
    borderRadius: 12,
  );

  static void showError(String msg) => Get.snackbar(
    'Lỗi', msg,
    backgroundColor: Colors.redAccent, colorText: Colors.white,
    snackPosition: SnackPosition.TOP, margin: const EdgeInsets.all(16),
    borderRadius: 12,
  );

  static Future<bool> confirm({required String title, required String message}) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
