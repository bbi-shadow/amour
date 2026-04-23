import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:confetti/confetti.dart';
import '../models/user_model.dart';
import '../themes/app_theme.dart';
import '../screens/chat/chat_detail_screen.dart';

class MatchPopup {
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
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (_) => _MatchDialog(
        matchedUser: matchedUser,
        matchId: matchId,
        currentUserName: currentUserName,
        currentUserPhotoUrl: currentUserPhotoUrl,
      ),
    );
  }
}

class _MatchDialog extends StatefulWidget {
  final UserModel matchedUser;
  final String matchId;
  final String currentUserName;
  final String? currentUserPhotoUrl;

  const _MatchDialog({
    required this.matchedUser,
    required this.matchId,
    required this.currentUserName,
    this.currentUserPhotoUrl,
  });

  @override
  State<_MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends State<_MatchDialog> with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play(); 

    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.elasticOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF4B6E), Color(0xFF9B59B6)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [BoxShadow(color: Colors.pink.withOpacity(0.3), blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("IT'S A MATCH!", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 10),
                  Text("Bạn và ${widget.matchedUser.name} đã thích nhau", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _avatar(widget.currentUserPhotoUrl, widget.currentUserName),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.favorite, color: Colors.white, size: 40),
                      ),
                      _avatar(widget.matchedUser.photoUrl, widget.matchedUser.name),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Get.to(() => ChatDetailScreen(
                          conversationId: widget.matchId,
                          otherUserId: widget.matchedUser.uid,
                          otherUserName: widget.matchedUser.name,
                          otherUserPhotoUrl: widget.matchedUser.photoUrl,
                        ));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFFF4B6E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      child: const Text("Gửi tin nhắn ngay", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("Để sau", style: TextStyle(color: Colors.white70))),
                ],
              ),
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [Colors.white, Colors.pink, Colors.orange, Colors.blue],
        ),
      ],
    );
  }

  Widget _avatar(String? url, String name) {
    return Container(
      width: 90, height: 90,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
      child: ClipOval(child: url != null && url.isNotEmpty ? Image.network(url, fit: BoxFit.cover) : Container(color: Colors.grey[300], child: Center(child: Text(name[0], style: const TextStyle(fontSize: 30))))),
    );
  }
}
