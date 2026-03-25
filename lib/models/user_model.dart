class UserModel {
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String bio;
  final String photoUrl;
  final String city;

  UserModel({
    required this.uid,
    required this.name,
    required this.age,
    required this.gender,
    required this.bio,
    required this.photoUrl,
    required this.city,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'age': age,
    'gender': gender,
    'bio': bio,
    'photoUrl': photoUrl,
    'city': city,
    'createdAt': DateTime.now(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    // Xử lý age có thể là int hoặc string
    age: map['age'] is int ? map['age'] : int.tryParse(map['age'].toString()) ?? 0,
    gender: map['gender']?.toString() ?? '',
    bio: map['bio']?.toString() ?? '',
    photoUrl: map['photoUrl']?.toString() ?? '',
    city: map['city']?.toString() ?? '',
  );
}