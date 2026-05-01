import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/app_constants.dart';

class OnboardingController extends GetxController {
  static OnboardingController get to => Get.find();

  final pageController = PageController();
  final RxInt currentPage = 0.obs;

  final List<OnboardingSlide> slides = [
    OnboardingSlide(
      icon: Icons.favorite_rounded,
      title: 'Tim nguoi\nhoan hao',
      subtitle: 'Hang ngan ho so thu vi dang cho ban. Vuot de kham pha ngay!',
      gradient: [const Color(0xFFFF4B6E), const Color(0xFFFF8E9B)],
    ),
    OnboardingSlide(
      icon: Icons.auto_awesome_rounded,
      title: 'Match ngay\nkhi ca hai thich',
      subtitle: 'Khi hai trai tim cung nhip dap — mot match moi duoc tao ra!',
      gradient: [const Color(0xFFFF6B35), const Color(0xFFFF4B6E)],
    ),
    OnboardingSlide(
      icon: Icons.chat_bubble_rounded,
      title: 'Tro chuyen\nthoai mai',
      subtitle: 'Chat, gui anh va goi video voi nguoi ay mot cach de dang.',
      gradient: [const Color(0xFF9B59B6), const Color(0xFF6C3483)],
    ),
    OnboardingSlide(
      icon: Icons.loyalty_rounded,
      title: 'Tinh yeu\ndich thuc',
      subtitle: 'Hang ngan cap doi da tim thay nhau. Câu chuyện của bạn bắt đầu ngay hôm nay!',
      gradient: [const Color(0xFFFF4B6E), const Color(0xFF9B59B6)],
    ),
  ];

  void onPageChanged(int index) => currentPage.value = index;

  void next() {
    if (currentPage.value < slides.length - 1) {
      pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      skip();
    }
  }

  void skip() {
    Get.offAllNamed(AppRoutes.login);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class OnboardingSlide {
  final IconData icon;
  final String title, subtitle;
  final List<Color> gradient;
  OnboardingSlide({required this.icon, required this.title, required this.subtitle, required this.gradient});
}
