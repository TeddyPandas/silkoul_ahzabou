
class Category {
  final String id;
  final String nameFr;
  final String nameAr;
  final String slug;
  final String? iconName;

  Category({
    required this.id,
    required this.nameFr,
    required this.nameAr,
    required this.slug,
    this.iconName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      nameFr: json['name_fr'],
      nameAr: json['name_ar'],
      slug: json['slug'],
      iconName: json['icon_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_fr': nameFr,
      'name_ar': nameAr,
      'slug': slug,
      'icon_name': iconName,
    };
  }
}
