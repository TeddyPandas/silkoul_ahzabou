
import 'author.dart';
import 'category.dart';

enum TeachingType { VIDEO, AUDIO }

class Teaching {
  final String id;
  final String titleFr;
  final String titleAr;
  final String? descriptionFr;
  final String? descriptionAr;
  final TeachingType type;
  final String mediaUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final String? authorId;
  final Author? author;
  final String? categoryId;
  final Category? category;
  final int viewsCount;
  final bool isFeatured;
  final DateTime publishedAt;
  final String? podcastShowId;

  Teaching({
    required this.id,
    required this.titleFr,
    required this.titleAr,
    this.descriptionFr,
    this.descriptionAr,
    required this.type,
    required this.mediaUrl,
    this.thumbnailUrl,
    this.durationSeconds = 0,
    this.authorId,
    this.author,
    this.categoryId,
    this.category,
    this.viewsCount = 0,
    this.isFeatured = false,
    required this.publishedAt,
    this.podcastShowId,
  });

  factory Teaching.fromJson(Map<String, dynamic> json) {
    return Teaching(
      id: json['id'],
      titleFr: json['title_fr'],
      titleAr: json['title_ar'],
      descriptionFr: json['description_fr'],
      descriptionAr: json['description_ar'],
      type: TeachingType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TeachingType.VIDEO,
      ),
      mediaUrl: json['media_url'],
      thumbnailUrl: json['thumbnail_url'],
      durationSeconds: json['duration_seconds'] ?? 0,
      authorId: json['author_id'],
      author: json['authors'] != null ? Author.fromJson(json['authors']) : null,
      categoryId: json['category_id'],
      category: json['categories'] != null ? Category.fromJson(json['categories']) : null,
      viewsCount: json['views_count'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
      publishedAt: DateTime.parse(json['published_at']),
      podcastShowId: json['podcast_show_id'],
    );
  }
}
