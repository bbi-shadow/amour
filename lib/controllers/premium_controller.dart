import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

class PremiumController extends GetxController {
  static PremiumController get to => Get.find();

  final RxInt selectedPlanIndex = 1.obs;
  final RxBool isLoading = false.obs;
  final String uid = AuthController.to.currentUid ?? '';

  final List<PremiumPlan> plans = [
    PremiumPlan(
      name: 'Basic',
      icon: Icons.auto_awesome_outlined,
      price: 99000,
      gradient: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      features: [
        'Xem ai da thich ban',
        'Luot thich vo han',
        '5 Luot thich dac biet moi ngay',
        'Xoa quang cao',
      ],
    ),
    PremiumPlan(
      name: 'Gold',
      icon: Icons.star_outline_rounded,
      price: 199000,
      gradient: [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      features: [
        'Xem ai da thich ban',
        'Luot thich vo han',
        '10 Luot thich dac biet moi ngay',
        'Day ho so hang tuan',
        'Uu tien hien thi',
      ],
      isPopular: true,
    ),
    PremiumPlan(
      name: 'Platinum',
      icon: Icons.diamond_outlined,
      price: 299000,
      gradient: [const Color(0xFFB9A0FF), const Color(0xFF9B59B6)],
      features: [
        'Xem ai da thich ban',
        'Luot thich vo han',
        'Luot thich dac biet khong gioi han',
        'Day ho so moi ngay',
        'Uu tien hien thi toi da',
      ],
    ),
  ];

  Future<void> subscribe() async {
    final plan = plans[selectedPlanIndex.value];
    final confirmed = await AppHelpers.confirm(
      title: 'Xac nhan dang ky',
      message: 'Ban co muon dang ky goi ${plan.name} voi gia ${AppHelpers.formatPrice(plan.price)}/thang?',
    );
    if (!confirmed) return;

    isLoading.value = true;
    try {
      final endDate = DateTime.now().add(const Duration(days: 30));
      final planName = plan.name.toLowerCase();

      await FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).update({
        'isPremium': true,
        'premiumPlan': planName,
        'premiumExpiry': Timestamp.fromDate(endDate),
      });

      await FirebaseFirestore.instance.collection('subscriptions').add({
        'userId': uid,
        'plan': planName,
        'price': plan.price,
        'startDate': Timestamp.now(),
        'endDate': Timestamp.fromDate(endDate),
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      AppHelpers.showSuccess('Kich hoat goi ${plan.name} thanh cong!');
      Get.back();
    } catch (e) {
      AppHelpers.showError('Dang ky that bai. Vui long thu lai sau!');
    } finally {
      isLoading.value = false;
    }
  }
}

class PremiumPlan {
  final String name;
  final IconData icon;
  final int price;
  final List<Color> gradient;
  final List<String> features;
  final bool isPopular;

  PremiumPlan({
    required this.name,
    required this.icon,
    required this.price,
    required this.gradient,
    required this.features,
    this.isPopular = false,
  });
}
