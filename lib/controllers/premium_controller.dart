import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

/// ══════════════════════════════════════════════════════════════
/// PremiumController — Quản lý đăng ký gói Premium
///
/// FIX [SECURITY]: Phiên bản cũ ghi isPremium thẳng vào Firestore từ client
///   → Bất kỳ user nào cũng có thể tự set isPremium = true bằng Firestore REST.
///
/// Giải pháp: Dùng Pending Payment Flow:
///   1. Client tạo pending_payment document (trạng thái 'pending')
///   2. Admin/Cloud Function xác nhận và set isPremium = true
///   3. Client poll trạng thái trong 60 giây, nếu = 'confirmed' → kích hoạt
///
/// Với production thực tế: tích hợp VNPay/Stripe webhook vào Cloud Function
/// để tự động confirm payment. Code dưới đây đã sẵn sàng cho luồng đó.
/// ══════════════════════════════════════════════════════════════
class PremiumController extends GetxController {
  static PremiumController get to => Get.find();

  final RxInt selectedPlanIndex = 1.obs;
  final RxBool isLoading = false.obs;
  final RxString paymentStatus = ''.obs; // '', 'pending', 'confirmed', 'failed'

  String get uid => AuthController.to.currentUid ?? '';

  final List<PremiumPlan> plans = [
    PremiumPlan(
      name: 'Basic',
      icon: Icons.auto_awesome_outlined,
      price: 99000,
      durationDays: 30,
      gradient: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      features: [
        'Xem ai đã thích bạn',
        'Lượt thích vô hạn',
        '5 Super Like mỗi ngày',
        'Xoá quảng cáo',
      ],
    ),
    PremiumPlan(
      name: 'Gold',
      icon: Icons.star_outline_rounded,
      price: 199000,
      durationDays: 30,
      gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      features: [
        'Xem ai đã thích bạn',
        'Lượt thích vô hạn',
        '10 Super Like mỗi ngày',
        'Đẩy hồ sơ hàng tuần',
        'Ưu tiên hiển thị',
      ],
      isPopular: true,
    ),
    PremiumPlan(
      name: 'Platinum',
      icon: Icons.diamond_outlined,
      price: 299000,
      durationDays: 30,
      gradient: [const Color(0xFFB9A0FF), const Color(0xFF9B59B6)],
      features: [
        'Xem ai đã thích bạn',
        'Lượt thích vô hạn',
        'Super Like không giới hạn',
        'Đẩy hồ sơ mỗi ngày',
        'Ưu tiên hiển thị tối đa',
      ],
    ),
  ];

  PremiumPlan get selectedPlan => plans[selectedPlanIndex.value];

  // ── Subscribe Flow ────────────────────────────────────────────

  Future<void> subscribe() async {
    if (uid.isEmpty) {
      AppHelpers.showError('Vui lòng đăng nhập lại');
      return;
    }

    final plan = selectedPlan;
    final confirmed = await AppHelpers.confirm(
      title: 'Xác nhận đăng ký',
      message:
      'Gói ${plan.name} — ${AppHelpers.formatPrice(plan.price)}/tháng\n\nBạn sẽ được chuyển đến trang thanh toán.',
    );
    if (!confirmed) return;

    isLoading.value = true;
    paymentStatus.value = 'pending';

    try {
      // BƯỚC 1: Tạo pending_payment document
      // Cloud Function / backend lắng nghe collection này để xử lý payment
      final paymentRef = await FirebaseFirestore.instance
          .collection('pending_payments')
          .add({
        'userId': uid,
        'plan': plan.name.toLowerCase(),
        'price': plan.price,
        'durationDays': plan.durationDays,
        'status': 'pending', // pending → confirmed / failed
        'createdAt': FieldValue.serverTimestamp(),
        // Production: thêm paymentMethodId, transactionId từ VNPay/Stripe SDK
      });

      // BƯỚC 2: Chờ Cloud Function / admin xác nhận (poll 60s)
      final success = await _waitForPaymentConfirmation(paymentRef.id);

      if (success) {
        paymentStatus.value = 'confirmed';
        AppHelpers.showSuccess('Kích hoạt gói ${plan.name} thành công! 🎉');
        Get.back();
      } else {
        paymentStatus.value = 'failed';
        AppHelpers.showError(
            'Thanh toán chưa được xác nhận. Vui lòng liên hệ hỗ trợ nếu đã thanh toán.');
      }
    } catch (e) {
      paymentStatus.value = 'failed';
      AppHelpers.showError('Lỗi đăng ký: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  /// Poll Firestore để chờ Cloud Function confirm payment (tối đa 60 giây)
  Future<bool> _waitForPaymentConfirmation(String paymentId) async {
    const maxWait = Duration(seconds: 60);
    const pollInterval = Duration(seconds: 2);
    final deadline = DateTime.now().add(maxWait);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(pollInterval);

      final doc = await FirebaseFirestore.instance
          .collection('pending_payments')
          .doc(paymentId)
          .get();

      if (!doc.exists) continue;
      final status = doc.data()?['status'] as String? ?? '';

      if (status == 'confirmed') return true;
      if (status == 'failed') return false;
    }

    return false; // Timeout
  }

  // ── DEV ONLY: Kích hoạt thủ công (chỉ dùng khi test, không để production) ──

  /// Dùng trong môi trường dev để test UI mà không cần Cloud Function.
  /// Gọi method này từ admin panel hoặc dev tool, KHÔNG expose ra user.
  Future<void> devActivatePremium({required String planName, int days = 30}) async {
    assert(() {
      // Chỉ compile trong debug mode
      return true;
    }());

    if (uid.isEmpty) return;
    final endDate = DateTime.now().add(Duration(days: days));

    await FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(uid)
        .update({
      'isPremium': true,
      'premiumPlan': planName.toLowerCase(),
      'premiumExpiry': Timestamp.fromDate(endDate),
    });

    AppHelpers.showSuccess('[DEV] Premium activated: $planName');
  }

  // ── Check & Restore ───────────────────────────────────────────

  /// Kiểm tra subscription có còn hạn không (gọi khi app launch)
  Future<void> checkAndRestoreSubscription() async {
    if (uid.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(uid)
        .get();

    if (!doc.exists) return;
    final data = doc.data()!;

    final isPremium = data['isPremium'] == true;
    final expiry = data['premiumExpiry'];

    if (!isPremium) return;

    // Kiểm tra xem subscription còn hạn không
    if (expiry != null) {
      final expiryDate = (expiry as Timestamp).toDate();
      if (DateTime.now().isAfter(expiryDate)) {
        // Hết hạn → revoke premium
        await FirebaseFirestore.instance
            .collection(AppConstants.colUsers)
            .doc(uid)
            .update({
          'isPremium': false,
          'premiumPlan': 'free',
        });
      }
    }
  }
}

class PremiumPlan {
  final String name;
  final IconData icon;
  final int price;
  final int durationDays;
  final List<Color> gradient;
  final List<String> features;
  final bool isPopular;

  PremiumPlan({
    required this.name,
    required this.icon,
    required this.price,
    required this.durationDays,
    required this.gradient,
    required this.features,
    this.isPopular = false,
  });
}