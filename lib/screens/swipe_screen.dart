import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../themes/app_theme.dart';
import '../widgets/cached_photo_widget.dart';
import '../widgets/match_popup.dart';
import 'profile_detail_screen.dart';

class SwipeScreen extends StatefulWidget {
  @override
  _SwipeScreenState createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> with TickerProviderStateMixin {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  List<UserModel> _profiles = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSwiping = false;

  // Animation controllers cho các nút
  late AnimationController _likeController;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _likeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      // 🧠 Gọi thuật toán Recommendation từ FirestoreService
      final profiles = await FirestoreService.getDiscoveryProfiles();
      setState(() {
        _profiles = profiles;
        _currentIndex = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSwipe(bool isLike) async {
    if (_currentIndex >= _profiles.length || _isSwiping) return;
    
    final target = _profiles[_currentIndex];
    if (isLike) {
      setState(() => _isLiked = true);
      _likeController.forward().then((_) => _likeController.reverse());
      HapticFeedback.mediumImpact();
    }

    setState(() => _isSwiping = true);

    // Lưu hành động vào database
    final isMatch = await FirestoreService.recordSwipe(targetUid: target.uid, isLike: isLike);
    
    if (isMatch && mounted) {
      final matchId = ([_uid, target.uid]..sort()).join('_');
      MatchPopup.show(context, matchedUser: target, matchId: matchId, currentUserName: 'Bạn');
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        _currentIndex++;
        _isSwiping = false;
        _isLiked = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_profiles.isEmpty || _currentIndex >= _profiles.length) return _buildEmptyState();

    final user = _profiles[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F0F2),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: GestureDetector(
                onTap: () => Get.to(() => ProfileDetailScreen(user: user)),
                child: Stack(
                  children: [
                    _buildProfileCard(user),
                    _buildTopOverlay(user),
                  ],
                ),
              ),
            ),
          ),
          _buildActionButtons(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedPhotoWidget(uid: user.uid, photoUrl: user.photoUrl, fit: BoxFit.cover),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 25, left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('${user.name}, ${user.age}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    if (user.zodiac.isNotEmpty) Text(user.zodiac, style: const TextStyle(fontSize: 22)),
                  ]),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(user.city, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  ]),
                  const SizedBox(height: 12),
                  // Hiển thị sở thích
                  Wrap(spacing: 8, children: user.interests.take(3).map((i) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  )).toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOverlay(UserModel user) {
    return Positioned(
      top: 15, right: 15,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.3), shape: BoxShape.circle),
        child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút X (Dislike)
          _circleBtn(Icons.close_rounded, Colors.red, () => _handleSwipe(false)),
          
          // Nút Tim (Like) - Nâng cấp màu sắc
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _likeController, curve: Curves.elasticOut)),
            child: GestureDetector(
              onTap: () => _handleSwipe(true),
              child: Container(
                width: 75, height: 75,
                decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: (_isLiked ? Colors.pink : Colors.black).withValues(alpha: 0.1), blurRadius: 15)],
                ),
                child: Icon(
                  _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isLiked ? Colors.pink : Colors.black87, // Đen khi chưa tim, đỏ khi đã tim
                  size: 38,
                ),
              ),
            ),
          ),

          // Nút Star (Super Like)
          _circleBtn(Icons.star_rounded, Colors.blue, () {}),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('💫', style: TextStyle(fontSize: 60)),
      const SizedBox(height: 15),
      const Text('Hết người để quẹt rồi!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      TextButton(onPressed: _loadProfiles, child: const Text('Tải lại', style: TextStyle(color: AppColors.primary))),
    ]));
  }
}
