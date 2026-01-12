import 'author.dart';
import 'category.dart';

class PodcastShow {
  final String id;
  final String titleFr;
  final String titleAr;
  final String? descriptionFr;
  final String? descriptionAr;
  final String? imageUrl;
  final String? authorId;
  final Author? author;
  final String? categoryId;
  final Category? category;

  PodcastShow({
    required this.id,
    required this.titleFr,
    required this.titleAr,
    this.descriptionFr,
    this.descriptionAr,
    this.imageUrl,
    this.authorId,
    this.author,
    this.categoryId,
    this.category,
  });

  factory PodcastShow.fromJson(Map<String, dynamic> json) {
    return PodcastShow(
      id: json['id'],
      titleFr: json['title_fr'],
      titleAr: json['title_ar'],
      descriptionFr: json['description_fr'],
      descriptionAr: json['description_ar'],
      imageUrl: json['image_url'],
      authorId: json['author_id'],
      author: json['authors'] != null ? Author.fromJson(json['authors']) : null,
      categoryId: json['category_id'],
      category: json['categories'] != null ? Category.fromJson(json['categories']) : null,
    );
  }


  PodcastShow copyWith({
    String? id,
    String? titleFr,
    String? titleAr,
    String? descriptionFr,
    String? descriptionAr,
    String? imageUrl,
    String? authorId,
    String? categoryId,
  }) {
    return PodcastShow(
      id: id ?? this.id,
      titleFr: titleFr ?? this.titleFr,
      titleAr: titleAr ?? this.titleAr,
      descriptionFr: descriptionFr ?? this.descriptionFr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      imageUrl: imageUrl ?? this.imageUrl,
      authorId: authorId ?? this.authorId,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}
