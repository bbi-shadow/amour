import 'package:cloud_firestore/cloud_firestore.dart';

/// ══════════════════════════════════════════════════════════════
/// UserModel — Model người dùng đầy đủ cho Amour Dating App
/// Hỗ trợ: 6 ảnh, sở thích, vị trí, premium, verify badge, v.v.
/// ══════════════════════════════════════════════════════════════
class UserModel {
  final String uid;
  final String name;
  final String email;
  final int age;
  final String gender;             // 'Nam' | 'Nữ' | 'Khác'
  final String lookingFor;         // Giới tính mong muốn tìm kiếm
  final String bio;
  final String photoUrl;           // Ảnh đại diện chính
  final List<String> photos;       // Tối đa 6 ảnh hồ sơ
  final String city;
  final double? latitude;
  final double? longitude;
  final int searchRadius;          // km
  final List<String> interests;    // Sở thích
  final String occupation;         // Nghề nghiệp
  final String school;             // Trường học
  final int height;                // cm
  final String zodiac;             // Cung hoàng đạo
  final String relationshipGoal;   // Mục tiêu hẹn hò
  final String maritalStatus;      // Tình trạng hôn nhân
  final bool isVerified;           // Verify badge
  final bool isPremium;            // Gói premium
  final String premiumPlan;        // 'free' | 'basic' | 'gold' | 'platinum'
  final DateTime? premiumExpiry;
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isBanned;
  final String banReason;
  final DateTime? createdAt;
  final int likeCount;             // Số lượt thích nhận được
  final int superLikeCount;        // Số Super Like còn lại
  final int boostCount;            // Số Boost còn lại
  final int dailySwipeCount;       // Số swipe hôm nay
  final DateTime? dailySwipeReset; // Thời điểm reset swipe

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
    this.occupation = '',
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

  /// Kiểm tra còn swipe không (free: 20/ngày, premium: unlimited)
  bool get canSwipe {
    if (isPremium) return true;
    if (dailySwipeReset == null) return true;
    final now = DateTime.now();
    final reset = dailySwipeReset!;
    if (now.difference(reset).inHours >= 24) return true; // reset rồi
    return dailySwipeCount < 20;
  }

  String get location => city;

  // ── Parse helpers ──────────────────────────────────────────
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

  // ── Factory constructors ───────────────────────────────────
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel._fromMap(data, doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel._fromMap(data, uid);
  }

  factory UserModel._fromMap(Map<String, dynamic> d, String uid) {
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
      interests: _parseList(d['interests']),
      occupation: d['occupation']?.toString() ?? '',
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
      'uid': uid,
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'lookingFor': lookingFor,
      'bio': bio,
      'photoUrl': photoUrl,
      'photos': photos,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'searchRadius': searchRadius,
      'interests': interests,
      'occupation': occupation,
      'school': school,
      'height': height,
      'zodiac': zodiac,
      'relationshipGoal': relationshipGoal,
      'maritalStatus': maritalStatus,
      'isVerified': isVerified,
      'isPremium': isPremium,
      'premiumPlan': premiumPlan,
      'premiumExpiry': premiumExpiry != null ? Timestamp.fromDate(premiumExpiry!) : null,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'isBanned': isBanned,
      'banReason': banReason,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'likeCount': likeCount,
      'superLikeCount': superLikeCount,
      'boostCount': boostCount,
      'dailySwipeCount': dailySwipeCount,
      'dailySwipeReset': dailySwipeReset != null ? Timestamp.fromDate(dailySwipeReset!) : null,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    int? age,
    String? gender,
    String? lookingFor,
    String? bio,
    String? photoUrl,
    List<String>? photos,
    String? city,
    double? latitude,
    double? longitude,
    int? searchRadius,
    List<String>? interests,
    String? occupation,
    String? school,
    int? height,
    String? zodiac,
    String? relationshipGoal,
    String? maritalStatus,
    bool? isVerified,
    bool? isPremium,
    String? premiumPlan,
    DateTime? premiumExpiry,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      photos: photos ?? this.photos,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      searchRadius: searchRadius ?? this.searchRadius,
      interests: interests ?? this.interests,
      occupation: occupation ?? this.occupation,
      school: school ?? this.school,
      height: height ?? this.height,
      zodiac: zodiac ?? this.zodiac,
      relationshipGoal: relationshipGoal ?? this.relationshipGoal,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      premiumPlan: premiumPlan ?? this.premiumPlan,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isBanned: isBanned,
      banReason: banReason,
      createdAt: createdAt,
    );
  }
}
