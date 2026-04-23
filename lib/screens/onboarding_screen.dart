import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import 'auth/login_screen.dart';

/// ══════════════════════════════════════════════════════════════
/// OnboardingScreen — Màn hình giới thiệu ứng dụng
/// 4 slides đẹp với animation mượt
/// ══════════════════════════════════════════════════════════════
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _currentPage = 0;

  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  final List<_OnboardingData> _slides = [
    _OnboardingData(
      emoji: '💕',
      title: 'Tìm người\nhoàn hảo',
      subtitle: 'Hàng ngàn hồ sơ thú vị đang chờ bạn. Vuốt để khám phá!',
      gradient: [const Color(0xFFFF4B6E), const Color(0xFFFF8E9B)],
      bgEmojis: ['💝', '💖', '✨', '🌹', '💫'],
    ),
    _OnboardingData(
      emoji: '🔥',
      title: 'Match ngay\nkhi cả hai thích',
      subtitle: 'Khi hai trái tim cùng nhịp đập — một match mới được tạo ra!',
      gradient: [const Color(0xFFFF6B35), const Color(0xFFFF4B6E)],
      bgEmojis: ['🔥', '⚡', '💥', '✨', '🎯'],
    ),
    _OnboardingData(
      emoji: '💬',
      title: 'Trò chuyện\nthoải mái',
      subtitle: 'Chat, gửi ảnh, voice message và gọi video với người ấy.',
      gradient: [const Color(0xFF9B59B6), const Color(0xFF6C3483)],
      bgEmojis: ['💬', '🎵', '📱', '🌙', '⭐'],
    ),
    _OnboardingData(
      emoji: '💍',
      title: 'Tình yêu\nđích thực',
      subtitle: 'Hàng ngàn cặp đôi đã tìm thấy nhau. Câu chuyện của bạn bắt đầu hôm nay!',
      gradient: [const Color(0xFFFF4B6E), const Color(0xFF9B59B6)],
      bgEmojis: ['💍', '🌹', '💕', '🥂', '🎉'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _goToLogin();
    }
  }

  void _goToLogin() {
    // Lưu đã xem onboarding
    Get.offAll(() => LoginScreen(), transition: Transition.fadeIn);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: slide.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Floating bg emojis
              ..._buildFloatingEmojis(slide.bgEmojis),

              Column(
                children: [
                  // Skip button
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: _goToLogin,
                      child: const Text('Bỏ qua',
                          style: TextStyle(color: Colors.white70, fontSize: 15)),
                    ),
                  ),

                  // PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageCtrl,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemCount: _slides.length,
                      itemBuilder: (_, i) => _buildSlide(_slides[i]),
                    ),
                  ),

                  // Bottom controls
                  _buildBottomControls(),
                  const SizedBox(height: 32),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide(_OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main emoji with float animation
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: child,
            ),
            child: Container(
              width: 160, height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30, offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(data.emoji, style: const TextStyle(fontSize: 72)),
              ),
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

  Widget _buildBottomControls() {
    final isLast = _currentPage == _slides.length - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final active = i == _currentPage;
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
            onTap: _nextPage,
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
                    blurRadius: 16, offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: isLast
                    ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Bắt đầu ngay',
                            style: TextStyle(
                              color: _slides[_currentPage].gradient.first,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            )),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded,
                            color: _slides[_currentPage].gradient.first, size: 22),
                      ])
                    : Icon(Icons.arrow_forward_rounded,
                        color: _slides[_currentPage].gradient.first, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingEmojis(List<String> emojis) {
    final positions = [
      const Offset(20, 80), const Offset(300, 120),
      const Offset(50, 450), const Offset(320, 380),
      const Offset(160, 600),
    ];
    return List.generate(emojis.length, (i) {
      return Positioned(
        left: positions[i].dx,
        top: positions[i].dy,
        child: AnimatedBuilder(
          animation: _floatAnim,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, _floatAnim.value * (i.isEven ? 1 : -1)),
            child: child,
          ),
          child: Text(emojis[i],
              style: TextStyle(fontSize: 24, color: Colors.white.withOpacity(0.25))),
        ),
      );
    });
  }
}

class _OnboardingData {
  final String emoji, title, subtitle;
  final List<Color> gradient;
  final List<String> bgEmojis;
  _OnboardingData({
    required this.emoji, required this.title,
    required this.subtitle, required this.gradient,
    required this.bgEmojis,
  });
}
