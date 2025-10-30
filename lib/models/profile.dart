class Profile {
  final String id;
  final String displayName;
  final String email;
  final String? phone;
  final String? address;
  final DateTime? dateOfBirth;
  final String? silsilaId;
  final String? avatarUrl;
  final int points;
  final int level;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.displayName,
    required this.email,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.silsilaId,
    this.avatarUrl,
    this.points = 0,
    this.level = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor pour créer depuis JSON (Supabase)
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      silsilaId: json['silsila_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      points: json['points'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Convertir en JSON pour Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'email': email,
      'phone': phone,
      'address': address,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'silsila_id': silsilaId,
      'avatar_url': avatarUrl,
      'points': points,
      'level': level,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // CopyWith pour immutabilité
  Profile copyWith({
    String? displayName,
    String? email,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    String? silsilaId,
    String? avatarUrl,
    int? points,
    int? level,
    DateTime? updatedAt,
  }) {
    return Profile(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      silsilaId: silsilaId ?? this.silsilaId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      points: points ?? this.points,
      level: level ?? this.level,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculer le niveau basé sur les points
  static int calculateLevel(int points) {
    if (points < 500) return 1;
    if (points < 1500) return 2;
    if (points < 3000) return 3;
    if (points < 5000) return 4;
    if (points < 8000) return 5;
    return 6; // Niveau maximum
  }
}
