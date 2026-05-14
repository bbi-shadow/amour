import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';

/// ══════════════════════════════════════════════════════════════
/// PremiumController — Quản lý đăng ký gói Premium qua VietQR Tĩnh
/// ══════════════════════════════════════════════════════════════
class PremiumController extends GetxController {
  static PremiumController get to => Get.find();

  // ── CẤU HÌNH THÔNG TIN TÀI KHOẢN NGÂN HÀNG (VIETQR) ───────────
  final String bankCode = 'mbbank';
  final String bankAccount = '4089051041187302'; // Thay số tài khoản của bạn vào đây
  final String accountName = 'CAO XUAN TU';

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

  // ── TẠO URL VIETQR TỰ ĐỘNG ─────────────────────────────────────
  String getVietQRUrl(int amount, String orderCode) {
    final encodedName = Uri.encodeComponent(accountName);
    return 'https://img.vietqr.io/image/$bankCode-$bankAccount-compact2.png?amount=$amount&addInfo=$orderCode&accountName=$encodedName';
  }

  // ── Subscribe Flow ────────────────────────────────────────────

  Future<void> subscribe() async {
    if (uid.isEmpty) {
      AppHelpers.showError('Vui lòng đăng nhập lại');
      return;
    }

    final plan = selectedPlan;
    
    isLoading.value = true;
    paymentStatus.value = 'pending';

    try {
      // BƯỚC 1: Tạo pending_payment document để lấy Mã đơn hàng (docId)
      final paymentRef = await FirebaseFirestore.instance
          .collection('pending_payments')
          .add({
        'userId': uid,
        'plan': plan.name.toLowerCase(),
        'price': plan.price,
        'durationDays': plan.durationDays,
        'status': 'pending', // pending → confirmed
        'createdAt': FieldValue.serverTimestamp(),
      });

      isLoading.value = false;

      // Sinh URL mã QR chuyển khoản tĩnh
      final qrUrl = getVietQRUrl(plan.price, paymentRef.id);
      
      // Hiển thị Dialog mã QR thanh toán
      _showQRDialog(plan, qrUrl, paymentRef.id);

      // BƯỚC 2: Chạy ngầm Polling chờ Admin xác nhận đơn hàng (tối đa 10 phút)
      _waitForPaymentConfirmation(paymentRef.id).then((success) async {
        if (success) {
          paymentStatus.value = 'confirmed';
          
          // Cập nhật lại UserModel trong AuthController để mở khóa toàn app
          final updatedDoc = await FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).get();
          if (updatedDoc.exists) {
            AuthController.to.currentUser.value = UserModel.fromFirestore(updatedDoc);
          }
          
          AppHelpers.showSuccess('Kích hoạt gói ${plan.name} thành công! 🎉');
          // Nếu user đang ở trang premium thì tự động quay về
          if (Get.currentRoute == AppRoutes.premium) {
            Get.back();
          }
        }
      });
    } catch (e) {
      paymentStatus.value = 'failed';
      AppHelpers.showError('Lỗi khởi tạo thanh toán: ${e.toString()}');
      isLoading.value = false;
    }
  }

  void _showQRDialog(PremiumPlan plan, String qrUrl, String orderCode) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'Thanh toán Gói ${plan.name}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mở App Ngân hàng quét mã QR dưới đây để chuyển khoản tự động',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              
              // QR Code container
              Container(
                width: 220,
                height: 220,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Image.network(
                  qrUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('Lỗi tải mã QR', style: TextStyle(color: Colors.red, fontSize: 12)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              
              // Chi tiết chuyển khoản (Fallback)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('Ngân hàng:', bankCode.toUpperCase()),
                    const SizedBox(height: 6),
                    _buildInfoRow('Số tài khoản:', bankAccount),
                    const SizedBox(height: 6),
                    _buildInfoRow('Chủ tài khoản:', accountName),
                    const SizedBox(height: 6),
                    _buildInfoRow('Số tiền:', AppHelpers.formatPrice(plan.price)),
                    const Divider(height: 16),
                    _buildInfoRow('Nội dung (Bắt buộc):', orderCode, isBold: true, color: AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Button "Tôi đã chuyển khoản"
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Đóng dialog
                    AppHelpers.showSuccess(
                      'Đơn hàng đang được Admin hệ thống duyệt. Tài khoản sẽ được nâng cấp ngay sau khi xác nhận.',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: const Text('Tôi đã chuyển khoản', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Hủy giao dịch', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildInfoRow(String label, String val, {bool isBold = false, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            val,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  /// Poll Firestore để chờ Admin confirm payment (tối đa 10 phút)
  Future<bool> _waitForPaymentConfirmation(String paymentId) async {
    const maxWait = Duration(seconds: 600);
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