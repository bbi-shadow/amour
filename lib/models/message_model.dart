import 'package:cloud_firestore/cloud_firestore.dart';

/// Loại tin nhắn
enum MessageType { text, image, emoji, sticker, voice, system, video_call, voice_call }

/// ══════════════════════════════════════════════════════════════════
/// MessageModel v2 — reactions, delivered, deletedFor, reply preview
/// ══════════════════════════════════════════════════════════════════
class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final MessageType type;
  final String? mediaUrl;

  // ── Status ─────────────────────────────────────────────────────
  final bool seen;
  final bool delivered;
  final DateTime? seenAt;
  final DateTime? timestamp;

  // ── Delete / Unsend ────────────────────────────────────────────
  final bool isDeleted;                       // Thu hồi (cả 2 bên thấy)
  final Map<String, bool> deletedFor;         // Chỉ ẩn phía mình

  // ── Reply ──────────────────────────────────────────────────────
  final String? replyToMessageId;
  final String? replyToText;
  final String? replyToSenderId;

  // ── Reactions ──────────────────────────────────────────────────
  /// reaction = { uid: emoji }  e.g. { 'uid123': '❤️', 'uid456': '👍' }
  final Map<String, String> reaction;

  // ── Call info ─────────────────────────────────────────────────
  final bool isCallMessage;
  final String? callStatus;
  final int? callDuration;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.type = MessageType.text,
    this.mediaUrl,
    this.seen = false,
    this.delivered = false,
    this.seenAt,
    this.timestamp,
    this.isDeleted = false,
    this.deletedFor = const {},
    this.replyToMessageId,
    this.replyToText,
    this.replyToSenderId,
    this.reaction = const {},
    this.isCallMessage = false,
    this.callStatus,
    this.callDuration,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return MessageModel(
      id: doc.id,
      conversationId: d['conversationId']?.toString() ?? '',
      senderId: d['senderId']?.toString() ?? '',
      text: d['text']?.toString() ?? '',
      type: _parseType(d['type']),
      mediaUrl: d['mediaUrl']?.toString(),
      seen: d['seen'] == true,
      delivered: d['delivered'] == true,
      seenAt: d['seenAt'] is Timestamp ? (d['seenAt'] as Timestamp).toDate() : null,
      timestamp: d['timestamp'] is Timestamp ? (d['timestamp'] as Timestamp).toDate() : null,
      isDeleted: d['isDeleted'] == true,
      deletedFor: Map<String, bool>.from(
        (d['deletedFor'] as Map?)?.map((k, v) => MapEntry(k.toString(), v == true)) ?? {},
      ),
      replyToMessageId: d['replyToMessageId']?.toString(),
      replyToText: d['replyToText']?.toString(),
      replyToSenderId: d['replyToSenderId']?.toString(),
      reaction: Map<String, String>.from(
        (d['reaction'] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString())) ?? {},
      ),
      isCallMessage: d['isCallMessage'] == true,
      callStatus: d['callStatus']?.toString(),
      callDuration: d['callDuration'] is num ? (d['callDuration'] as num).toInt() : null,
    );
  }

  static MessageType _parseType(dynamic raw) {
    switch (raw?.toString()) {
      case 'image': return MessageType.image;
      case 'emoji': return MessageType.emoji;
      case 'sticker': return MessageType.sticker;
      case 'voice': return MessageType.voice;
      case 'system': return MessageType.system;
      case 'video_call': return MessageType.video_call;
      case 'voice_call': return MessageType.voice_call;
      default: return MessageType.text;
    }
  }

  /// Grouped reactions: { emoji: count }
  Map<String, int> get reactionSummary {
    final map = <String, int>{};
    for (final emoji in reaction.values) {
      map[emoji] = (map[emoji] ?? 0) + 1;
    }
    return map;
  }

  Map<String, dynamic> toMap() => {
    'conversationId': conversationId,
    'senderId': senderId,
    'text': text,
    'type': type.name,
    'mediaUrl': mediaUrl,
    'seen': seen,
    'delivered': delivered,
    'seenAt': seenAt != null ? Timestamp.fromDate(seenAt!) : null,
    'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
    'isDeleted': isDeleted,
    'deletedFor': deletedFor,
    'replyToMessageId': replyToMessageId,
    'replyToText': replyToText,
    'replyToSenderId': replyToSenderId,
    'reaction': reaction,
    'isCallMessage': isCallMessage,
    'callStatus': callStatus,
    'callDuration': callDuration,
  };
}

/// Model cho conversation (cuộc trò chuyện)
class ConversationModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;
  final bool isBlocked;

  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    this.lastSenderId = '',
    this.lastMessageTime,
    this.unreadCount = const {},
    this.isBlocked = false,
  });

  factory ConversationModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return ConversationModel(
      id: doc.id,
      participants: List<String>.from(d['participants'] ?? []),
      lastMessage: d['lastMessage']?.toString() ?? '',
      lastSenderId: d['lastSenderId']?.toString() ?? '',
      lastMessageTime: d['lastMessageTime'] is Timestamp
          ? (d['lastMessageTime'] as Timestamp).toDate()
          : null,
      unreadCount: Map<String, int>.from(
        (d['unreadCount'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {},
      ),
      isBlocked: d['isBlocked'] == true,
    );
  }
}