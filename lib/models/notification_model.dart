import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { match, message, like, super_like, visit, system }

class NotificationModel {
  final String id;
  final String userId;
  final String fromUserId;
  final String fromUserName;
  final String fromUserPhoto;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? extra;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserPhoto,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.extra,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      fromUserPhoto: data['fromUserPhoto'] ?? '',
      type: _parseType(data['type'] ?? ''),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      extra: data['extra'] as Map<String, dynamic>?,
    );
  }

  static NotificationType _parseType(String type) {
    switch (type) {
      case 'match': return NotificationType.match;
      case 'message': return NotificationType.message;
      case 'like': return NotificationType.like;
      case 'super_like': return NotificationType.super_like;
      case 'visit': return NotificationType.visit;
      default: return NotificationType.system;
    }
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'fromUserId': fromUserId,
    'fromUserName': fromUserName,
    'fromUserPhoto': fromUserPhoto,
    'type': type.name,
    'title': title,
    'body': body,
    'isRead': isRead,
    'createdAt': Timestamp.fromDate(createdAt),
    'extra': extra,
  };
}
