import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../controllers/profile_controller.dart';
import '../controllers/theme_controller.dart';
import '../widgets/cached_photo_widget.dart';
import 'edit_profile_screen.dart';
import 'safety_screen.dart';
import 'help_screen.dart';
import 'premium/premium_screen.dart';
import 'notifications_screen.dart';

// ══════════════════════════════════════════════════════════════
// HomeProfileTab - VIEW (MVC)
// ══════════════════════════════════════════════════════════════
class HomeProfileTab extends StatefulWidget {
  const HomeProfileTab({super.key});
  @override
  State<HomeProfileTab> createState() => _HomeProfileTabState();
}

class _HomeProfileTabState extends State<HomeProfileTab> with SingleTickerProviderStateMixin {
  final controller = Get.put(ProfileController());
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _openSettings(bool isDark) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _FullSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.to.isDark;
      final bg = isDark ? AppColors.darkBg : const Color(0xFFF2F2F7);

      if (controller.isLoading.value && controller.userData.isEmpty) {
        return Scaffold(
          backgroundColor: bg,
          body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      }

      return Scaffold(
        backgroundColor: bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.refreshAll,
            child: CustomScrollView(slivers: [
              _buildHeader(isDark),
              _buildBody(isDark),
            ]),
          ),
        ),
      );
    });
  }

  Widget _buildHeader(bool isDark) {
    final user = controller.userData;
    final name = user['name']?.toString() ?? 'Người dùng';
    final photo = user['photoUrl']?.toString() ?? '';
    final isPremium = user['isPremium'] == true;
    final isVerified = user['isVerified'] == true;
    final age = user['age'];
    final gender = user['gender']?.toString() ?? '';
    final city = user['city']?.toString() ?? '';

    return SliverToBoxAdapter(
      child: Column(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF7C3AED)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(children: [
                Row(children: [
                  RichText(text: const TextSpan(children: [
                    TextSpan(text: 'A', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    TextSpan(text: 'mour', style: TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.w900)),
                  ])),
                  const Spacer(),
                  _hBtn(Icons.notifications_outlined, () => Get.to(() => const NotificationsScreen())),
                  const SizedBox(width: 8),
                  _hBtn(Icons.settings_outlined, () => _openSettings(isDark)),
                ]),
                const SizedBox(height: 20),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Stack(alignment: Alignment.bottomRight, children: [
                    GestureDetector(
                      onTap: () => Get.to(() => const EditProfileScreen()),
                      child: Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 6))],
                        ),
                        child: ClipOval(child: photo.isNotEmpty 
                          ? CachedPhotoWidget(uid: controller.uid, photoUrl: photo) 
                          : Container(color: Colors.white24, child: const Icon(Icons.person, size: 50, color: Colors.white))),
                      ),
                    ),
                    const CircleAvatar(radius: 13, backgroundColor: Colors.white, child: Icon(Icons.edit_rounded, color: AppColors.primary, size: 14)),
                  ]),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
                      if (isVerified) const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.verified, color: Colors.blue, size: 18)),
                      if (isPremium) const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.workspace_premium, color: Colors.amber, size: 18)),
                    ]),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      if (age != null && (age as num) > 0) _chip('$age tuổi', Icons.cake_outlined),
                      if (gender.isNotEmpty) _chip(gender, gender == 'Nữ' ? Icons.female : Icons.male),
                      if (city.isNotEmpty) _chip(city, Icons.location_on_outlined),
                    ]),
                  ])),
                ]),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.2))),
                  child: Row(children: [
                    _statItem(Icons.favorite_outline_rounded, '${controller.matchCount.value}', 'Matches'),
                    _vDivider(),
                    _statItem(Icons.thumb_up_outlined, '${user['likeCount'] ?? 0}', 'Yêu thích'),
                    _vDivider(),
                    _statItem(Icons.star_outline_rounded, '${user['superLikeCount'] ?? 0}', 'Super Like'),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!isPremium) _buildPremiumBanner(),
      ]),
    );
  }

  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () => Get.to(() => const PremiumScreen()),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]), borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nâng cấp Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            Text('Xem ai thích bạn và lượt thích vô hạn', style: TextStyle(color: Colors.white54, fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]), borderRadius: BorderRadius.circular(16)),
            child: const Text('Xem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    final sc = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildSettingsCard(isDark),
          const SizedBox(height: 20),
          _sectionLabel('BÀI ĐĂNG CỦA TÔI', sc),
          const _MyPostsSection(),
          const SizedBox(height: 28),
          Center(child: Column(children: [
            Text('${AppConstants.appName} v${AppConstants.appVersion}', style: TextStyle(color: sc, fontSize: 12)),
            const SizedBox(height: 4),
            Text('Amour Team', style: TextStyle(color: sc, fontSize: 11)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark) {
    return GestureDetector(
      onTap: () => _openSettings(isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: const Color(0xFF4ECDC4).withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Row(children: [
          Icon(Icons.settings_rounded, color: Colors.white, size: 22),
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cài đặt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            Text('Thông báo, tìm kiếm, riêng tư...', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
        ]),
      ),
    );
  }

  Widget _hBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.18), border: Border.all(color: Colors.white.withOpacity(0.25))),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );

  Widget _chip(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 11), const SizedBox(width: 3),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _statItem(IconData icon, String value, String label) => Expanded(
    child: Column(children: [
      Icon(icon, color: Colors.white, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
    ]),
  );

  Widget _vDivider() => Container(width: 1, height: 36, color: Colors.white.withOpacity(0.25));

  Widget _sectionLabel(String t, Color sc) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 2),
    child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sc, letterSpacing: 0.8)),
  );
}

// ══════════════════════════════════════════════════════════════
// MyPostsSection
// ══════════════════════════════════════════════════════════════
class _MyPostsSection extends StatelessWidget {
  const _MyPostsSection();
  @override
  Widget build(BuildContext context) {
    final controller = ProfileController.to;
    return Obx(() {
      if (controller.myPosts.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: const Center(child: Text('Chưa có bài đăng nào.', style: TextStyle(color: Colors.grey))),
        );
      }
      return Column(children: controller.myPosts.map((post) => _MyPostCard(post: post)).toList());
    });
  }
}

class _MyPostCard extends StatefulWidget {
  final PostModel post;
  const _MyPostCard({required this.post});
  @override
  State<_MyPostCard> createState() => _MyPostCardState();
}

class _MyPostCardState extends State<_MyPostCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final controller = ProfileController.to;
    final isDark = ThemeController.to.isDark;
    final tc = isDark ? AppColors.darkText : AppColors.lightText;
    final sc = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final isLiked = widget.post.likes.contains(controller.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(
          leading: CircleAvatar(backgroundImage: controller.userData['photoUrl']?.toString().isNotEmpty == true ? NetworkImage(controller.userData['photoUrl']) : null),
          title: Text(controller.userData['name'] ?? 'Bạn', style: TextStyle(fontWeight: FontWeight.w700, color: tc)),
          subtitle: Text(AppHelpers.timeAgo(widget.post.createdAt), style: TextStyle(fontSize: 11, color: sc)),
          trailing: IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _confirmDelete(context, widget.post.id)),
        ),
        if (widget.post.content.isNotEmpty) 
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), 
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(widget.post.content, 
                maxLines: _expanded ? null : 4,
                overflow: _expanded ? null : TextOverflow.ellipsis,
                style: TextStyle(color: tc, fontSize: 14, height: 1.5)),
            ),
          ),
        if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty) 
          Image.network(widget.post.imageUrl!, width: double.infinity, fit: BoxFit.cover),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: [
            IconButton(icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : sc), onPressed: () => FirestoreService.toggleLikePost(widget.post, isLiked)),
            Text('${widget.post.likes.length}', style: TextStyle(color: sc)),
            const Spacer(),
            const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${widget.post.commentCount}', style: const TextStyle(color: Colors.grey)),
          ]),
        ),
      ]),
    );
  }

  void _confirmDelete(BuildContext context, String postId) async {
    final ok = await AppHelpers.confirm(title: 'Xoá bài đăng?', message: 'Hành động này không thể hoàn tác.');
    if (ok) ProfileController.to.deletePost(postId);
  }
}

// ══════════════════════════════════════════════════════════════
// FullSettingsSheet
// ══════════════════════════════════════════════════════════════
class _FullSettingsSheet extends StatefulWidget {
  const _FullSettingsSheet();
  @override
  State<_FullSettingsSheet> createState() => _FullSettingsSheetState();
}

class _FullSettingsSheetState extends State<_FullSettingsSheet> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final controller = ProfileController.to;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.settings.value;
      final isDark = ThemeController.to.isDark;
      final bg = isDark ? AppColors.darkBg : Colors.white;
      final tc = isDark ? AppColors.darkText : AppColors.lightText;
      final sc = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

      return DraggableScrollableSheet(
        initialChildSize: 0.92, maxChildSize: 0.97, minChildSize: 0.4,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: Column(children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('Cài đặt', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: tc)),
                const Spacer(),
                IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close_rounded)),
              ]),
            ),
            const SizedBox(height: 14),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: isDark ? AppColors.darkCard : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(14)),
              child: TabBar(
                controller: _tabCtrl, isScrollable: true, tabAlignment: TabAlignment.start,
                labelColor: Colors.white, unselectedLabelColor: sc,
                indicator: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF7C3AED)]), borderRadius: BorderRadius.circular(12)),
                tabs: const [
                  Tab(icon: Icon(Icons.person_outline, size: 18), text: 'Hồ sơ'),
                  Tab(icon: Icon(Icons.notifications_none, size: 18), text: 'Thông báo'),
                  Tab(icon: Icon(Icons.search, size: 18), text: 'Tìm kiếm'),
                  Tab(icon: Icon(Icons.visibility_off_outlined, size: 18), text: 'Riêng tư'),
                  Tab(icon: Icon(Icons.palette_outlined, size: 18), text: 'Giao diện'),
                  Tab(icon: Icon(Icons.account_box_outlined, size: 18), text: 'Tài khoản')
                ],
              ),
            ),
            Expanded(child: TabBarView(controller: _tabCtrl, children: [
              _tabProfile(isDark, tc, sc, scrollCtrl),
              _tabNotif(s, isDark, tc, sc, scrollCtrl),
              _tabSearch(s, isDark, tc, sc, scrollCtrl),
              _tabPrivacy(s, isDark, tc, sc, scrollCtrl),
              _tabTheme(isDark, tc, sc, scrollCtrl),
              _tabAccount(isDark, tc, sc, scrollCtrl),
            ])),
          ]),
        ),
      );
    });
  }

  Widget _tabProfile(bool d, Color tc, Color sc, ScrollController c) => ListView(controller: c, padding: const EdgeInsets.all(20), children: [
    _sec('Cá nhân', sc),
    _card(d, [
      _act(Icons.edit_rounded, 'Chỉnh sửa hồ sơ', 'Ảnh, bio, sở thích...', AppColors.primary, tc, sc, () => Get.to(() => const EditProfileScreen())),
      _act(Icons.workspace_premium_rounded, 'Premium', 'Mở khoá tính năng', Colors.amber, tc, sc, () => Get.to(() => const PremiumScreen())),
    ]),
  ]);

  Widget _tabNotif(dynamic s, bool d, Color tc, Color sc, ScrollController c) => ListView(controller: c, padding: const EdgeInsets.all(20), children: [
    _sec('Thông báo', sc),
    _card(d, [
      _sw('Match mới', 'Khi có người phù hợp', s.notifMatch, (v) => controller.updateSetting('notifMatch', v), tc, sc),
      _sw('Tin nhắn', 'Khi nhận tin nhắn mới', s.notifMessage, (v) => controller.updateSetting('notifMessage', v), tc, sc),
      _sw('Lượt thích', 'Khi ai đó thích bạn', s.notifLike, (v) => controller.updateSetting('notifLike', v), tc, sc),
    ]),
  ]);

  Widget _tabSearch(dynamic s, bool d, Color tc, Color sc, ScrollController c) => ListView(controller: c, padding: const EdgeInsets.all(20), children: [
    _sec('Khoảng cách', sc),
    _card(d, [
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(children: [Text('Bán kính', style: TextStyle(color: tc)), const Spacer(), Text('${s.searchRadius} km', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))]),
        Slider(value: s.searchRadius.toDouble(), min: 1, max: 200, activeColor: AppColors.primary, onChanged: (v) => controller.updateSetting('searchRadius', v.round())),
      ])),
    ]),
  ]);

  Widget _tabPrivacy(dynamic s, bool d, Color tc, Color sc, ScrollController c) => ListView(controller: c, padding: const EdgeInsets.all(20), children: [
    _sec('Hiển thị', sc),
    _card(d, [
      _sw('Trạng thái online', 'Hiển thị khi bạn hoạt động', s.showOnline, (v) => controller.updateSetting('showOnline', v), tc, sc),
      _sw('Hiển thị tuổi', 'Hiển thị tuổi trên hồ sơ', s.showAge, (v) => controller.updateSetting('showAge', v), tc, sc),
    ]),
  ]);

  Widget _tabTheme(bool d, Color tc, Color sc, ScrollController c) => ListView(controller: c, padding: const EdgeInsets.all(20), children: [
    _sec('Giao diện', sc),
    _card(d, [
      _sw(d ? 'Chế độ tối' : 'Chế độ sáng', 'Thay đổi màu sắc', d, (v) => ThemeController.to.setDark(v), tc, sc),
    ]),
  ]);

  Widget _tabAccount(bool d, Color tc, Color sc, ScrollController c) => ListView(controller: c, padding: const EdgeInsets.all(20), children: [
    _sec('Tài khoản', sc),
    _card(d, [
      _act(Icons.logout_rounded, 'Đăng xuất', 'Thoát khỏi ứng dụng', AppColors.primary, tc, sc, controller.logout),
      _act(Icons.delete_forever_rounded, 'Xoá tài khoản', 'Xoá vĩnh viễn dữ liệu', Colors.red, tc, sc, controller.deleteAccount),
    ]),
  ]);

  Widget _sec(String t, Color sc) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: Text(t.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sc, letterSpacing: 0.8)));
  Widget _card(bool d, List<Widget> ch) => Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: d ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]), child: Column(children: ch));
  Widget _sw(String t, String st, bool val, ValueChanged<bool> onChanged, Color tc, Color sc) => ListTile(title: Text(t, style: TextStyle(color: tc, fontSize: 14, fontWeight: FontWeight.w600)), subtitle: Text(st, style: TextStyle(color: sc, fontSize: 12)), trailing: Switch(value: val, activeColor: AppColors.primary, onChanged: onChanged));
  Widget _act(IconData i, String t, String st, Color c, Color tc, Color sc, VoidCallback onTap) => ListTile(leading: CircleAvatar(backgroundColor: c.withOpacity(0.1), child: Icon(i, color: c, size: 20)), title: Text(t, style: TextStyle(color: tc, fontSize: 14, fontWeight: FontWeight.w600)), subtitle: Text(st, style: TextStyle(color: sc, fontSize: 12)), trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14), onTap: onTap);
}
