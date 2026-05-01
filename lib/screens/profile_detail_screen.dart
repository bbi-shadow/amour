import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../controllers/profile_detail_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/match_dialog.dart'; // Đã đổi import
import 'chat/chat_detail_screen.dart';

class ProfileDetailScreen extends StatelessWidget {
  final UserModel user;
  const ProfileDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileDetailController(user: user), tag: user.uid);
    final isDark = ThemeController.to.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.black,
      body: Stack(
        children: [
          _buildPhotoSlider(controller),
          SafeArea(child: _buildTopBar()),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel(context, controller, isDark)),
        ],
      ),
    );
  }

  Widget _buildPhotoSlider(ProfileDetailController controller) {
    final photos = user.photos.isNotEmpty ? user.photos : [user.photoUrl];
    return PageView.builder(
      onPageChanged: (i) => controller.currentPhotoIndex.value = i,
      itemCount: photos.length,
      itemBuilder: (_, i) => photos[i].isNotEmpty
          ? Image.network(photos[i], fit: BoxFit.cover)
          : Container(color: AppColors.primary),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        _topButton(Icons.arrow_back_ios_new_rounded, () => Get.back()),
        const Spacer(),
        _topButton(Icons.more_horiz_rounded, () {}),
      ]),
    );
  }

  Widget _topButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, ProfileDetailController controller, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, 
          end: Alignment.bottomCenter, 
          colors: [Colors.transparent, isDark ? AppColors.darkBg : Colors.black],
          stops: const [0.0, 0.8]
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('${user.name}, ${user.age}', 
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (user.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 24),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(user.city, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 24),
          _buildActionButtons(context, controller),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProfileDetailController controller) {
    return Obx(() {
      if (controller.isMatched.value) {
        return Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Get.to(() => ChatDetailScreen(
                conversationId: controller.conversationId.value,
                otherUserId: user.uid,
                otherUserName: user.name,
                otherUserPhotoUrl: user.photoUrl,
              )),
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('Nhắn tin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              ),
            ),
          ),
          const SizedBox(width: 12),
          _circleActionBtn(Icons.call_outlined, Colors.green, () => controller.initiateCall(isVideo: false)),
          const SizedBox(width: 12),
          _circleActionBtn(Icons.videocam_outlined, Colors.blue, () => controller.initiateCall(isVideo: true)),
        ]);
      }

      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _circleActionBtn(Icons.close_rounded, Colors.red, () => Get.back()),
        _circleActionBtn(Icons.favorite_rounded, Colors.green, () async {
          final isMatch = await controller.handleSwipe();
          if (isMatch) {
            // Hiển thị Dialog chúc mừng
            MatchDialog.show(
              context, 
              matchedUser: user, 
              matchId: controller.conversationId.value, 
              currentUserName: 'Bạn'
            );
          }
        }, size: 70),
        _circleActionBtn(Icons.star_rounded, Colors.blue, () {}),
      ]);
    });
  }

  Widget _circleActionBtn(IconData icon, Color color, VoidCallback onTap, {double size = 55}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.white, 
          shape: BoxShape.circle, 
          boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}
