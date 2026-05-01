import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/premium_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PremiumController());
    final isDark = ThemeController.to.isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
              ? [const Color(0xFF0F0F1A), const Color(0xFF1A1A2E)] 
              : [const Color(0xFFFDFCFD), const Color(0xFFF8F9FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildPlanCards(controller, isDark),
                      const SizedBox(height: 32),
                      _buildFeaturesList(controller, isDark),
                      const SizedBox(height: 32),
                      _buildSubscribeButton(controller),
                      const SizedBox(height: 20),
                      _buildFooter(isDark),
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

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black87),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Amour Premium',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Trai nghiem nhung tinh nang dac quyen',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildPlanCards(PremiumController controller, bool isDark) {
    return Obx(() => Row(
      children: List.generate(controller.plans.length, (i) {
        final plan = controller.plans[i];
        final selected = controller.selectedPlanIndex.value == i;
        
        return Expanded(
          child: GestureDetector(
            onTap: () => controller.selectedPlanIndex.value = i,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                gradient: selected ? LinearGradient(colors: plan.gradient) : null,
                color: selected ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? Colors.white30 : (isDark ? Colors.white10 : Colors.grey.shade200),
                  width: 2,
                ),
                boxShadow: selected ? [
                  BoxShadow(color: plan.gradient.first.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))
                ] : null,
              ),
              child: Column(
                children: [
                  Icon(plan.icon, color: selected ? Colors.white : plan.gradient.first, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    plan.name,
                    style: TextStyle(
                      color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppHelpers.formatPrice(plan.price),
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    ));
  }

  Widget _buildFeaturesList(PremiumController controller, bool isDark) {
    return Obx(() {
      final plan = controller.plans[controller.selectedPlanIndex.value];
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tinh nang goi ${plan.name}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ...plan.features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Text(f, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
                ],
              ),
            )).toList(),
          ],
        ),
      );
    });
  }

  Widget _buildSubscribeButton(PremiumController controller) {
    return Obx(() {
      final plan = controller.plans[controller.selectedPlanIndex.value];
      return SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.subscribe,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 8,
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
          child: controller.isLoading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Kich hoat ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      );
    });
  }

  Widget _buildFooter(bool isDark) {
    return Column(
      children: [
        Text(
          'Gia han tu dong hang thang. Huy bat ky luc nao.',
          style: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          'Dieu khoan va Chinh sach',
          style: TextStyle(
            color: AppColors.primary.withOpacity(0.7),
            fontSize: 11,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }
}
