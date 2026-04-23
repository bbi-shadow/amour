import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../themes/app_theme.dart';

/// ══════════════════════════════════════════════════════════════
/// AppConstants — Các hằng số toàn cục
/// ══════════════════════════════════════════════════════════════
class AppConstants {
  // App Info
  static const appName      = 'Amour';
  static const appVersion   = '1.0.0';

  // Limits
  static const maxPhotos         = 6;
  static const maxBioLength      = 300;
  static const freeSwipesPerDay  = 20;
  static const maxSearchRadius   = 200;  // km

  // Premium Plans
  static const premiumBasicPrice    = 99000;   // VND/tháng
  static const premiumGoldPrice     = 199000;
  static const premiumPlatinumPrice = 299000;

  // Firestore Collections
  static const colUsers           = 'users';
  static const colMatches         = 'matches';
  static const colConversations   = 'conversations';
  static const colMessages        = 'messages';
  static const colLikes           = 'likes';
  static const colSwipes          = 'swipes';
  static const colBlocks          = 'blocks';
  static const colReports         = 'reports';
  static const colNotifications   = 'notifications';
  static const colSubscriptions   = 'subscriptions';
  static const colCalls           = 'calls';
  static const colAdmins          = 'admins';
  static const colCities          = 'cities';
  static const colFriendRequests  = 'friend_requests';
  static const colFriends         = 'friends';
  static const colFollowing       = 'following'; // ✅ Thêm collection following
  static const colFollowers       = 'followers'; // ✅ Thêm collection followers

  // Zodiac Signs
  static const List<String> zodiacSigns = [
    'Bạch Dương ♈', 'Kim Ngưu ♉', 'Song Tử ♊', 'Cự Giải ♋',
    'Sư Tử ♌', 'Xử Nữ ♍', 'Thiên Bình ♎', 'Bọ Cạp ♏',
    'Nhân Mã ♐', 'Ma Kết ♑', 'Bảo Bình ♒', 'Song Ngư ♓',
  ];

  // Relationship Goals
  static const List<String> relationshipGoals = [
    'Hẹn hò nghiêm túc 💑',
    'Kết bạn mới 🤝',
    'Tình cảm thông thường 😊',
    'Chưa chắc chắn 🤔',
    'Hôn nhân 💍',
  ];

  // Interests
  static const List<Map<String, String>> interestOptions = [
    {'emoji': '🎵', 'label': 'Âm nhạc'},
    {'emoji': '🎬', 'label': 'Phim ảnh'},
    {'emoji': '🏋️', 'label': 'Thể dục'},
    {'emoji': '✈️', 'label': 'Du lịch'},
    {'emoji': '📚', 'label': 'Đọc sách'},
    {'emoji': '🍜', 'label': 'Ẩm thực'},
    {'emoji': '🎮', 'label': 'Gaming'},
    {'emoji': '🐾', 'label': 'Yêu thú cưng'},
    {'emoji': '🎨', 'label': 'Nghệ thuật'},
    {'emoji': '☕', 'label': 'Cà phê'},
    {'emoji': '🏖️', 'label': 'Biển'},
    {'emoji': '🌿', 'label': 'Thiên nhiên'},
    {'emoji': '🧘', 'label': 'Yoga'},
    {'emoji': '📸', 'label': 'Nhiếp ảnh'},
    {'emoji': '🎭', 'label': 'Sân khấu'},
    {'emoji': '🚴', 'label': 'Đạp xe'},
  ];

  // Report Reasons
  static const List<String> reportReasons = [
    'Ảnh giả/không thật',
    'Nội dung phản cảm',
    'Spam/quảng cáo',
    'Hành vi quấy rối',
    'Thông tin sai',
    'Tài khoản lừa đảo',
    'Khác',
  ];

  // Ice Breaker Messages
  static const List<String> iceBreakers = [
    '👋 Chào! Mình thấy hồ sơ của bạn rất thú vị!',
    '☕ Nếu có thể, bạn muốn uống cà phê ở đâu?',
    '🎵 Gần đây bạn hay nghe nhạc gì?',
    '✈️ Điểm đến trong mơ của bạn là đâu?',
    '🍜 Bạn thích món ăn nào nhất?',
    '😄 Kể cho mình nghe điều thú vị về bạn đi!',
  ];
}

/// ══════════════════════════════════════════════════════════════
/// AppRoutes — Routing
/// ══════════════════════════════════════════════════════════════
class AppRoutes {
  static const splash       = '/';
  static const onboarding   = '/onboarding';
  static const login        = '/login';
  static const register     = '/register';
  static const home         = '/home';
  static const swipe        = '/swipe';
  static const chat         = '/chat';
  static const chatDetail   = '/chat-detail';
  static const profile      = '/profile';
  static const editProfile  = '/edit-profile';
  static const settings     = '/settings';
  static const premium      = '/premium';
  static const notifications= '/notifications';
  static const call         = '/call';
  static const admin        = '/admin';
  static const discovery    = '/discovery';
  static const userDetail   = '/user-detail';
  static const safety       = '/safety';
  static const help         = '/help';
}

/// ══════════════════════════════════════════════════════════════
/// AppHelpers — Utility functions
/// ══════════════════════════════════════════════════════════════
class AppHelpers {
  /// Format thời gian thân thiện
  static String timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format giá tiền VND
  static String formatPrice(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return '${buffer}đ';
  }

  /// Format thời lượng gọi
  static String formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Kiểm tra email hợp lệ
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  /// Kiểm tra mật khẩu mạnh
  static String? validatePassword(String pass) {
    if (pass.length < 8) return 'Ít nhất 8 ký tự';
    if (!pass.contains(RegExp(r'[A-Z]'))) return 'Cần ít nhất 1 chữ hoa';
    if (!pass.contains(RegExp(r'[0-9]'))) return 'Cần ít nhất 1 số';
    return null;
  }

  /// SnackBar thành công
  static void showSuccess(String msg) => Get.snackbar(
    '✅ Thành công', msg,
    backgroundColor: AppColors.success,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    duration: const Duration(seconds: 3),
    margin: const EdgeInsets.all(16),
    borderRadius: 12,
  );

  /// SnackBar lỗi
  static void showError(String msg) => Get.snackbar(
    '❌ Lỗi', msg,
    backgroundColor: AppColors.error,
    colorText: Colors.white,
    snackPosition: SnackPosition.TOP,
    duration: const Duration(seconds: 3),
    margin: const EdgeInsets.all(16),
    borderRadius: 12,
  );

  /// Dialog xác nhận
  static Future<bool> confirm({required String title, required String message}) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
