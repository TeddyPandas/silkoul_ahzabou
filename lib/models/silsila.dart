class Silsila {
  final String id;
  final String name;
  final bool isGlobal;
  final String? imageUrl;
  final int level;
  final String? description;
  // Note: Parent IDs sont gérés à part ou chargés à la demande dans une structure de graphe
  
  final DateTime createdAt;

  Silsila({
    required this.id,
    required this.name,
    this.isGlobal = false,
    this.imageUrl,
    required this.level,
    this.description,
    required this.createdAt,
  });

  factory Silsila.fromJson(Map<String, dynamic> json) {
    return Silsila(
      id: json['id'] as String,
      name: json['name'] as String,
      isGlobal: json['is_global'] ?? false,
      imageUrl: json['image_url'] as String?,
      level: json['level'] as int,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_global': isGlobal,
      'image_url': imageUrl,
      'level': level,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Silsila copyWith({
    String? name,
    bool? isGlobal,
    String? imageUrl,
    int? level,
    String? description,
  }) {
    return Silsila(
      id: id,
      name: name ?? this.name,
      isGlobal: isGlobal ?? this.isGlobal,
      imageUrl: imageUrl ?? this.imageUrl,
      level: level ?? this.level,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }
}
