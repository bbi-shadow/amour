import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';

/// ══════════════════════════════════════════════════════════════
/// NotificationsScreen — Danh sách thông báo
/// ══════════════════════════════════════════════════════════════
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F9),
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.lightText,
        actions: [
          TextButton(
            onPressed: () => _markAllRead(),
            child: const Text('Đọc tất cả',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return _buildEmpty();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final notif = NotificationModel.fromFirestore(docs[i]);
              return _NotifTile(notif: notif);
            },
          );
        },
      ),
    );
  }

  Future<void> _markAllRead() async {
    // TODO: batch update all isRead = true
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🔔', style: TextStyle(fontSize: 56)),
          SizedBox(height: 16),
          Text('Chưa có thông báo', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.lightText)),
          SizedBox(height: 8),
          Text('Khi có match hoặc tin nhắn mới,\nbạn sẽ thấy ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.lightSubtext, fontSize: 14)),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  const _NotifTile({required this.notif});

  Color get _typeColor {
    switch (notif.type) {
      case NotificationType.match: return const Color(0xFFFF4B6E);
      case NotificationType.message: return const Color(0xFF667EEA);
      case NotificationType.like: return const Color(0xFFFF6B35);
      case NotificationType.superLike: return const Color(0xFF00BCD4);
      case NotificationType.visit: return const Color(0xFF9B59B6);
      default: return Colors.grey;
    }
  }

  String get _typeEmoji {
    switch (notif.type) {
      case NotificationType.match: return '💕';
      case NotificationType.message: return '💬';
      case NotificationType.like: return '❤️';
      case NotificationType.superLike: return '⭐';
      case NotificationType.visit: return '👀';
      default: return '🔔';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FirestoreService.markNotificationRead(notif.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : _typeColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead ? Colors.grey.shade100 : _typeColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(children: [
          // Avatar
          Stack(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: notif.fromUserPhoto.isNotEmpty
                    ? DecorationImage(image: NetworkImage(notif.fromUserPhoto), fit: BoxFit.cover)
                    : null,
                color: notif.fromUserPhoto.isEmpty ? _typeColor.withOpacity(0.15) : null,
              ),
              child: notif.fromUserPhoto.isEmpty
                  ? Center(child: Text(_typeEmoji, style: const TextStyle(fontSize: 24)))
                  : null,
            ),
            Positioned(bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: _typeColor, shape: BoxShape.circle),
                child: Text(_typeEmoji, style: const TextStyle(fontSize: 10)),
              ),
            ),
          ]),
          const SizedBox(width: 12),

          // Content
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(notif.title, style: TextStyle(
                  fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.lightText,
                ))),
                if (!notif.isRead)
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: _typeColor, shape: BoxShape.circle),
                  ),
              ]),
              const SizedBox(height: 4),
              Text(notif.body, style: const TextStyle(
                  color: AppColors.lightSubtext, fontSize: 13, height: 1.4)),
              const SizedBox(height: 4),
              Text(AppHelpers.timeAgo(notif.createdAt),
                  style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 11)),
            ],
          )),
        ]),
      ),
    );
  }
}
