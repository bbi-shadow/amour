class UserSettingsModel {
  bool notifMatch;
  bool notifMessage;
  bool notifLike;
  bool vibration;
  bool showOnline;
  bool showDistance;
  bool showAge;
  int searchRadius;
  String lookingFor;

  UserSettingsModel({
    this.notifMatch = true,
    this.notifMessage = true,
    this.notifLike = true,
    this.vibration = true,
    this.showOnline = true,
    this.showDistance = true,
    this.showAge = true,
    this.searchRadius = 50,
    this.lookingFor = 'Tất cả',
  });

  factory UserSettingsModel.fromMap(Map<String, dynamic> data) {
    return UserSettingsModel(
      notifMatch: data['notifMatch'] ?? true,
      notifMessage: data['notifMessage'] ?? true,
      notifLike: data['notifLike'] ?? true,
      vibration: data['vibration'] ?? true,
      showOnline: data['showOnline'] ?? true,
      showDistance: data['showDistance'] ?? true,
      showAge: data['showAge'] ?? true,
      searchRadius: (data['searchRadius'] as num?)?.toInt() ?? 50,
      lookingFor: data['lookingFor']?.toString() ?? 'Tất cả',
    );
  }

  Map<String, dynamic> toMap() => {
    'notifMatch': notifMatch,
    'notifMessage': notifMessage,
    'notifLike': notifLike,
    'vibration': vibration,
    'showOnline': showOnline,
    'showDistance': showDistance,
    'showAge': showAge,
    'searchRadius': searchRadius,
    'lookingFor': lookingFor,
  };
}
