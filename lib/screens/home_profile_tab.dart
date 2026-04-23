import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../services/firestore_service.dart';
import '../services/database_helper.dart';
import '../controllers/auth_controller.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import 'safety_screen.dart';
import 'help_screen.dart';
import 'premium/premium_screen.dart';
import 'notifications_screen.dart';

/// ══════════════════════════════════════════════════════════════
/// HomeProfileTab — Tab Hồ sơ trong HomeScreen
/// ══════════════════════════════════════════════════════════════
class HomeProfileTab extends StatefulWidget {
  const HomeProfileTab({super.key});
  @override
  State<HomeProfileTab> createState() => _HomeProfileTabState();
}

class _HomeProfileTabState extends State<HomeProfileTab> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  int _matchCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      // Try local SQLite first
      final local = await DatabaseHelper.getProfile(_uid);
      if (local != null && mounted) {
        _data = local;
        setState(() => _isLoading = false);
      }
      // Always fetch fresh from Firestore
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.colUsers).doc(_uid).get();
      if (doc.exists && mounted) {
        _data = doc.data();
        // Count matches
        final matchSnap = await FirebaseFirestore.instance
            .collection(AppConstants.colMatches)
            .where('users', arrayContains: _uid).get();
        _matchCount = matchSnap.docs.length;
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  _buildSliverHeader(),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildStatsRow(),
                        const SizedBox(height: 16),
                        if (!(_data?['isPremium'] == true))
                          _buildPremiumBanner(),
                        const SizedBox(height: 16),
                        _buildMenuSection(),
                        const SizedBox(height: 16),
                        _buildLogoutButton(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverHeader() {
    final name = _data?['name']?.toString() ?? '';
    final bio  = _data?['bio']?.toString() ?? '';
    final age  = _data?['age'];
    final city = _data?['city']?.toString() ?? '';
    final gender = _data?['gender']?.toString() ?? '';
    final photo = _data?['photoUrl']?.toString() ?? '';
    final photoPath = _data?['photo_path']?.toString() ?? '';
    final isPremium = _data?['isPremium'] == true;
    final premiumPlan = _data?['premiumPlan']?.toString() ?? 'free';
    final isVerified = _data?['isVerified'] == true;

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.gradientRomantic,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(children: [
              // Top actions
              Row(children: [
                const Text('Amour', style: TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.to(() => const NotificationsScreen()),
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 26),
                ),
                IconButton(
                  onPressed: () => Get.to(() => const SettingsScreen()),
                  icon: const Icon(Icons.settings_outlined,
                      color: Colors.white, size: 24),
                ),
              ]),
              const SizedBox(height: 12),

              // Avatar
              Stack(alignment: Alignment.bottomRight, children: [
                GestureDetector(
                  onTap: () async {
                    await Get.to(() => const EditProfileScreen());
                    _load();
                  },
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: ClipOval(child: _buildAvatarImage(photo, photoPath)),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await Get.to(() => const EditProfileScreen());
                    _load();
                  },
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: AppColors.primary, size: 16),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              // Name row
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(name.isNotEmpty ? name : 'Chưa có tên',
                    style: const TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                if (isVerified) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 13),
                  ),
                ],
                if (isPremium) ...[
                  const SizedBox(width: 6),
                  const Text('💎', style: TextStyle(fontSize: 16)),
                ],
              ]),
              const SizedBox(height: 6),

              // Info chips
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8, runSpacing: 6,
                children: [
                  if (age != null && (age as num) > 0)
                    _chip('$age tuổi', Icons.cake_rounded),
                  if (gender.isNotEmpty)
                    _chip(gender, gender == 'Nữ' ? Icons.female : Icons.male),
                  if (city.isNotEmpty)
                    _chip(city, Icons.location_on_rounded),
                ],
              ),

              if (bio.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(bio, textAlign: TextAlign.center, maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.85),
                        fontSize: 13, height: 1.4)),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 12),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildAvatarImage(String url, String localPath) {
    if (localPath.isNotEmpty) {
      final f = File(localPath);
      if (f.existsSync()) {
        return Image.file(f, fit: BoxFit.cover, width: 100, height: 100);
      }
    }
    if (url.isNotEmpty) {
      return Image.network(url, fit: BoxFit.cover, width: 100, height: 100,
          errorBuilder: (_, __, ___) => _avatarPlaceholder());
    }
    return _avatarPlaceholder();
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.2),
      child: const Icon(Icons.person_rounded, size: 60, color: Colors.white),
    );
  }

  Widget _buildStatsRow() {
    final likes = _data?['likeCount'] ?? 0;
    final superLikes = _data?['superLikeCount'] ?? 5;
    final boosts = _data?['boostCount'] ?? 0;

    return Row(children: [
      Expanded(child: _statCard('💕', '$_matchCount', 'Matches')),
      const SizedBox(width: 10),
      Expanded(child: _statCard('❤️', '$likes', 'Lượt thích')),
      const SizedBox(width: 10),
      Expanded(child: _statCard('⭐', '$superLikes', 'Super Like')),
      const SizedBox(width: 10),
      Expanded(child: _statCard('⚡', '$boosts', 'Boosts')),
    ]);
  }

  Widget _statCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(
            fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.lightText)),
        Text(label, style: const TextStyle(
            color: AppColors.lightSubtext, fontSize: 10)),
      ]),
    );
  }

  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () => Get.to(() => const PremiumScreen()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(children: [
          const Text('💎', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nâng cấp Premium', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              Text('Xem ai thích bạn & unlimited likes',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Xem', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ]),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(
      children: [
        _menuCard(
          icon: Icons.edit_rounded,
          title: 'Chỉnh sửa hồ sơ',
          subtitle: 'Cập nhật ảnh, bio, sở thích...',
          gradient: AppColors.gradientPink,
          onTap: () async {
            await Get.to(() => const EditProfileScreen());
            _load();
          },
        ),
        const SizedBox(height: 10),
        _menuCard(
          icon: Icons.notifications_rounded,
          title: 'Thông báo',
          subtitle: 'Xem match mới, tin nhắn...',
          gradient: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
          onTap: () => Get.to(() => const NotificationsScreen()),
        ),
        const SizedBox(height: 10),
        _menuCard(
          icon: Icons.settings_rounded,
          title: 'Cài đặt',
          subtitle: 'Thông báo, quyền riêng tư, tài khoản',
          gradient: [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
          onTap: () => Get.to(() => const SettingsScreen()),
        ),
        const SizedBox(height: 10),
        _menuCard(
          icon: Icons.shield_rounded,
          title: 'An toàn & Quyền riêng tư',
          subtitle: 'Block, báo cáo, xác minh tài khoản',
          gradient: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
          onTap: () => Get.to(() => const SafetyScreen()),
        ),
        const SizedBox(height: 10),
        _menuCard(
          icon: Icons.help_rounded,
          title: 'Trợ giúp & Phản hồi',
          subtitle: 'FAQ, liên hệ hỗ trợ',
          gradient: [const Color(0xFFF7971E), const Color(0xFFFFD200)],
          onTap: () => Get.to(() => const HelpScreen()),
        ),
      ],
    );
  }

  Widget _menuCard({
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient,
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15,
                  color: AppColors.lightText)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(
                  fontSize: 12, color: AppColors.lightSubtext)),
            ],
          )),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: Color(0xFFCCCCCC)),
        ]),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () => AuthController.to.logout(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.logout_rounded, color: AppColors.primary, size: 20),
          SizedBox(width: 8),
          Text('Đăng xuất', style: TextStyle(
              color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      ),
    );
  }
}
