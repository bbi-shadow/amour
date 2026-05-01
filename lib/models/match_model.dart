import 'package:cloud_firestore/cloud_firestore.dart';

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
