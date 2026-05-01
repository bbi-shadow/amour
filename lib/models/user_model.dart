import 'package:cloud_firestore/cloud_firestore.dart';

/// ══════════════════════════════════════════════════════════════
/// UserModel — Model người dùng đầy đủ cho Amour Dating App
/// ══════════════════════════════════════════════════════════════
class UserModel {
  final String uid;
  final String name;
  final String email;
  final int age;
  final String gender;
  final String lookingFor;
  final String bio;
  final String photoUrl;
  final List<String> photos;
  final String city;
  final double? latitude;
  final double? longitude;
  final int searchRadius;
  final List<String> interests;
  final String job;                 // ✅ Đã đổi từ occupation thành job
  final String school;
  final int height;
  final String zodiac;
  final String relationshipGoal;
  final String maritalStatus;
  final bool isVerified;
  final bool isPremium;
  final String premiumPlan;
  final DateTime? premiumExpiry;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isBanned;
  final String banReason;
  final DateTime? createdAt;
  final int likeCount;
  final int superLikeCount;
  final int boostCount;
  final int dailySwipeCount;
  final DateTime? dailySwipeReset;

  UserModel({
    required this.uid,
    required this.name,
    this.email = '',
    required this.age,
    this.gender = '',
    this.lookingFor = 'Tất cả',
    required this.bio,
    required this.photoUrl,
    this.photos = const [],
    required this.city,
    this.latitude,
    this.longitude,
    this.searchRadius = 50,
    this.interests = const [],
    this.job = '',
    this.school = '',
    this.height = 0,
    this.zodiac = '',
    this.relationshipGoal = '',
    this.maritalStatus = '',
    this.isVerified = false,
    this.isPremium = false,
    this.premiumPlan = 'free',
    this.premiumExpiry,
    this.isOnline = false,
    this.lastSeen,
    this.isBanned = false,
    this.banReason = '',
    this.createdAt,
    this.likeCount = 0,
    this.superLikeCount = 5,
    this.boostCount = 0,
    this.dailySwipeCount = 0,
    this.dailySwipeReset,
  });

  bool get canSwipe {
    if (isPremium) return true;
    if (dailySwipeReset == null) return true;
    final now = DateTime.now();
    if (now.difference(dailySwipeReset!).inHours >= 24) return true;
    return dailySwipeCount < 20;
  }

  String get location => city;
  List<String> get hobbies => interests; // ✅ Alias cho interests

  static int _parseInt(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  static double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is double) return raw;
    if (raw is int) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  static List<String> _parseList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    return [];
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return null;
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    final uid = doc.id;
    return UserModel(
      uid: uid,
      name: d['name']?.toString() ?? '',
      email: d['email']?.toString() ?? '',
      age: _parseInt(d['age']),
      gender: d['gender']?.toString() ?? '',
      lookingFor: d['lookingFor']?.toString() ?? 'Tất cả',
      bio: d['bio']?.toString() ?? '',
      photoUrl: (d['photoUrl'] ?? d['profileImageUrl'])?.toString() ?? '',
      photos: _parseList(d['photos']),
      city: (d['city'] ?? d['location'])?.toString() ?? '',
      latitude: _parseDouble(d['latitude']),
      longitude: _parseDouble(d['longitude']),
      searchRadius: _parseInt(d['searchRadius'] ?? 50),
      interests: _parseList(d['interests'] ?? d['hobbies']),
      job: (d['job'] ?? d['occupation'])?.toString() ?? '',
      school: d['school']?.toString() ?? '',
      height: _parseInt(d['height']),
      zodiac: d['zodiac']?.toString() ?? '',
      relationshipGoal: d['relationshipGoal']?.toString() ?? '',
      maritalStatus: d['maritalStatus']?.toString() ?? '',
      isVerified: d['isVerified'] == true,
      isPremium: d['isPremium'] == true,
      premiumPlan: d['premiumPlan']?.toString() ?? 'free',
      premiumExpiry: _parseDate(d['premiumExpiry']),
      isOnline: d['isOnline'] == true,
      lastSeen: _parseDate(d['lastSeen']),
      isBanned: d['isBanned'] == true,
      banReason: d['banReason']?.toString() ?? '',
      createdAt: _parseDate(d['createdAt']),
      likeCount: _parseInt(d['likeCount']),
      superLikeCount: _parseInt(d['superLikeCount'] ?? 5),
      boostCount: _parseInt(d['boostCount']),
      dailySwipeCount: _parseInt(d['dailySwipeCount']),
      dailySwipeReset: _parseDate(d['dailySwipeReset']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid, 'name': name, 'email': email, 'age': age, 'gender': gender,
      'lookingFor': lookingFor, 'bio': bio, 'photoUrl': photoUrl, 'photos': photos,
      'city': city, 'latitude': latitude, 'longitude': longitude,
      'searchRadius': searchRadius, 'interests': interests, 'job': job,
      'school': school, 'height': height, 'zodiac': zodiac,
      'relationshipGoal': relationshipGoal, 'maritalStatus': maritalStatus,
      'isVerified': isVerified, 'isPremium': isPremium, 'premiumPlan': premiumPlan,
      'premiumExpiry': premiumExpiry != null ? Timestamp.fromDate(premiumExpiry!) : null,
      'isOnline': isOnline, 'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isBanned': isBanned, 'banReason': banReason,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'likeCount': likeCount, 'superLikeCount': superLikeCount, 'boostCount': boostCount,
      'dailySwipeCount': dailySwipeCount,
      'dailySwipeReset': dailySwipeReset != null ? Timestamp.fromDate(dailySwipeReset!) : null,
    };
  }
}
