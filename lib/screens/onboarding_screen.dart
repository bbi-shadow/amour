import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';
import '../themes/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());

    return Scaffold(
      body: Obx(() {
        final slide = controller.slides[controller.currentPage.value];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: slide.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: controller.skip,
                    child: const Text('Bo qua',
                        style: TextStyle(color: Colors.white70, fontSize: 15)),
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    itemCount: controller.slides.length,
                    itemBuilder: (_, i) => _buildSlide(controller.slides[i]),
                  ),
                ),

                // Bottom controls
                _buildBottomControls(controller),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSlide(OnboardingSlide data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Icon(data.icon, size: 72, color: Colors.white),
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(OnboardingController controller) {
    final isLast = controller.currentPage.value == controller.slides.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(controller.slides.length, (i) {
              final active = i == controller.currentPage.value;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 28 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),

          // Next / Get Started button
          GestureDetector(
            onTap: controller.next,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isLast ? double.infinity : 70,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isLast ? 18 : 35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: isLast
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Bat dau ngay',
                            style: TextStyle(
                              color: controller.slides[controller.currentPage.value].gradient.first,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            )),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            color: controller.slides[controller.currentPage.value].gradient.first, size: 22),
                      ])
                    : Icon(Icons.arrow_forward_rounded,
                        color: controller.slides[controller.currentPage.value].gradient.first, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
