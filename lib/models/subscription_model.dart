import 'package:cloud_firestore/cloud_firestore.dart';

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
