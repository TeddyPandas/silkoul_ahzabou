
import 'author.dart';
import 'category.dart';

class Article {
  final String id;
  final String titleFr;
  final String titleAr;
  final String? contentFr;
  final String? contentAr;
  final String? authorId;
  final Author? author;
  final String? categoryId;
  final Category? category;
  final int readTimeMinutes;
  final int viewsCount;
  final bool isFeatured;
  final DateTime publishedAt;

  Article({
    required this.id,
    required this.titleFr,
    required this.titleAr,
    this.contentFr,
    this.contentAr,
    this.authorId,
    this.author,
    this.categoryId,
    this.category,
    this.readTimeMinutes = 5,
    this.viewsCount = 0,
    this.isFeatured = false,
    required this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      titleFr: json['title_fr'],
      titleAr: json['title_ar'],
      contentFr: json['content_fr'],
      contentAr: json['content_ar'],
      authorId: json['author_id'],
      author: json['authors'] != null ? Author.fromJson(json['authors']) : null,
      categoryId: json['category_id'],
      category: json['categories'] != null ? Category.fromJson(json['categories']) : null,
      readTimeMinutes: json['read_time_minutes'] ?? 5,
      viewsCount: json['views_count'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
      publishedAt: DateTime.parse(json['published_at']),
    );
  }
}
