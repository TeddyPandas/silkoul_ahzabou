
class SilsilaNode {
  final String id;
  final String name;
  final String? image;
  final bool isGlobal; // Identifie si c'est un Grand Cheikh reconnu (Base globale)
  final bool isUser;   // Identifie le nœud de l'utilisateur courant
  
  // Graph connections
  final List<String> parentIds;
  final List<String> childrenIds;
  
  // Layout coordinates (calculées dynamiquement)
  double x;
  double y;
  int level; // Niveau générationnel (0 = Utilsateur, 1 = Parents, etc.)

  SilsilaNode({
    required this.id,
    required this.name,
    this.image,
    this.isGlobal = false,
    this.isUser = false,
    this.parentIds = const [],
    this.childrenIds = const [],
    this.x = 0,
    this.y = 0,
    this.level = 0,
  });

  // Pour faciliter la création de mocks/copies
  SilsilaNode copyWith({
    String? id,
    String? name,
    String? image,
    bool? isGlobal,
    bool? isUser,
    List<String>? parentIds,
    List<String>? childrenIds,
    double? x,
    double? y,
    int? level,
  }) {
    return SilsilaNode(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      isGlobal: isGlobal ?? this.isGlobal,
      isUser: isUser ?? this.isUser,
      parentIds: parentIds ?? this.parentIds,
      childrenIds: childrenIds ?? this.childrenIds,
      x: x ?? this.x,
      y: y ?? this.y,
      level: level ?? this.level,
    );
  }

  @override
  String toString() => 'SilsilaNode(id: $id, name: $name, level: $level)';
}
