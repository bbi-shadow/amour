import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:confetti/confetti.dart';
import '../models/user_model.dart';
import '../themes/app_theme.dart';
import '../screens/chat/chat_detail_screen.dart';
import '../controllers/match_controller.dart';

class MatchDialog extends StatelessWidget {
  final UserModel matchedUser;
  final String matchId;
  final String currentUserName;
  final String? currentUserPhotoUrl;

  const MatchDialog({
    super.key,
    required this.matchedUser,
    required this.matchId,
    required this.currentUserName,
    this.currentUserPhotoUrl,
  });

  // Phương thức tĩnh để hiển thị Dialog
  static void show(
    BuildContext context, {
    required UserModel matchedUser,
    required String matchId,
    required String currentUserName,
    String? currentUserPhotoUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) => MatchDialog(
        matchedUser: matchedUser,
        matchId: matchId,
        currentUserName: currentUserName,
        currentUserPhotoUrl: currentUserPhotoUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MatchController());

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: ScaleTransition(
            scale: controller.scaleAnim,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 48),
                  const SizedBox(height: 16),
                  const Text("Kết nối thành công",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Text("Bạn và ${matchedUser.name} đã thích nhau",
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 14)),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _avatar(currentUserPhotoUrl, currentUserName),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.favorite_rounded, color: AppColors.primary, size: 32),
                      ),
                      _avatar(matchedUser.photoUrl, matchedUser.name),
                    ],
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.to(() => ChatDetailScreen(
                              conversationId: matchId,
                              otherUserId: matchedUser.uid,
                              otherUserName: matchedUser.name,
                              otherUserPhotoUrl: matchedUser.photoUrl,
                            ));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text("Gửi tin nhắn", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: () => Get.back(),
                      child: const Text("Để sau", style: TextStyle(color: Colors.white38, fontSize: 14))),
                ],
              ),
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: controller.confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [AppColors.primary, Colors.amber, Colors.blue, Colors.white],
        ),
      ],
    );
  }

  Widget _avatar(String? url, String name) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(url, fit: BoxFit.cover)
            : Container(
                color: Colors.white10,
                child: Center(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)))),
      ),
    );
  }
}
