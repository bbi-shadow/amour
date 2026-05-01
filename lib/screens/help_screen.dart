import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/help_controller.dart';
import '../controllers/theme_controller.dart';
import '../themes/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HelpController());
    final isDark = ThemeController.to.isDark;
    final bg = isDark ? AppColors.darkBg : const Color(0xFFF8F9FE);
    final textColor = isDark ? Colors.white : AppColors.lightText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Tro giup va Phan hoi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: _contactBtn(
              icon: Icons.email_outlined,
              label: 'Email ho tro',
              color: Colors.redAccent,
              onTap: controller.launchEmail,
            )),
            const SizedBox(width: 12),
            Expanded(child: _contactBtn(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat truc tiep',
              color: Colors.blueAccent,
              onTap: () {},
            )),
          ]),
          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text('CAU HOI THUONG GAP',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 1.1)),
          ),

          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Obx(() => Column(
              children: List.generate(controller.faqs.length, (i) {
                final faq = controller.faqs[i];
                final isOpen = controller.expandedIndices.contains(i);
                final isLast = i == controller.faqs.length - 1;
                
                return Column(
                  children: [
                    ListTile(
                      onTap: () => controller.toggleExpanded(i),
                      title: Text(faq.question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      trailing: Icon(isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 20),
                    ),
                    if (isOpen)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(faq.answer, style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 13, height: 1.5)),
                      ),
                    if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: isDark ? Colors.white10 : Colors.grey.shade100),
                  ],
                );
              }),
            )),
          ),
          
          const SizedBox(height: 48),
          Center(child: Text('Amour v1.0.0', style: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : Colors.grey))),
        ],
      ),
    );
  }

  Widget _contactBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
