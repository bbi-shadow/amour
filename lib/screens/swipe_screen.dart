import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/recommendation_service.dart';
import '../services/database_helper.dart';
import '../widgets/match_popup.dart';
import '../widgets/cached_photo_widget.dart'; // ✅ widget ảnh local cache
import 'profile_detail_screen.dart';

class SwipeScreen extends StatefulWidget {
  @override
  _SwipeScreenState createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with SingleTickerProviderStateMixin {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final _firestore = FirebaseFirestore.instance;

  List<UserModel> _profiles = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSwiping = false;
  String _rsMethod = '';

  String _currentUserName = 'Bạn';
  String? _currentUserPhotoUrl;

  bool _likePressed = false;
  bool _friendPressed = false;

  late AnimationController _animController;
  late Animation<Offset> _slideAnim;
  double _dragDx = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slideAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(2, 0))
        .animate(CurvedAnimation(
        parent: _animController, curve: Curves.easeOut));
    _loadProfiles();
    // Dọn cache ảnh cũ hơn 7 ngày khi khởi động
    DatabaseHelper.clearOldPhotoCache();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════
  //  LOAD PROFILES
  // ════════════════════════════════════════
  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final myDoc = await _firestore.collection('users').doc(_uid).get();
      final currentUser = UserModel.fromFirestore(myDoc);

      _currentUserName =
      currentUser.name.isNotEmpty ? currentUser.name : 'Bạn';
      _currentUserPhotoUrl =
      currentUser.photoUrl.isNotEmpty ? currentUser.photoUrl : null;

      final swipedSnap = await _firestore
          .collection('swipes').doc(_uid).collection('actions').get();
      final likedSnap = await _firestore
          .collection('likes').doc(_uid).collection('liked').get();
      final dislikedSnap = await _firestore
          .collection('dislikes').doc(_uid).collection('disliked').get();

      final swipedUids = <String>{
        ...swipedSnap.docs.map((d) => d.id),
        ...likedSnap.docs.map((d) => d.id),
        ...dislikedSnap.docs.map((d) => d.id),
        _uid,
      };

      final allSnap = await _firestore.collection('users').get();
      final candidates = allSnap.docs
          .where((d) => !swipedUids.contains(d.id))
          .map((d) {
        try {
          return UserModel.fromFirestore(d);
        } catch (_) {
          return null;
        }
      })
          .whereType<UserModel>()
          .toList();

      if (candidates.isEmpty) {
        setState(() { _profiles = []; _isLoading = false; });
        return;
      }

      final swipeCount = swipedSnap.docs.length;
      _rsMethod = swipeCount >= 10
          ? 'SVD'
          : swipeCount >= 3
          ? 'Collaborative'
          : 'Content-Based';

      final ranked = await RecommendationService.getRecommendations(
          currentUser, candidates);

      // Pre-cache ảnh 3 profile đầu tiên
      _preCachePhotos(ranked.take(3).toList());

      setState(() {
        _profiles = ranked;
        _currentIndex = 0;
        _likePressed = false;
        _friendPressed = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar('Lỗi', 'Không thể tải profiles: $e',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    }
  }

  /// Tải trước ảnh của các profile sắp tới vào local cache
  void _preCachePhotos(List<UserModel> profiles) {
    for (final p in profiles) {
      if (p.photoUrl.isNotEmpty) {
        DatabaseHelper.downloadAndCachePhoto(p.uid, p.photoUrl);
      }
    }
  }

  // ════════════════════════════════════════
  //  SWIPE
  // ════════════════════════════════════════
  Future<void> _handleSwipe(bool isLike) async {
    if (_currentIndex >= _profiles.length || _isSwiping) return;
    setState(() { _isSwiping = true; _dragDx = 0; });

    final target = _profiles[_currentIndex];

    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(isLike ? 2.5 : -2.5, -0.3),
    ).animate(CurvedAnimation(
        parent: _animController, curve: Curves.easeOut));

    await _animController.forward();
    _animController.reset();

    final isMatch = await RecommendationService.recordSwipe(
        targetUid: target.uid, isLike: isLike);

    if (isMatch && mounted) {
      final matchId = _generateMatchId(_uid, target.uid);
      await _ensureConversation(matchId, target);
      _showMatchPopup(target, matchId);
    }

    // Pre-cache ảnh profile tiếp theo
    final nextIdx = _currentIndex + 1;
    if (nextIdx < _profiles.length) {
      final next = _profiles[nextIdx];
      if (next.photoUrl.isNotEmpty) {
        DatabaseHelper.downloadAndCachePhoto(next.uid, next.photoUrl);
      }
    }

    if (mounted) {
      setState(() {
        _currentIndex++;
        _isSwiping = false;
        _likePressed = false;
        _friendPressed = false;
      });
    }
  }

  // ════════════════════════════════════════
  //  KẾT BẠN
  // ════════════════════════════════════════
  Future<void> _handleFriendRequest() async {
    if (_currentIndex >= _profiles.length || _isSwiping) return;
    final target = _profiles[_currentIndex];

    HapticFeedback.mediumImpact();
    setState(() => _friendPressed = true);

    try {
      final batch = _firestore.batch();
      batch.set(
        _firestore.collection('friend_requests')
            .doc(_uid).collection('sent').doc(target.uid),
        {'timestamp': FieldValue.serverTimestamp(), 'status': 'pending'},
      );
      batch.set(
        _firestore.collection('friend_requests')
            .doc(target.uid).collection('received').doc(_uid),
        {'timestamp': FieldValue.serverTimestamp(), 'status': 'pending'},
      );
      await batch.commit();

      final theirRequest = await _firestore
          .collection('friend_requests')
          .doc(target.uid).collection('sent').doc(_uid).get();

      if (theirRequest.exists && mounted) {
        final friendId = _generateMatchId(_uid, target.uid);
        await _firestore.collection('friends').doc(friendId).set({
          'users': [_uid, target.uid],
          'createdAt': FieldValue.serverTimestamp(),
        });
        _showFriendSuccessPopup(target);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Đã gửi lời kết bạn tới ${target.name}!'),
          ]),
          backgroundColor: const Color(0xFF5B86E5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (_) {
      if (mounted) setState(() => _friendPressed = false);
    }
  }

  void _showFriendSuccessPopup(UserModel other) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: const Color(0xFF5B86E5).withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🤝', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              const Text('Đã kết bạn thành công!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Bạn và ${other.name} đã là bạn bè!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _avatarWidget(_currentUserPhotoUrl, _currentUserName),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Icon(Icons.people_rounded,
                        color: Color(0xFF5B86E5), size: 30),
                  ),
                  _avatarWidget(
                      other.photoUrl.isNotEmpty ? other.photoUrl : null,
                      other.name),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B86E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Tuyệt vời!',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarWidget(String? photoUrl, String name) {
    return Column(
      children: [
        Container(
          width: 66, height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
                colors: [Color(0xFF5B86E5), Color(0xFF36D1DC)]),
            border: Border.all(color: const Color(0xFF5B86E5), width: 2.5),
          ),
          child: photoUrl != null && photoUrl.isNotEmpty
              ? ClipOval(
              child: Image.network(photoUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _initialsText(name, 20)))
              : _initialsText(name, 20),
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

  Widget _initialsText(String name, double size) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
            color: Colors.white, fontSize: size, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _generateMatchId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> _ensureConversation(String matchId, UserModel other) async {
    final convRef = _firestore.collection('conversations').doc(matchId);
    if (!(await convRef.get()).exists) {
      await convRef.set({
        'participants': [_uid, other.uid],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': '',
        'unreadCount': {_uid: 0, other.uid: 0},
      });
    }
  }

  void _showMatchPopup(UserModel matched, String matchId) {
    MatchPopup.show(
      context,
      matchedUser: matched,
      matchId: matchId,
      currentUserName: _currentUserName,
      currentUserPhotoUrl: _currentUserPhotoUrl,
    );
  }

  void _viewProfile(UserModel profile) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ProfileDetailScreen(user: profile)));
  }

  // ════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0F2),
      appBar: AppBar(
        title: Row(children: const [
          Icon(Icons.favorite_rounded, color: Color(0xFFFF4B6E), size: 22),
          SizedBox(width: 8),
          Text('Amour',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF4B6E),
                  fontSize: 20)),
        ]),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_rsMethod.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4B6E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(_rsMethod,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF4B6E),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.grey),
            onPressed: _loadProfiles,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _profiles.isEmpty || _currentIndex >= _profiles.length
          ? _buildEmpty()
          : _buildSwipeArea(),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(color: Color(0xFFFF4B6E)),
        const SizedBox(height: 16),
        Text('Đang tìm người phù hợp...',
            style: TextStyle(color: Colors.grey[600])),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('💫', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 16),
        const Text('Hết profiles rồi!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Quay lại sau để xem thêm',
            style: TextStyle(color: Colors.grey[500])),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _loadProfiles,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tải lại'),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B6E),
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20))),
        ),
      ]),
    );
  }

  Widget _buildSwipeArea() {
    final profile = _profiles[_currentIndex];
    final isLiking = _dragDx > 30;
    final isPassing = _dragDx < -30;

    return Column(children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: () => _viewProfile(profile),
            onPanUpdate: (d) {
              if (!_isSwiping) setState(() => _dragDx += d.delta.dx);
            },
            onPanEnd: (_) {
              if (_isSwiping) return;
              if (_dragDx > 80) {
                _handleSwipe(true);
              } else if (_dragDx < -80) {
                _handleSwipe(false);
              } else {
                setState(() => _dragDx = 0);
              }
            },
            child: SlideTransition(
              position: _slideAnim,
              child: Transform.rotate(
                angle: _dragDx / 800,
                child: Stack(children: [
                  _buildProfileCard(profile),
                  if (isLiking)
                    _buildOverlay(
                        'LIKE', const Color(0xFF4CAF50), Alignment.topLeft),
                  if (isPassing)
                    _buildOverlay(
                        'PASS', const Color(0xFFE53935), Alignment.topRight),
                ]),
              ),
            ),
          ),
        ),
      ),

      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text('Nhấn để xem hồ sơ chi tiết',
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ),

      // ── Buttons ──
      Padding(
        padding: const EdgeInsets.only(
            bottom: 32, top: 4, left: 40, right: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // X - Bỏ qua
            _actionButton(
              child: Icon(Icons.close_rounded,
                  color: Colors.red.shade400, size: 28),
              bg: Colors.white,
              shadow: Colors.red.shade100,
              size: 58,
              onTap: _isSwiping
                  ? null
                  : () {
                HapticFeedback.lightImpact();
                _handleSwipe(false);
              },
            ),

            // ❤️ Like (lớn giữa)
            GestureDetector(
              onTap: _isSwiping
                  ? null
                  : () async {
                HapticFeedback.mediumImpact();
                setState(() => _likePressed = true);
                await Future.delayed(
                    const Duration(milliseconds: 180));
                _handleSwipe(true);
              },
              child: AnimatedOpacity(
                opacity: _isSwiping ? 0.4 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: _likePressed ? 76 : 70,
                  height: _likePressed ? 76 : 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF2D55), Color(0xFFFF6B8A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF2D55).withOpacity(0.45),
                        blurRadius: _likePressed ? 24 : 16,
                        spreadRadius: _likePressed ? 3 : 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.favorite_rounded,
                      color: Colors.white, size: 32),
                ),
              ),
            ),

            // 👤 Kết bạn
            _actionButton(
              child: Icon(
                _friendPressed
                    ? Icons.people_rounded
                    : Icons.person_add_rounded,
                color: _friendPressed
                    ? Colors.white
                    : const Color(0xFF5B86E5),
                size: 26,
              ),
              bg: _friendPressed
                  ? const Color(0xFF5B86E5)
                  : Colors.white,
              shadow: const Color(0xFF5B86E5).withOpacity(0.3),
              size: 58,
              onTap: (_isSwiping || _friendPressed)
                  ? null
                  : _handleFriendRequest,
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _actionButton({
    required Widget child,
    required Color bg,
    required Color shadow,
    required double size,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bg,
            boxShadow: [
              BoxShadow(
                  color: shadow, blurRadius: 12, offset: const Offset(0, 4))
            ],
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  // ── Profile Card ─────────────────────────────
  Widget _buildProfileCard(UserModel profile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(fit: StackFit.expand, children: [
          // ✅ Dùng CachedPhotoWidget thay Image.network
          CachedPhotoWidget(
            uid: profile.uid,
            photoUrl: profile.photoUrl.isNotEmpty ? profile.photoUrl : null,
            fit: BoxFit.cover,
          ),

          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.72),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Info bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${profile.name}, ${profile.age}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                                color: Colors.black38,
                                blurRadius: 4,
                                offset: Offset(0, 1))
                          ])),
                  if (profile.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(profile.location,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ]),
                  ],
                  if (profile.bio.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(profile.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            height: 1.4)),
                  ],
                  if (profile.interests.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: profile.interests.take(4).map((tag) =>
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.5)),
                            ),
                            child: Text(tag,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Info icon
          Positioned(
            top: 12, right: 12,
            child: GestureDetector(
              onTap: () => _viewProfile(profile),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle),
                child: const Icon(Icons.info_outline_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildOverlay(String text, Color color, Alignment align) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color, width: 4),
        ),
        child: Align(
          alignment: align,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Transform.rotate(
              angle: align == Alignment.topLeft ? -0.4 : 0.4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    border: Border.all(color: color, width: 3),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(text,
                    style: TextStyle(
                        color: color,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}