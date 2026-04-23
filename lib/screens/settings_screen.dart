import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../controllers/auth_controller.dart';
import 'premium/premium_screen.dart';

/// ══════════════════════════════════════════════════════════════
/// SettingsScreen — Cài đặt ứng dụng đầy đủ
/// ══════════════════════════════════════════════════════════════
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  // Settings states
  bool _notifMatch = true;
  bool _notifMessage = true;
  bool _notifLike = true;
  bool _showOnline = true;
  bool _showDistance = true;
  bool _showAge = true;
  bool _darkMode = false;
  bool _vibration = true;
  int _searchRadius = 50;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(_uid).get();
      if (!doc.exists || !mounted) return;
      final d = doc.data()!;
      setState(() {
        _notifMatch = d['notifMatch'] != false;
        _notifMessage = d['notifMessage'] != false;
        _notifLike = d['notifLike'] != false;
        _showOnline = d['showOnline'] != false;
        _showDistance = d['showDistance'] != false;
        _showAge = d['showAge'] != false;
        _searchRadius = (d['searchRadius'] as num?)?.toInt() ?? 50;
        _vibration = d['vibration'] != false;
      });
    } catch (_) {}
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    setState(() {});
    await FirebaseFirestore.instance.collection('users').doc(_uid).update({key: value});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F9),
      appBar: AppBar(
        title: const Text('Cài đặt', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.lightText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPremiumBanner(),
            const SizedBox(height: 20),
            _buildSection('🔔 Thông báo', [
              _switchTile('Match mới', 'Khi có người phù hợp', _notifMatch,
                  (v) { setState(() => _notifMatch = v); _saveSetting('notifMatch', v); }),
              _switchTile('Tin nhắn', 'Khi có tin nhắn đến', _notifMessage,
                  (v) { setState(() => _notifMessage = v); _saveSetting('notifMessage', v); }),
              _switchTile('Lượt thích', 'Khi ai đó thích bạn', _notifLike,
                  (v) { setState(() => _notifLike = v); _saveSetting('notifLike', v); }),
              _switchTile('Rung', 'Rung khi có thông báo', _vibration,
                  (v) { setState(() => _vibration = v); _saveSetting('vibration', v); }),
            ]),
            const SizedBox(height: 16),
            _buildSection('🔍 Tìm kiếm', [
              _sliderTile('Khoảng cách tìm kiếm', '${_searchRadius}km',
                  _searchRadius.toDouble(), 1, 200, (v) {
                    setState(() => _searchRadius = v.round());
                    _saveSetting('searchRadius', _searchRadius);
                  }),
            ]),
            const SizedBox(height: 16),
            _buildSection('👁️ Quyền riêng tư', [
              _switchTile('Hiển thị trạng thái online', 'Mọi người thấy bạn đang online', _showOnline,
                  (v) { setState(() => _showOnline = v); _saveSetting('showOnline', v); }),
              _switchTile('Hiển thị khoảng cách', 'Cho thấy bạn ở gần họ bao xa', _showDistance,
                  (v) { setState(() => _showDistance = v); _saveSetting('showDistance', v); }),
              _switchTile('Hiển thị tuổi', 'Hiện tuổi trên hồ sơ', _showAge,
                  (v) { setState(() => _showAge = v); _saveSetting('showAge', v); }),
            ]),
            const SizedBox(height: 16),
            _buildSection('🎨 Giao diện', [
              _switchTile('Dark Mode', 'Chế độ tối', _darkMode,
                  (v) { setState(() => _darkMode = v); }),
            ]),
            const SizedBox(height: 16),
            _buildSection('⚠️ Tài khoản', [
              _actionTile('Thay đổi mật khẩu', Icons.lock_outline, Colors.blue,
                  () => _changePassword()),
              _actionTile('Xoá tài khoản', Icons.delete_outline, Colors.red,
                  () => _deleteAccount()),
            ]),
            const SizedBox(height: 16),
            _buildLogoutButton(),
            const SizedBox(height: 40),
            _buildVersionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () => Get.to(() => const PremiumScreen()),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          const Text('💎', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nâng cấp Premium', style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              Text('Mở khoá tất cả tính năng cao cấp',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Xem', style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title, style: const TextStyle(
              color: AppColors.lightSubtext, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(children: [
            ...children.asMap().entries.map((e) {
              final isLast = e.key == children.length - 1;
              return Column(children: [
                e.value,
                if (!isLast) const Divider(height: 1, indent: 56, endIndent: 16,
                    color: Color(0xFFF5F5F5)),
              ]);
            }),
          ]),
        ),
      ],
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.lightText)),
            Text(subtitle, style: const TextStyle(
                color: AppColors.lightSubtext, fontSize: 12)),
          ],
        )),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ]),
    );
  }

  Widget _sliderTile(String title, String valueText, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(title, style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.lightText)),
            const Spacer(),
            Text(valueText, style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w700)),
          ]),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: AppColors.primary,
              trackHeight: 4,
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: TextStyle(
          color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: color.withOpacity(0.5)),
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
          borderRadius: BorderRadius.circular(16),
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

  Widget _buildVersionInfo() {
    return Column(children: [
      Text('${AppConstants.appName} v${AppConstants.appVersion}',
          style: const TextStyle(color: AppColors.lightSubtext, fontSize: 13)),
      const SizedBox(height: 4),
      const Text('Made with ❤️ in Vietnam',
          style: TextStyle(color: AppColors.lightSubtext, fontSize: 12)),
    ]);
  }

  Future<void> _changePassword() async {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.isEmpty) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    AppHelpers.showSuccess('Đã gửi email đặt lại mật khẩu!');
  }

  Future<void> _deleteAccount() async {
    final confirmed = await AppHelpers.confirm(
      title: '⚠️ Xoá tài khoản',
      message: 'Hành động này không thể hoàn tác. Tất cả dữ liệu của bạn sẽ bị xoá vĩnh viễn!',
    );
    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      // Xoá Firestore data
      await FirebaseFirestore.instance.collection('users').doc(_uid).delete();
      // Xoá Firebase Auth
      await FirebaseAuth.instance.currentUser!.delete();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      AppHelpers.showError('Xoá tài khoản thất bại. Thử đăng nhập lại rồi thử lại!');
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
