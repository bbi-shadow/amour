import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════════════════════
// MatchModel
// ══════════════════════════════════════════════════════════════
class MatchModel {
  final String id;
  final List<String> users;
  final DateTime? createdAt;
  final bool isActive;

  MatchModel({
    required this.id,
    required this.users,
    this.createdAt,
    this.isActive = true,
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return MatchModel(
      id: doc.id,
      users: List<String>.from(d['users'] ?? []),
      createdAt: d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : null,
      isActive: d['isActive'] != false,
    );
  }

  Map<String, dynamic> toMap() => {
    'users': users,
    'createdAt': FieldValue.serverTimestamp(),
    'isActive': isActive,
  };
}

// ══════════════════════════════════════════════════════════════
// NotificationModel
// ══════════════════════════════════════════════════════════════
enum NotificationType { match, message, like, superLike, visit, system }

class NotificationModel {
  final String id;
  final String userId;         // Người nhận
  final String fromUserId;
  final String fromUserName;
  final String fromUserPhoto;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;
  final String? targetId;      // matchId / conversationId / etc.

  NotificationModel({
    required this.id,
    required this.userId,
    required this.fromUserId,
    this.fromUserName = '',
    this.fromUserPhoto = '',
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    this.createdAt,
    this.targetId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return NotificationModel(
      id: doc.id,
      userId: d['userId']?.toString() ?? '',
      fromUserId: d['fromUserId']?.toString() ?? '',
      fromUserName: d['fromUserName']?.toString() ?? '',
      fromUserPhoto: d['fromUserPhoto']?.toString() ?? '',
      type: _parseType(d['type']),
      title: d['title']?.toString() ?? '',
      body: d['body']?.toString() ?? '',
      isRead: d['isRead'] == true,
      createdAt: d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : null,
      targetId: d['targetId']?.toString(),
    );
  }

  static NotificationType _parseType(dynamic raw) {
    switch (raw?.toString()) {
      case 'match': return NotificationType.match;
      case 'message': return NotificationType.message;
      case 'like': return NotificationType.like;
      case 'superLike': return NotificationType.superLike;
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
    'createdAt': FieldValue.serverTimestamp(),
    'targetId': targetId,
  };
}

// ══════════════════════════════════════════════════════════════
// ReportModel
// ══════════════════════════════════════════════════════════════
class ReportModel {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String description;
  final String status;         // 'pending' | 'reviewed' | 'resolved'
  final DateTime? createdAt;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.description = '',
    this.status = 'pending',
    this.createdAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return ReportModel(
      id: doc.id,
      reporterId: d['reporterId']?.toString() ?? '',
      reportedUserId: d['reportedUserId']?.toString() ?? '',
      reason: d['reason']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      status: d['status']?.toString() ?? 'pending',
      createdAt: d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'reporterId': reporterId,
    'reportedUserId': reportedUserId,
    'reason': reason,
    'description': description,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
  };
}

// ══════════════════════════════════════════════════════════════
// SubscriptionModel
// ══════════════════════════════════════════════════════════════
class SubscriptionModel {
  final String id;
  final String userId;
  final String plan;           // 'basic' | 'gold' | 'platinum'
  final double price;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final String paymentMethod;
  final String status;         // 'active' | 'expired' | 'cancelled'

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.plan,
    required this.price,
    this.currency = 'VND',
    required this.startDate,
    required this.endDate,
    this.paymentMethod = '',
    this.status = 'active',
  });

  bool get isActive => status == 'active' && endDate.isAfter(DateTime.now());

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return SubscriptionModel(
      id: doc.id,
      userId: d['userId']?.toString() ?? '',
      plan: d['plan']?.toString() ?? 'basic',
      price: (d['price'] as num?)?.toDouble() ?? 0,
      currency: d['currency']?.toString() ?? 'VND',
      startDate: d['startDate'] is Timestamp ? (d['startDate'] as Timestamp).toDate() : DateTime.now(),
      endDate: d['endDate'] is Timestamp ? (d['endDate'] as Timestamp).toDate() : DateTime.now(),
      paymentMethod: d['paymentMethod']?.toString() ?? '',
      status: d['status']?.toString() ?? 'active',
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CallModel — Lịch sử cuộc gọi
// ══════════════════════════════════════════════════════════════
enum CallType { video, voice }
enum CallStatus { calling, accepted, rejected, missed, ended }

class CallModel {
  final String id;
  final String callerId;
  final String receiverId;
  final CallType type;
  final CallStatus status;
  final int duration;          // giây
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String channelId;      // Agora channel

  CallModel({
    required this.id,
    required this.callerId,
    required this.receiverId,
    this.type = CallType.voice,
    this.status = CallStatus.calling,
    this.duration = 0,
    this.startedAt,
    this.endedAt,
    this.channelId = '',
  });

  factory CallModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return CallModel(
      id: doc.id,
      callerId: d['callerId']?.toString() ?? '',
      receiverId: d['receiverId']?.toString() ?? '',
      type: d['type'] == 'video' ? CallType.video : CallType.voice,
      status: _parseStatus(d['status']),
      duration: (d['duration'] as num?)?.toInt() ?? 0,
      startedAt: d['startedAt'] is Timestamp ? (d['startedAt'] as Timestamp).toDate() : null,
      endedAt: d['endedAt'] is Timestamp ? (d['endedAt'] as Timestamp).toDate() : null,
      channelId: d['channelId']?.toString() ?? '',
    );
  }

  static CallStatus _parseStatus(dynamic raw) {
    switch (raw?.toString()) {
      case 'accepted': return CallStatus.accepted;
      case 'rejected': return CallStatus.rejected;
      case 'missed': return CallStatus.missed;
      case 'ended': return CallStatus.ended;
      default: return CallStatus.calling;
    }
  }

  Map<String, dynamic> toMap() => {
    'callerId': callerId,
    'receiverId': receiverId,
    'type': type.name,
    'status': status.name,
    'duration': duration,
    'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : FieldValue.serverTimestamp(),
    'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
    'channelId': channelId,
  };
}
