import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/safety_controller.dart';
import '../controllers/theme_controller.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SafetyController());
    final isDark = ThemeController.to.isDark;
    final bg = isDark ? AppColors.darkBg : const Color(0xFFF8F9FE);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('An toan va Rieng tu', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(isDark, [
            _buildItem(
              context,
              icon: Icons.block_outlined,
              color: Colors.red,
              title: 'Danh sach da chan',
              subtitle: 'Quan ly nguoi dung bi chan',
              onTap: () => Get.to(() => const BlockedListScreen()),
            ),
            _buildItem(
              context,
              icon: Icons.flag_outlined,
              color: Colors.orange,
              title: 'Bao cao nguoi dung',
              subtitle: 'Bao cao hanh vi khong phu hop',
              isLast: true,
              onTap: () => _showReportSheet(context, controller),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection(isDark, [
            _buildItem(
              context,
              icon: Icons.verified_user_outlined,
              color: Colors.green,
              title: 'Xac minh tai khoan',
              subtitle: 'Tang do tin cay cho ho so',
              onTap: () {},
            ),
            _buildItem(
              context,
              icon: Icons.lock_outline,
              color: Colors.blue,
              title: 'Mat khau',
              subtitle: 'Cap nhat bao mat tai khoan',
              isLast: true,
              onTap: () {},
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildItem(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      shape: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.05))),
    );
  }

  void _showReportSheet(BuildContext context, SafetyController controller) {
    final reasons = ['Noi dung khong phu hop', 'Spam', 'Gia mao', 'Quay roi', 'Khac'];
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ly do bao cao', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...reasons.map((r) => ListTile(
              title: Text(r),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Get.back();
                controller.sendReport(r);
              },
            )),
          ],
        ),
      ),
    );
  }
}

class BlockedListScreen extends StatelessWidget {
  const BlockedListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SafetyController.to;
    final isDark = ThemeController.to.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F9FE),
      appBar: AppBar(title: const Text('Nguoi dung da chan')),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (controller.blockedUids.isEmpty) return const Center(child: Text('Chua chan ai', style: TextStyle(color: Colors.grey)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.blockedUids.length,
          itemBuilder: (ctx, i) {
            final uid = controller.blockedUids[i];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
              builder: (ctx2, snap) {
                if (!snap.hasData) return const SizedBox.shrink();
                final data = snap.data!.data() as Map<String, dynamic>?;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(backgroundImage: data?['photoUrl']?.isNotEmpty == true ? NetworkImage(data!['photoUrl']) : null),
                    title: Text(data?['name'] ?? 'User'),
                    trailing: TextButton(
                      onPressed: () => controller.unblockUser(uid),
                      child: const Text('Bo chan'),
                    ),
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }
}
