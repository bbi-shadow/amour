import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '/screens/chat/chat_detail_screen.dart'; // ✅ dùng đúng ChatDetailScreen

class MatchPopup extends StatelessWidget {
  final UserModel matchedUser;
  final String matchId;
  final String currentUserName;
  final String? currentUserPhotoUrl;

  const MatchPopup({
    super.key,
    required this.matchedUser,
    required this.matchId,
    this.currentUserName = 'Bạn',
    this.currentUserPhotoUrl,
  });

  static Future<void> show(
      BuildContext context, {
        required UserModel matchedUser,
        required String matchId,
        String currentUserName = 'Bạn',
        String? currentUserPhotoUrl,
      }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => MatchPopup(
        matchedUser: matchedUser,
        matchId: matchId,
        currentUserName: currentUserName,
        currentUserPhotoUrl: currentUserPhotoUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFFF6B8A).withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✨ Confetti hearts
            const Text('💕', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            const Text(
              'Thật tuyệt!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bạn và ${matchedUser.name} đã thích nhau!',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Avatars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _avatar(currentUserPhotoUrl, currentUserName),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const Icon(Icons.favorite,
                          color: Color(0xFFFF6B8A), size: 28),
                      const SizedBox(height: 4),
                      Container(
                        width: 40, height: 1,
                        color: const Color(0xFFFF6B8A).withOpacity(0.4),
                      ),
                    ],
                  ),
                ),
                _avatar(
                    matchedUser.photoUrl.isNotEmpty ? matchedUser.photoUrl : null,
                    matchedUser.name),
              ],
            ),
            const SizedBox(height: 28),

            // Nút Nhắn tin
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(
                        conversationId: matchId,          // ✅ matchId = conversationId
                        otherUserId: matchedUser.uid,
                        otherUserName: matchedUser.name,
                        otherUserPhotoUrl: matchedUser.photoUrl.isNotEmpty
                            ? matchedUser.photoUrl
                            : null,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                label: const Text(
                  'Nhắn tin ngay',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Nút Tiếp tục
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Tiếp tục khám phá',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String? photoUrl, String name) {
    return Column(
      children: [
        Container(
          width: 76, height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B8A), Color(0xFFFFB3C1)],
            ),
            border: Border.all(color: const Color(0xFFFF6B8A), width: 2.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B8A).withOpacity(0.35),
                blurRadius: 12,
              ),
            ],
          ),
          child: photoUrl != null && photoUrl.isNotEmpty
              ? ClipOval(
            child: Image.network(photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initials(name)),
          )
              : _initials(name),
        ),
        const SizedBox(height: 6),
        Text(name,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _initials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
      ),
    );
  }
}