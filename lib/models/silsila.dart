class Silsila {
  final String id;
  final String name;
  final String? parentId;
  final int level;
  final String? description;
  final DateTime createdAt;

  Silsila({
    required this.id,
    required this.name,
    this.parentId,
    required this.level,
    this.description,
    required this.createdAt,
  });

  factory Silsila.fromJson(Map<String, dynamic> json) {
    return Silsila(
      id: json['id'] as String,
      name: json['name'] as String,
      parentId: json['parent_id'] as String?,
      level: json['level'] as int,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'level': level,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Vérifier si c'est une silsila racine
  bool get isRoot {
    return parentId == null;
  }

  Silsila copyWith({
    String? name,
    String? parentId,
    int? level,
    String? description,
  }) {
    return Silsila(
      id: id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }
}
