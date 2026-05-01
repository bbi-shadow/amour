import 'package:cloud_firestore/cloud_firestore.dart';

/// Các loại tin nhắn
enum MessageType { text, image, emoji, sticker, voice, system, video_call, voice_call }

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final MessageType type;
  final String? mediaUrl;       // URL ảnh/voice
  final bool seen;
  final DateTime? timestamp;
  final bool isDeleted;
  final String? replyToText;
  
  // Call fields
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
    this.timestamp,
    this.isDeleted = false,
    this.replyToText,
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
      timestamp: d['timestamp'] is Timestamp ? (d['timestamp'] as Timestamp).toDate() : null,
      isDeleted: d['isDeleted'] == true,
      replyToText: d['replyToText']?.toString(),
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

  Map<String, dynamic> toMap() => {
    'conversationId': conversationId,
    'senderId': senderId,
    'text': text,
    'type': type.name,
    'mediaUrl': mediaUrl,
    'seen': seen,
    'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
    'isDeleted': isDeleted,
    'replyToText': replyToText,
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
