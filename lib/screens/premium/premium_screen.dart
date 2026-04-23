import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';

/// ══════════════════════════════════════════════════════════════
/// PremiumScreen — Màn hình đăng ký gói VIP / Premium
/// - 3 gói: Basic, Gold, Platinum
/// - Hiển thị features của từng gói
/// - Glassmorphism design
/// ══════════════════════════════════════════════════════════════
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});
  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedPlan = 1; // 0=basic, 1=gold, 2=platinum
  bool _isLoading = false;
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  final List<_PlanData> _plans = [
    _PlanData(
      name: 'Basic',
      emoji: '✨',
      price: 99000,
      duration: '1 tháng',
      color: const Color(0xFF667EEA),
      gradient: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      features: [
        '❌ Xem ai đã thích bạn',
        '✅ Unlimited Likes',
        '✅ 5 Super Likes/ngày',
        '❌ Boost Profile',
        '✅ Xoá quảng cáo',
        '❌ Ưu tiên match',
      ],
    ),
    _PlanData(
      name: 'Gold',
      emoji: '⭐',
      price: 199000,
      duration: '1 tháng',
      color: const Color(0xFFFFD700),
      gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      features: [
        '✅ Xem ai đã thích bạn',
        '✅ Unlimited Likes',
        '✅ 10 Super Likes/ngày',
        '✅ 1 Boost/tuần',
        '✅ Xoá quảng cáo',
        '✅ Ưu tiên match',
      ],
      isPopular: true,
    ),
    _PlanData(
      name: 'Platinum',
      emoji: '💎',
      price: 299000,
      duration: '1 tháng',
      color: const Color(0xFFB9A0FF),
      gradient: [const Color(0xFFB9A0FF), const Color(0xFF9B59B6)],
      features: [
        '✅ Xem ai đã thích bạn',
        '✅ Unlimited Likes',
        '✅ Unlimited Super Likes',
        '✅ 1 Boost/ngày',
        '✅ Xoá quảng cáo',
        '✅ Ưu tiên match tối đa',
      ],
    ),
  ];

  Future<void> _subscribe() async {
    final confirmed = await AppHelpers.confirm(
      title: 'Xác nhận đăng ký',
      message: 'Đăng ký gói ${_plans[_selectedPlan].name} - '
          '${AppHelpers.formatPrice(_plans[_selectedPlan].price)}/tháng?',
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      // TODO: Tích hợp payment gateway thực tế (VNPay, ZaloPay, ...)
      // Hiện tại demo: cập nhật trực tiếp Firestore

      final endDate = DateTime.now().add(const Duration(days: 30));
      final plan = _plans[_selectedPlan].name.toLowerCase();

      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'isPremium': true,
        'premiumPlan': plan,
        'premiumExpiry': Timestamp.fromDate(endDate),
        // Premium features
        if (plan == 'gold') 'boostCount': FieldValue.increment(4),
        if (plan == 'platinum') 'boostCount': 999,
        'superLikeCount': plan == 'platinum' ? 999 : plan == 'gold' ? 10 : 5,
      });

      // Ghi subscription record
      await FirebaseFirestore.instance.collection('subscriptions').add({
        'userId': _uid,
        'plan': plan,
        'price': _plans[_selectedPlan].price,
        'currency': 'VND',
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(endDate),
        'status': 'active',
        'paymentMethod': 'demo',
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppHelpers.showSuccess('Đã kích hoạt gói ${_plans[_selectedPlan].name}! 🎉');
      Get.back();
    } catch (e) {
      AppHelpers.showError('Đăng ký thất bại. Thử lại sau!');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildPlanCards(),
                      const SizedBox(height: 24),
                      _buildFeaturesComparison(),
                      const SizedBox(height: 24),
                      _buildSubscribeButton(),
                      const SizedBox(height: 16),
                      _buildTerms(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
          const Expanded(
            child: Column(
              children: [
                Text('💎 Amour Premium',
                    style: TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w800)),
                Text('Mở khoá tất cả tính năng',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPlanCards() {
    return Row(
      children: List.generate(_plans.length, (i) {
        final plan = _plans[i];
        final selected = _selectedPlan == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPlan = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(
                left: i == 0 ? 0 : 6,
                right: i == 2 ? 0 : 6,
                top: selected ? 0 : 12,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(colors: plan.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight)
                    : null,
                color: selected ? null : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.white.withOpacity(0.5) : Colors.transparent,
                  width: 2,
                ),
                boxShadow: selected ? [
                  BoxShadow(color: plan.color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
                ] : null,
              ),
              child: Column(
                children: [
                  if (plan.isPopular == true)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('PHỔ BIẾN', style: TextStyle(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                    ),
                  Text(plan.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(plan.name, style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(AppHelpers.formatPrice(plan.price),
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('/tháng', style: TextStyle(
                      color: selected ? Colors.white70 : Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFeaturesComparison() {
    final plan = _plans[_selectedPlan];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tính năng gói ${plan.name}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          ...plan.features.map((f) {
            final isIncluded = f.startsWith('✅');
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: isIncluded
                        ? AppColors.success.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncluded ? Icons.check : Icons.close,
                    color: isIncluded ? AppColors.success : Colors.red.shade400,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(f.substring(2).trim(), style: TextStyle(
                  color: isIncluded ? Colors.white : Colors.white38,
                  fontSize: 14,
                )),
              ]),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    final plan = _plans[_selectedPlan];
    return GestureDetector(
      onTap: _isLoading ? null : _subscribe,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: plan.gradient),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: plan.color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(
                  'Đăng ký ${plan.name} - ${AppHelpers.formatPrice(plan.price)}/tháng',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
        ),
      ),
    );
  }

  Widget _buildTerms() {
    return const Column(children: [
      Text('Đăng ký tự động gia hạn mỗi tháng.',
          style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
      SizedBox(height: 4),
      Text('Huỷ bất cứ lúc nào trong Cài đặt.',
          style: TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
    ]);
  }
}

class _PlanData {
  final String name;
  final String emoji;
  final int price;
  final String duration;
  final Color color;
  final List<Color> gradient;
  final List<String> features;
  final bool? isPopular;

  _PlanData({
    required this.name,
    required this.emoji,
    required this.price,
    required this.duration,
    required this.color,
    required this.gradient,
    required this.features,
    this.isPopular,
  });
}
