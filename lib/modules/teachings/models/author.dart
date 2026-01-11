
class Author {
  final String id;
  final String name;
  final String? bio;
  final String? imageUrl;

  Author({
    required this.id,
    required this.name,
    this.bio,
    this.imageUrl,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'],
      name: json['name'],
      bio: json['bio'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'image_url': imageUrl,
    };
  }
  

  Author copyWith({
    String? id,
    String? name,
    String? bio,
    String? imageUrl,
  }) {
    return Author(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
