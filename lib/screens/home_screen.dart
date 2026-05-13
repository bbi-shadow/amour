import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/theme_controller.dart';
import '../repositories/user_repository.dart';
import '../themes/app_theme.dart';

// ── StatefulWidget để dùng WidgetsBindingObserver (online/offline) ──
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _userRepo = UserRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnline(true); // Online khi vào app
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnline(false); // Offline khi destroy
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline(true);  // Quay lại app
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _setOnline(false); // Thoát / minimize
        break;
      default:
        break;
    }
  }

  Future<void> _setOnline(bool online) async {
    try {
      final uid = AuthController.to.currentUid;
      if (uid == null || uid.isEmpty) return;
      await _userRepo.setOnlineStatus(isOnline: online);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
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
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, -2),
              )
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _navItem(controller, 0, Icons.home_rounded, Icons.home_outlined, 'Trang chủ', inactiveColor),
                  _navItem(controller, 1, Icons.favorite_rounded, Icons.favorite_outline_rounded, 'Hẹn hò', inactiveColor),
                  _centerNavBtn(controller),
                  // ── Badge reactive: Obx bao ngoài để update realtime ──
                  Obx(() => _navItemBadge(
                    controller, 3,
                    Icons.chat_bubble_rounded,
                    Icons.chat_bubble_outline_rounded,
                    'Tin nhắn',
                    controller.unreadMessages.value, // đọc trong Obx → reactive
                    inactiveColor,
                  )),
                  _navItem(controller, 4, Icons.settings_rounded, Icons.settings_outlined, 'Cài đặt', inactiveColor),
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
        child: Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.explore_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }

  Widget _navItem(HomeController controller, int index, IconData active,
      IconData inactive, String label, Color inactiveColor) {
    final isSelected = controller.currentIndex.value == index;
    final color = isSelected ? AppColors.primary : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          controller.changeTab(index);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? active : inactive, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _navItemBadge(HomeController controller, int index, IconData active,
      IconData inactive, String label, int count, Color inactiveColor) {
    final isSelected = controller.currentIndex.value == index;
    final color = isSelected ? AppColors.primary : inactiveColor;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          controller.changeTab(index);
        },
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
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}