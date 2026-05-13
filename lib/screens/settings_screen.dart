import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/profile_controller.dart';
import '../controllers/theme_controller.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../widgets/cached_photo_widget.dart';
import 'edit_profile_screen.dart';
import 'premium/premium_screen.dart';
import 'notifications_screen.dart';
import 'safety_screen.dart';
import 'help_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController());

    return Obx(() {
      final isDark = ThemeController.to.isDark;
      final bg = isDark ? AppColors.darkBg : const Color(0xFFF2F2F7);
      final tc = isDark ? AppColors.darkText : AppColors.lightText;
      final sc = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

      if (controller.isLoading.value && controller.userData.isEmpty) {
        return Scaffold(
          backgroundColor: bg,
          body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        );
      }

      final user = controller.userData;
      final name = user['name']?.toString() ?? 'Người dùng';
      final photo = user['photoUrl']?.toString() ?? '';
      final isPremium = user['isPremium'] == true;
      final isVerified = user['isVerified'] == true;
      final age = user['age'];
      final city = user['city']?.toString() ?? '';

      return Scaffold(
        backgroundColor: bg,
        body: CustomScrollView(
          slivers: [
            // Header profile
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text('Cài đặt',
                                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                            const Spacer(),
                            _hBtn(Icons.notifications_outlined, () => Get.to(() => const NotificationsScreen())),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                GestureDetector(
                                  onTap: () => Get.to(() => const EditProfileScreen()),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
                                    ),
                                    child: ClipOval(
                                      child: photo.isNotEmpty
                                          ? CachedPhotoWidget(uid: controller.uid, photoUrl: photo)
                                          : Container(color: Colors.white24, child: const Icon(Icons.person, size: 44, color: Colors.white)),
                                    ),
                                  ),
                                ),
                                const CircleAvatar(radius: 12, backgroundColor: Colors.white, child: Icon(Icons.edit_rounded, color: AppColors.primary, size: 13)),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Flexible(child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
                                    if (isVerified) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified, color: Colors.blue, size: 18)),
                                    if (isPremium) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.workspace_premium, color: Colors.amber, size: 18)),
                                  ]),
                                  const SizedBox(height: 6),
                                  Wrap(spacing: 6, runSpacing: 4, children: [
                                    if (age != null && (age as num) > 0)
                                      _chip('$age tuổi', Icons.cake_outlined),
                                    if (city.isNotEmpty)
                                      _chip(city, Icons.location_on_outlined),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Stats row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(children: [
                            _statItem(Icons.favorite_outline_rounded, '${controller.matchCount.value}', 'Matches'),
                            _vDivider(),
                            _statItem(Icons.thumb_up_outlined, '${user['likeCount'] ?? 0}', 'Yêu thích'),
                            _vDivider(),
                            _statItem(Icons.star_outline_rounded, '${user['superLikeCount'] ?? 0}', 'Super Like'),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(child: const SizedBox(height: 16)),

            // Premium banner nếu chưa có
            if (!isPremium)
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: () => Get.to(() => const PremiumScreen()),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Nâng cấp Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                        Text('Xem ai thích bạn • Lượt thích vô hạn', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('Xem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ]),
                  ),
                ),
              ),

            // Settings sections
            SliverToBoxAdapter(
              child: Obx(() {
                final s = controller.settings.value;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TÀI KHOẢN
                      _sectionLabel('TÀI KHOẢN', sc),
                      _card(isDark, tc, sc, [
                        _actTile(Icons.edit_rounded, 'Chỉnh sửa hồ sơ', 'Ảnh, bio, sở thích...', AppColors.primary, tc, sc,
                                () => Get.to(() => const EditProfileScreen())),
                        _divider(isDark),
                        _actTile(Icons.workspace_premium_rounded, 'Premium', 'Mở khoá tính năng cao cấp', Colors.amber, tc, sc,
                                () => Get.to(() => const PremiumScreen())),
                      ]),
                      const SizedBox(height: 20),

                      // THÔNG BÁO
                      _sectionLabel('THÔNG BÁO', sc),
                      _card(isDark, tc, sc, [
                        _swTile('Match mới', 'Khi có người phù hợp', s.notifMatch,
                                (v) => controller.updateSetting('notifMatch', v), tc, sc),
                        _divider(isDark),
                        _swTile('Tin nhắn', 'Khi nhận tin nhắn mới', s.notifMessage,
                                (v) => controller.updateSetting('notifMessage', v), tc, sc),
                        _divider(isDark),
                        _swTile('Lượt thích', 'Khi ai đó thích bạn', s.notifLike,
                                (v) => controller.updateSetting('notifLike', v), tc, sc),
                      ]),
                      const SizedBox(height: 20),

                      // TÌM KIẾM
                      _sectionLabel('TÌM KIẾM', sc),
                      _card(isDark, tc, sc, [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            Row(children: [
                              Text('Bán kính tìm kiếm', style: TextStyle(color: tc, fontSize: 14, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text('${s.searchRadius} km', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ]),
                            Slider(
                              value: s.searchRadius.toDouble(),
                              min: 1, max: 200,
                              activeColor: AppColors.primary,
                              onChanged: (v) => controller.updateSetting('searchRadius', v.round()),
                            ),
                          ]),
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // QUYỀN RIÊNG TƯ
                      _sectionLabel('QUYỀN RIÊNG TƯ', sc),
                      _card(isDark, tc, sc, [
                        _swTile('Trạng thái online', 'Hiển thị khi bạn hoạt động', s.showOnline,
                                (v) => controller.updateSetting('showOnline', v), tc, sc),
                        _divider(isDark),
                        _swTile('Hiển thị tuổi', 'Hiển thị tuổi trên hồ sơ', s.showAge,
                                (v) => controller.updateSetting('showAge', v), tc, sc),
                      ]),
                      const SizedBox(height: 20),

                      // GIAO DIỆN
                      _sectionLabel('GIAO DIỆN', sc),
                      _card(isDark, tc, sc, [
                        _swTile(
                          isDark ? 'Chế độ tối' : 'Chế độ sáng',
                          'Thay đổi màu sắc ứng dụng',
                          isDark,
                              (v) => ThemeController.to.setDark(v),
                          tc, sc,
                        ),
                      ]),
                      const SizedBox(height: 20),

                      // HỖ TRỢ
                      _sectionLabel('HỖ TRỢ', sc),
                      _card(isDark, tc, sc, [
                        _actTile(Icons.security_rounded, 'An toàn', 'Quyền riêng tư & bảo mật', AppColors.primary, tc, sc,
                                () => Get.to(() => const SafetyScreen())),
                        _divider(isDark),
                        _actTile(Icons.help_outline_rounded, 'Trợ giúp', 'FAQ & liên hệ', const Color(0xFF3498DB), tc, sc,
                                () => Get.to(() => const HelpScreen())),
                      ]),
                      const SizedBox(height: 20),

                      // TÀI KHOẢN NGUY HIỂM
                      _sectionLabel('TÀI KHOẢN', sc),
                      _card(isDark, tc, sc, [
                        _actTile(Icons.logout_rounded, 'Đăng xuất', 'Thoát khỏi ứng dụng', AppColors.primary, tc, sc,
                            controller.logout),
                        _divider(isDark),
                        _actTile(Icons.delete_forever_rounded, 'Xoá tài khoản', 'Xoá vĩnh viễn tất cả dữ liệu', Colors.red, tc, sc,
                            controller.deleteAccount),
                      ]),
                      const SizedBox(height: 28),

                      Center(child: Column(children: [
                        Text('${AppConstants.appName} v${AppConstants.appVersion}',
                            style: TextStyle(color: sc, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('Amour Team', style: TextStyle(color: sc, fontSize: 11)),
                      ])),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }

  Widget _hBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.18),
          border: Border.all(color: Colors.white.withOpacity(0.25))),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );

  Widget _chip(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 11),
      const SizedBox(width: 3),
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
    padding: const EdgeInsets.only(left: 4, bottom: 10),
    child: Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sc, letterSpacing: 0.8)),
  );

  Widget _card(bool isDark, Color tc, Color sc, List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
    ),
    child: Column(children: children),
  );

  Widget _divider(bool isDark) => Divider(
    height: 1, indent: 56,
    color: isDark ? Colors.white10 : Colors.grey.shade100,
  );

  Widget _swTile(String t, String st, bool val, ValueChanged<bool> onChanged, Color tc, Color sc) => ListTile(
    title: Text(t, style: TextStyle(color: tc, fontSize: 14, fontWeight: FontWeight.w600)),
    subtitle: Text(st, style: TextStyle(color: sc, fontSize: 12)),
    trailing: Switch(value: val, activeColor: AppColors.primary, onChanged: onChanged),
  );

  Widget _actTile(IconData i, String t, String st, Color c, Color tc, Color sc, VoidCallback onTap) => ListTile(
    onTap: onTap,
    leading: CircleAvatar(
        radius: 18,
        backgroundColor: c.withOpacity(0.12),
        child: Icon(i, color: c, size: 18)),
    title: Text(t, style: TextStyle(color: tc, fontSize: 14, fontWeight: FontWeight.w600)),
    subtitle: Text(st, style: TextStyle(color: sc, fontSize: 12)),
    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: sc),
  );
}