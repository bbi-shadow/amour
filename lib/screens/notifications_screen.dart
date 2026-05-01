import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../controllers/theme_controller.dart';
import '../models/notification_model.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationController());

    return Obx(() {
      final isDark = ThemeController.to.isDark;
      final bgColor = isDark ? AppColors.darkBg : const Color(0xFFF8F9FE);
      final textColor = isDark ? Colors.white : AppColors.lightText;

      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text('Thong bao', style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          elevation: 0,
          foregroundColor: textColor,
          actions: [
            TextButton(
              onPressed: controller.markAllAsRead,
              child: const Text('Doc tat ca', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        body: controller.isLoading.value
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : controller.notifications.isEmpty
                ? _buildEmpty(isDark)
                : _buildList(controller, isDark),
      );
    });
  }

  Widget _buildList(NotificationController controller, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: controller.notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final notif = controller.notifications[i];
        return _NotifTile(notif: notif, isDark: isDark);
      },
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text('Chua co thong bao', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final bool isDark;

  const _NotifTile({required this.notif, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(notif.type);
    final icon = _getTypeIcon(notif.type);

    return GestureDetector(
      onTap: () {
        NotificationController.to.markAsRead(notif.id);
        _handleNavigation(notif);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? (isDark ? AppColors.darkCard : Colors.white) : typeColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: notif.isRead ? Colors.transparent : typeColor.withOpacity(0.2)),
        ),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: notif.fromUserPhoto.isNotEmpty ? NetworkImage(notif.fromUserPhoto) : null,
            backgroundColor: typeColor.withOpacity(0.1),
            child: notif.fromUserPhoto.isEmpty ? Icon(icon, color: typeColor) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.title, style: TextStyle(fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(notif.body, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13)),
                const SizedBox(height: 4),
                Text(AppHelpers.timeAgo(notif.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  void _handleNavigation(NotificationModel notif) {
    switch (notif.type) {
      case NotificationType.message:
        final convId = notif.extra?['conversationId'] as String?;
        if (convId != null) {
          Get.toNamed(AppRoutes.chatDetail, arguments: {
            'conversationId': convId,
            'otherUserId': notif.fromUserId,
            'otherUserName': notif.title,
          });
        }
        break;
      default:
        Get.toNamed(AppRoutes.home);
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.match: return Colors.pink;
      case NotificationType.message: return Colors.blue;
      case NotificationType.like: return Colors.orange;
      default: return AppColors.primary;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.match: return Icons.favorite;
      case NotificationType.message: return Icons.chat_bubble_outline;
      case NotificationType.like: return Icons.thumb_up_outlined;
      default: return Icons.notifications;
    }
  }
}
