import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/swipe_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/user_model.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/cached_photo_widget.dart';
import '../widgets/match_dialog.dart';
import 'profile_detail_screen.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});
  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> with TickerProviderStateMixin {
  final controller = Get.put(SwipeController());

  late AnimationController _cardCtrl;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  // Drag state
  double _dragX = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _cardSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(1.5, 0))
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeInOut));
    _cardFade = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSwipe(bool isLike) async {
    if (controller.currentProfile == null) return;

    if (isLike) {
      _cardSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(1.5, -0.2))
          .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
      HapticFeedback.mediumImpact();
    } else {
      _cardSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(-1.5, -0.2))
          .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
      HapticFeedback.lightImpact();
    }

    await _cardCtrl.forward();
    _cardCtrl.reset();
    setState(() { _dragX = 0; _isDragging = false; });

    final profile = controller.currentProfile!;
    final isMatch = await controller.handleSwipe(isLike);

    if (isMatch && mounted) {
      final matchId = ([controller.uid, profile.uid]..sort()).join('_');
      MatchDialog.show(context, matchedUser: profile, matchId: matchId, currentUserName: 'Bạn');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.to.isDark;
      final bgColor = isDark ? AppColors.darkBg : const Color(0xFFF8F0F2);

      if (controller.isLoading.value) {
        return Scaffold(
          backgroundColor: bgColor,
          body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      }

      if (controller.currentProfile == null) {
        return _buildEmptyState(isDark);
      }

      final user = controller.currentProfile!;
      final nextUser = controller.nextProfile;

      return Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(children: [
            _buildHeader(isDark),
            _buildFilterChips(isDark),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    setState(() {
                      _dragX += d.delta.dx;
                      _isDragging = true;
                    });
                  },
                  onHorizontalDragEnd: (d) {
                    if (_dragX > 80) {
                      _onSwipe(true);
                    } else if (_dragX < -80) {
                      _onSwipe(false);
                    } else {
                      setState(() { _dragX = 0; _isDragging = false; });
                    }
                  },
                  child: Stack(children: [
                    if (nextUser != null) _buildCard(nextUser, isDark, isBehind: true),
                    SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
                        child: Transform.translate(
                          offset: Offset(_isDragging ? _dragX : 0, 0),
                          child: Transform.rotate(
                            angle: _isDragging ? (_dragX / 800) : 0,
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: () => Get.to(() => ProfileDetailScreen(user: user)),
                                  child: _buildCard(user, isDark),
                                ),
                                // Like / Nope overlay
                                if (_isDragging && _dragX > 20)
                                  Positioned(
                                    top: 40, left: 20,
                                    child: _swipeLabel('THÍCH', AppColors.primary),
                                  ),
                                if (_isDragging && _dragX < -20)
                                  Positioned(
                                    top: 40, right: 20,
                                    child: _swipeLabel('BỎ QUA', Colors.red),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            _buildActionButtons(isDark),
            const SizedBox(height: 20),
          ]),
        ),
      );
    });
  }

  Widget _swipeLabel(String text, Color color) {
    return Transform.rotate(
      angle: text == 'THÍCH' ? -0.3 : 0.3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hẹn Hò', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
          Text('Gợi ý phù hợp nhất cho bạn', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey)),
        ]),
        const Spacer(),
        // Filter icon - màu primary thay vì màu xanh lá
        GestureDetector(
          onTap: () => _showFilterSheet(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
          ),
        ),
      ]),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final chips = ['Gần đây', 'Tuổi: 18-30', 'Sở thích'];
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        itemBuilder: (ctx, i) => Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: i == 0 ? AppColors.primary : Colors.grey.withOpacity(0.2)),
          ),
          child: Text(chips[i], style: TextStyle(fontSize: 12, color: i == 0 ? AppColors.primary : Colors.grey, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildCard(UserModel user, bool isDark, {bool isBehind = false}) {
    return AnimatedScale(
      scale: isBehind ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isBehind ? 0.05 : 0.15), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(fit: StackFit.expand, children: [
            CachedPhotoWidget(uid: user.uid, photoUrl: user.photoUrl, fit: BoxFit.cover),
            Positioned.fill(child: Container(
              decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                stops: const [0.5, 1.0],
              )),
            )),
            Positioned(
              bottom: 24, left: 24, right: 24,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${user.name}, ${user.age}', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900))),
                  if (user.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 22),
                ]),
                if (user.city.isNotEmpty) Row(children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(user.city, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ]),
                if (user.bio.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(user.bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                ],
                const SizedBox(height: 10),
                Wrap(spacing: 8, children: user.interests.take(3).map((i) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 12)),
                )).toList()),
              ]),
            ),
            // Online dot
            if (user.isOnline)
              Positioned(top: 16, right: 16, child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              )),
          ]),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        // Bỏ qua - đỏ
        _circleBtn(Icons.close_rounded, Colors.red, () => _onSwipe(false), small: false),
        // Super Like - vàng
        _circleBtn(Icons.star_rounded, AppColors.gold, () {}, small: true),
        // Thích - primary (hồng đỏ) - KHÔNG dùng xanh lá
        _circleBtn(Icons.favorite_rounded, AppColors.primary, () => _onSwipe(true), small: false),
        // Quay lại - cam
        _circleBtn(Icons.replay_rounded, Colors.orange, controller.undo, small: true),
      ]),
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap, {required bool small}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: small ? 50 : 64,
        height: small ? 50 : 64,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: color, size: small ? 24 : 32),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ThemeController.to.isDark ? AppColors.darkBg : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Bộ lọc tìm kiếm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.grey, side: BorderSide(color: Colors.grey.shade300)),
              child: const Text('Đóng'),
            )),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Áp dụng'),
            )),
          ]),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.favorite_border_rounded, size: 80, color: AppColors.primary.withOpacity(0.3)),
        const SizedBox(height: 24),
        const Text('Hết người để gợi ý rồi!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Hãy quay lại sau nhé', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: controller.loadProfiles,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tải lại'),
        ),
      ])),
    );
  }
}