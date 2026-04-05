import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/match_service.dart';
import '../widgets/match_popup.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat/chat_detail_screen.dart'; // ✅ Tính năng: nút nhắn tin

class ProfileDetailScreen extends StatefulWidget {
  final UserModel user;
  final bool isLiked;

  const ProfileDetailScreen({
    super.key,
    required this.user,
    this.isLiked = false,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  bool _isLoading = false;
  bool _isCheckingMatch = true; // ✅ kiểm tra xem đã match chưa
  bool _isMatched = false;      // ✅ trạng thái đã match
  String? _conversationId;      // ✅ lưu conversationId nếu đã match
  final MatchService _matchService = MatchService();
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.isLiked;
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _heartController, curve: Curves.elasticOut));

    _checkMatchStatus(); // ✅ kiểm tra match khi vào màn hình
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  // ✅ Tính năng: kiểm tra xem 2 người đã match chưa
  Future<void> _checkMatchStatus() async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser!.uid;
      final matched = await _matchService.isMatched(widget.user.uid);
      if (matched) {
        // Tìm conversationId
        final sorted = [currentUid, widget.user.uid]..sort();
        final convId = '${sorted[0]}_${sorted[1]}';
        setState(() {
          _isMatched = true;
          _conversationId = convId;
          _isLiked = true;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isCheckingMatch = false);
  }

  Future<void> _handleLike() async {
    if (_isLoading) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isLiked = true;
      _isLoading = true;
    });
    _heartController.forward(from: 0);

    try {
      final matchData = await _matchService.swipeRight(widget.user.uid);

      if (matchData != null && mounted) {
        final matchId = matchData['matchId'] as String;

        // ✅ FIX: dùng widget.user trực tiếp thay vì re-parse dirty matchData
        final currentUser = FirebaseAuth.instance.currentUser!;
        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        final currentData = currentUserDoc.data();

        // Tạo conversation nếu chưa có
        await _ensureConversation(matchId, widget.user.uid);

        setState(() {
          _isMatched = true;
          _conversationId = matchId;
        });

        await MatchPopup.show(
          context,
          matchedUser: widget.user,   // ✅ dùng trực tiếp
          matchId: matchId,
          currentUserName:
          currentData?['name'] ?? currentData?['displayName'] ?? 'Bạn',
          currentUserPhotoUrl:
          currentData?['photoUrl'] ?? currentData?['profileImageUrl'],
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Đã thích ${widget.user.name}!'),
              ],
            ),
            backgroundColor: const Color(0xFFFF6B8A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLiked = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ensureConversation(String matchId, String otherUid) async {
    final convRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(matchId);
    final snap = await convRef.get();
    if (!snap.exists) {
      final currentUid = FirebaseAuth.instance.currentUser!.uid;
      await convRef.set({
        'participants': [currentUid, otherUid],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'unreadCount': {currentUid: 0, otherUid: 0},
      });
    }
  }

  Future<void> _handleDislike() async {
    HapticFeedback.lightImpact();
    await _matchService.swipeLeft(widget.user.uid);
    if (mounted) Navigator.pop(context, 'disliked');
  }

  // ✅ Tính năng: chuyển sang màn hình chat
  void _openChat() {
    if (_conversationId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          conversationId: _conversationId!,
          otherUserId: widget.user.uid,
          otherUserName: widget.user.name,
          otherUserPhotoUrl:
          widget.user.photoUrl.isNotEmpty ? widget.user.photoUrl : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildPhoto(),
          _buildTopBar(),
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildPhoto() {
    return Positioned.fill(
      child: widget.user.photoUrl.isNotEmpty
          ? Image.network(
        widget.user.photoUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholderPhoto(),
      )
          : _buildPlaceholderPhoto(),
    );
  }

  Widget _buildPlaceholderPhoto() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B8A), Color(0xFFFFB3C1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          widget.user.name.isNotEmpty
              ? widget.user.name[0].toUpperCase()
              : '?',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 100,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16, right: 16, bottom: 40,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black54, Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 18),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                // TODO: Report/block
              },
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_outlined,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black.withOpacity(0.92)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 60,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    '${widget.user.name}, ${widget.user.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
                // ✅ Badge "Đã match" nếu match rồi
                if (!_isCheckingMatch && _isMatched)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B8A).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Đã match',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            if (widget.user.city.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Color(0xFFFF9BB0), size: 16),
                  const SizedBox(width: 4),
                  Text(widget.user.city,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                ],
              ),
            const SizedBox(height: 14),

            if (widget.user.bio.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.2), width: 1),
                ),
                child: Text(
                  widget.user.bio,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.5),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 24),

            // ✅ Tính năng: nút Nhắn tin thay thế nút Dislike khi đã match
            if (!_isCheckingMatch && _isMatched)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openChat,
                  icon: const Icon(Icons.chat_bubble_outline,
                      color: Colors.white),
                  label: Text(
                    'Nhắn tin với ${widget.user.name}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B8A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionBtn(
                    icon: Icons.close_rounded,
                    color: Colors.white,
                    bgColor: Colors.white.withOpacity(0.15),
                    size: 56,
                    onTap: _handleDislike,
                  ),
                  _buildLikeButton(),
                  _buildActionBtn(
                    icon: Icons.star_rounded,
                    color: const Color(0xFFFFD700),
                    bgColor: Colors.white.withOpacity(0.15),
                    size: 56,
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      // TODO: super like
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLikeButton() {
    return ScaleTransition(
      scale: _heartScale,
      child: GestureDetector(
        onTap: _isLiked ? null : _handleLike,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 72, height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _isLiked
                ? const LinearGradient(
              colors: [Color(0xFFFF6B8A), Color(0xFFFF9BB0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: _isLiked ? null : Colors.white.withOpacity(0.15),
            boxShadow: _isLiked
                ? [
              BoxShadow(
                color: const Color(0xFFFF6B8A).withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ]
                : [],
          ),
          child: _isLoading
              ? const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          )
              : Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: Colors.white,
            size: 34,
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}