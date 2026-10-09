class User {
  final String id;
  final String username;
  final String email;
  final String? profileImage;
  final int level;
  final int totalPoints;
  final int totalAreas;
  final int totalDistance;
  final DateTime createdAt;
  final List<String> badges;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profileImage,
    this.level = 1,
    this.totalPoints = 0,
    this.totalAreas = 0,
    this.totalDistance = 0,
    required this.createdAt,
    this.badges = const [],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      profileImage: json['profileImage'],
      level: json['level'] ?? 1,
      totalPoints: json['totalPoints'] ?? 0,
      totalAreas: json['totalAreas'] ?? 0,
      totalDistance: json['totalDistance'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      badges: List<String>.from(json['badges'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImage': profileImage,
      'level': level,
      'totalPoints': totalPoints,
      'totalAreas': totalAreas,
      'totalDistance': totalDistance,
      'createdAt': createdAt.toIso8601String(),
      'badges': badges,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? profileImage,
    int? level,
    int? totalPoints,
    int? totalAreas,
    int? totalDistance,
    DateTime? createdAt,
    List<String>? badges,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      level: level ?? this.level,
      totalPoints: totalPoints ?? this.totalPoints,
      totalAreas: totalAreas ?? this.totalAreas,
      totalDistance: totalDistance ?? this.totalDistance,
      createdAt: createdAt ?? this.createdAt,
      badges: badges ?? this.badges,
    );
  }
} 