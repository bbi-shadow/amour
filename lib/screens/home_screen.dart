import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'swipe_screen.dart';
import 'chat/chat_list_screen.dart';
import 'auth/login_screen.dart';
import 'edit_profile_screen.dart';
import '/services/database_helper.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    SwipeScreen(),
    ChatListScreen(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.favorite_rounded, Icons.favorite_outlined, 'Khám phá'),
              _navItem(1, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Tin nhắn'),
              _navItem(2, Icons.person_rounded, Icons.person_outline_rounded, 'Hồ sơ'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF4B6E).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? active : inactive,
              color: isSelected ? const Color(0xFFFF4B6E) : Colors.grey[400],
              size: 26,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? const Color(0xFFFF4B6E) : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
//  PROFILE TAB
// ══════════════════════════════════════════════
class ProfileTab extends StatefulWidget {
  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _user = FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _profileData;
  int _matchCount = 0;
  int _likeCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadProfile(), _loadStats()]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadProfile() async {
    try {
      final local = await DatabaseHelper.getProfile(_user!.uid);
      if (local != null) {
        _profileData = local;
      } else {
        final doc = await _firestore.collection('users').doc(_user.uid).get();
        if (doc.exists) _profileData = doc.data();
      }
    } catch (_) {}
  }

  Future<void> _loadStats() async {
    try {
      final matchSnap = await _firestore
          .collection('matches')
          .where('users', arrayContains: _user!.uid)
          .get();
      _matchCount = matchSnap.docs.length;

      final likeSnap = await _firestore
          .collection('likes')
          .doc(_user.uid)
          .collection('liked')
          .get();
      _likeCount = likeSnap.docs.length;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final name = _profileData?['name'] ?? '';
    final bio = _profileData?['bio'] ?? '';
    final age = _profileData?['age'];
    final city = _profileData?['city'] ?? '';
    final gender = _profileData?['gender'] ?? '';
    final photoPath = _profileData?['photo_path'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F0F2),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF4B6E)))
          : RefreshIndicator(
        color: const Color(0xFFFF4B6E),
        onRefresh: _loadAll,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Hero Header ──────────────────────
            SliverToBoxAdapter(
              child: _buildHeroHeader(
                  name, bio, age, city, gender, photoPath),
            ),
            // ── Stats ────────────────────────────
            SliverToBoxAdapter(
              child: _buildStats(),
            ),
            // ── Menu ─────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildMenuCard(
                    icon: Icons.edit_rounded,
                    title: 'Chỉnh sửa hồ sơ',
                    subtitle: 'Cập nhật ảnh, tuổi, bio...',
                    gradient: const [Color(0xFFFF4B6E), Color(0xFFFF8E53)],
                    onTap: () async {
                      await Get.to(() => EditProfileScreen());
                      _loadAll();
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildMenuCard(
                    icon: Icons.settings_rounded,
                    title: 'Cài đặt',
                    subtitle: 'Thông báo, quyền riêng tư...',
                    gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                    onTap: () => Get.snackbar('Sắp ra mắt', '🚧 Đang phát triển',
                        backgroundColor:
                        const Color(0xFF667EEA).withOpacity(0.9),
                        colorText: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  _buildMenuCard(
                    icon: Icons.shield_rounded,
                    title: 'An toàn & Quyền riêng tư',
                    subtitle: 'Block, báo cáo, xác minh',
                    gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                    onTap: () => Get.snackbar('Sắp ra mắt', '🚧 Đang phát triển',
                        backgroundColor:
                        const Color(0xFF11998E).withOpacity(0.9),
                        colorText: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  _buildMenuCard(
                    icon: Icons.help_rounded,
                    title: 'Trợ giúp & Phản hồi',
                    subtitle: 'FAQ, liên hệ hỗ trợ',
                    gradient: const [Color(0xFFF7971E), Color(0xFFFFD200)],
                    onTap: () => Get.snackbar('Sắp ra mắt', '🚧 Đang phát triển',
                        backgroundColor:
                        const Color(0xFFF7971E).withOpacity(0.9),
                        colorText: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  _buildLogoutButton(),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero Header ─────────────────────────────
  Widget _buildHeroHeader(String name, String bio, dynamic age,
      String city, String gender, String photoPath) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background gradient
        Container(
          height: 260,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF4B6E), Color(0xFFFF8E9B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Content
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
            child: Column(
              children: [
                // Avatar + edit button
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(child: _buildAvatar(photoPath)),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await Get.to(() => EditProfileScreen());
                        _loadAll();
                      },
                      child: Container(
                        width: 30, height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.edit_rounded,
                            color: Color(0xFFFF4B6E), size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Name
                Text(
                  name.isNotEmpty ? name : (_user?.email ?? 'Chưa có tên'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                // Tags: tuổi, giới tính, thành phố
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    if (age != null && age > 0)
                      _chip('$age tuổi', Icons.cake_rounded),
                    if (gender.isNotEmpty)
                      _chip(gender,
                          gender == 'Nữ' ? Icons.female : Icons.male),
                    if (city.isNotEmpty)
                      _chip(city, Icons.location_on_rounded),
                  ],
                ),
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Stats ─────────────────────────────────
  Widget _buildStats() {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                  child: _statItem(_matchCount.toString(), 'Match', '💕')),
              _divider(),
              Expanded(
                  child: _statItem(_likeCount.toString(), 'Đã thích', '❤️')),
              _divider(),

            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() => Container(
      width: 1, height: 40, color: Colors.grey.withOpacity(0.15));

  Widget _statItem(String value, String label, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFF4B6E))),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ── Menu Card ─────────────────────────────
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF222222))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500])),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 15, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }

  // ── Logout ────────────────────────────────
  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        await DatabaseHelper.deleteProfile(_user!.uid);
        await FirebaseAuth.instance.signOut();
        Get.offAll(() => LoginScreen());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF4B6E).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFFF4B6E), size: 20),
            SizedBox(width: 8),
            Text(
              'Đăng xuất',
              style: TextStyle(
                color: Color(0xFFFF4B6E),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar ────────────────────────────────
  Widget _buildAvatar(String photoPath) {
    if (photoPath.isNotEmpty) {
      final f = File(photoPath);
      if (f.existsSync()) {
        return Image.file(f, fit: BoxFit.cover);
      }
    }
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: const Icon(Icons.person_rounded, size: 60, color: Colors.white),
    );
  }
}

// ignore: non_constant_identifier_names
Widget _statItem(String value, String label, String emoji) {
  return Column(
    children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFF4B6E))),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500)),
    ],
  );
}