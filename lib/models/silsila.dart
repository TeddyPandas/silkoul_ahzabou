class Silsila {
  final String id;
  final String name;
  final String? imageUrl;
  final int level;
  final bool isGlobal;
  final DateTime? createdAt;

  Silsila({
    required this.id,
    required this.name,
    this.imageUrl,
    this.level = 0,
    this.isGlobal = false,
    this.createdAt,
  });

  factory Silsila.fromJson(Map<String, dynamic> json) {
    return Silsila(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      level: json['level'] is int ? json['level'] : 0,
      isGlobal: json['is_global'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'level': level,
      'is_global': isGlobal,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
