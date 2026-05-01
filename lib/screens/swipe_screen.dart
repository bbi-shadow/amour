import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/swipe_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/user_model.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/cached_photo_widget.dart';
import '../widgets/match_dialog.dart'; // Đã đổi import
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
    
    // Animation logic
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

    // Business logic
    final profile = controller.currentProfile!;
    final isMatch = await controller.handleSwipe(isLike);
    
    if (isMatch && mounted) {
      final matchId = ([controller.uid, profile.uid]..sort()).join('_');
      // Sử dụng MatchDialog.show thay cho MatchPopup
      MatchDialog.show(context, matchedUser: profile, matchId: matchId, currentUserName: 'Ban');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.to.isDark;
      final bgColor = isDark ? AppColors.darkBg : const Color(0xFFF8F0F2);

      if (controller.isLoading.value) {
        return Scaffold(backgroundColor: bgColor, body: const Center(child: CircularProgressIndicator(color: AppColors.primary)));
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
                child: Stack(children: [
                  if (nextUser != null) _buildCard(nextUser, isDark, isBehind: true),
                  SlideTransition(
                    position: _cardSlide,
                    child: FadeTransition(
                      opacity: _cardFade,
                      child: GestureDetector(
                        onTap: () => Get.to(() => ProfileDetailScreen(user: user)),
                        child: _buildCard(user, isDark),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            _buildActionButtons(isDark),
            const SizedBox(height: 20),
          ]),
        ),
      );
    });
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hen Ho', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
          Text('Goi y phu hop nhat cho ban', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey)),
        ]),
        const Spacer(),
        IconButton(icon: const Icon(Icons.tune_rounded), onPressed: () {}),
      ]),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final chips = ['Gan day', 'Tuoi: 18-30', 'So thich'];
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
            Positioned.fill(child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.85)], stops: const [0.5, 1.0])))),
            Positioned(
              bottom: 24, left: 24, right: 24,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${user.name}, ${user.age}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                Row(children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(user.city, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ]),
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: user.interests.take(3).map((i) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 12)))).toList()),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _circleBtn(Icons.close_rounded, Colors.red, () => _onSwipe(false), small: false),
        _circleBtn(Icons.star_rounded, Colors.blue, () {}, small: true),
        _circleBtn(Icons.favorite_rounded, Colors.green, () => _onSwipe(true), small: false),
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
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Icon(icon, color: color, size: small ? 24 : 32),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey),
        const SizedBox(height: 24),
        const Text('Het nguoi de quet roi!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Hay quay lai sau nhe', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: controller.loadProfiles, child: const Text('Tai lai')),
      ])),
    );
  }
}
