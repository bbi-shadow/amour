import 'package:cloud_firestore/cloud_firestore.dart';

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
