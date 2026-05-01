import 'package:cloud_firestore/cloud_firestore.dart';

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
