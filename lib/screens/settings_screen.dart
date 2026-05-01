import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../controllers/profile_controller.dart';
import '../controllers/theme_controller.dart';
import 'premium/premium_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ProfileController.to;
    final isDark = ThemeController.to.isDark;
    final bg = isDark ? AppColors.darkBg : const Color(0xFFF8F9FE);
    final textColor = isDark ? Colors.white : AppColors.lightText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Cai dat', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final s = controller.settings.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildPremiumBanner(),
              const SizedBox(height: 24),
              
              _buildSection('Thong bao', isDark, [
                _switchTile('Match moi', 'Khi co nguoi phu hop', s.notifMatch, 
                    (v) => controller.updateSetting('notifMatch', v)),
                _switchTile('Tin nhan', 'Khi co tin nhan den', s.notifMessage, 
                    (v) => controller.updateSetting('notifMessage', v)),
                _switchTile('Luot thich', 'Khi ai do thich ban', s.notifLike, 
                    (v) => controller.updateSetting('notifLike', v)),
              ]),

              const SizedBox(height: 16),
              _buildSection('Tim kiem', isDark, [
                _sliderTile('Khoang cach tim kiem', '${s.searchRadius}km', 
                    s.searchRadius.toDouble(), 1, 200, 
                    (v) => controller.updateSetting('searchRadius', v.round())),
              ]),

              const SizedBox(height: 16),
              _buildSection('Quyen rieng tu', isDark, [
                _switchTile('Hien thi trang thai online', 'Moi nguoi thay ban dang hoat dong', s.showOnline, 
                    (v) => controller.updateSetting('showOnline', v)),
                _switchTile('Hien thi tuoi', 'Hien thi tuoi tren ho so', s.showAge, 
                    (v) => controller.updateSetting('showAge', v)),
              ]),

              const SizedBox(height: 16),
              _buildSection('Giao dien', isDark, [
                _switchTile(
                  'Che do toi',
                  isDark ? 'Dang bat che do toi' : 'Dang bat che do sang',
                  isDark,
                  (v) => ThemeController.to.setDark(v),
                ),
              ]),

              const SizedBox(height: 16),
              _buildSection('Tai khoan', isDark, [
                _actionTile('Xoa tai khoan', Icons.delete_outline, Colors.red, 
                    () => controller.deleteAccount()),
              ]),

              const SizedBox(height: 24),
              _buildLogoutButton(controller),
              const SizedBox(height: 40),
              _buildVersionInfo(isDark),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () => Get.to(() => const PremiumScreen()),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(children: [
          const Icon(Icons.workspace_premium, color: Colors.amber, size: 32),
          const SizedBox(width: 14),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amour Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Mo khoa tat ca tinh nang cao cap', style: TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          )),
          const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
        ]),
      ),
    );
  }

  Widget _buildSection(String title, bool isDark, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1.1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
    );
  }

  Widget _sliderTile(String title, String valueText, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            Text(valueText, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ]),
          Slider(value: value, min: min, max: max, activeColor: AppColors.primary, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _actionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
    );
  }

  Widget _buildLogoutButton(ProfileController controller) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: controller.logout,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Dang xuat', style: TextStyle(fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildVersionInfo(bool isDark) {
    return Center(
      child: Column(children: [
        Text('${AppConstants.appName} v${AppConstants.appVersion}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const Text('Amour Team', style: TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
    );
  }
}
