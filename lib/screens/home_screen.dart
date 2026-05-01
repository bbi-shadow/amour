import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../controllers/theme_controller.dart';
import '../themes/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Khoi tao hoac tim HomeController
    final controller = Get.put(HomeController());

    return Obx(() {
      final isDark = ThemeController.to.isDark;
      final bgColor = isDark ? AppColors.darkCard : Colors.white;
      final inactiveColor = isDark ? Colors.white38 : Colors.grey.shade400;

      return Scaffold(
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: controller.screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _navItem(controller, 0, Icons.home_rounded, Icons.home_outlined, 'Trang chu', inactiveColor),
                  _navItem(controller, 1, Icons.favorite_rounded, Icons.favorite_outline_rounded, 'Hen ho', inactiveColor),
                  _centerNavBtn(controller),
                  _navItemBadge(controller, 3, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Tin nhan', controller.unreadMessages.value, inactiveColor),
                  _navItemBadge(controller, 4, Icons.person_rounded, Icons.person_outline_rounded, 'Ho so', controller.unreadNotifs.value, inactiveColor),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _centerNavBtn(HomeController controller) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          controller.changeTab(2);
        },
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7C3AED)]),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: const Icon(Icons.explore_rounded, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  Widget _navItem(HomeController controller, int index, IconData active, IconData inactive, String label, Color inactiveColor) {
    final isSelected = controller.currentIndex.value == index;
    final color = isSelected ? AppColors.primary : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: () => controller.changeTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? active : inactive, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _navItemBadge(HomeController controller, int index, IconData active, IconData inactive, String label, int count, Color inactiveColor) {
    final isSelected = controller.currentIndex.value == index;
    final color = isSelected ? AppColors.primary : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: () => controller.changeTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isSelected ? active : inactive, color: color, size: 24),
                if (count > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
