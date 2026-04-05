import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String bio;
  final String photoUrl;
  final String city;
  final List<String> interests;

  UserModel({
    required this.uid,
    required this.name,
    required this.age,
    this.gender = '',
    required this.bio,
    required this.photoUrl,
    required this.city,
    this.interests = const [],
  });

  String get location => city;

  static int _parseAge(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt(); // ✅ Firestore đôi khi trả double
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  static List<String> _parseInterests(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    // ✅ Tránh crash nếu doc.data() null
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel(
      uid: doc.id,
      name: data['name']?.toString() ?? '',
      age: _parseAge(data['age']),
      gender: data['gender']?.toString() ?? '',
      bio: data['bio']?.toString() ?? '',
      photoUrl: (data['photoUrl'] ?? data['profileImageUrl'])?.toString() ?? '',
      city: (data['city'] ?? data['location'])?.toString() ?? '',
      interests: _parseInterests(data['interests']),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      name: data['name']?.toString() ?? '',
      age: _parseAge(data['age']),
      gender: data['gender']?.toString() ?? '',
      bio: data['bio']?.toString() ?? '',
      photoUrl: (data['photoUrl'] ?? data['profileImageUrl'])?.toString() ?? '',
      city: (data['city'] ?? data['location'])?.toString() ?? '',
      interests: _parseInterests(data['interests']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'age': age,
      'gender': gender,
      'bio': bio,
      'photoUrl': photoUrl,
      'city': city,
      'interests': interests,
    };
  }
}