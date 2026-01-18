
class MediaAuthor {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bio;

  MediaAuthor({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bio,
  });

  factory MediaAuthor.fromJson(Map<String, dynamic> json) {
    return MediaAuthor(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
    );
  }
}

class MediaCategory {
  final String id;
  final String name;
  final int rank;

  MediaCategory({
    required this.id,
    required this.name,
    required this.rank,
  });

  factory MediaCategory.fromJson(Map<String, dynamic> json) {
    return MediaCategory(
      id: json['id'],
      name: json['name'],
      rank: json['rank'] ?? 0,
    );
  }
}

class MediaVideo {
  final String id;
  final String youtubeId;
  final String title;
  final String? description;
  final int? duration;
  final DateTime? publishedAt;
  final String? customSubtitleUrl;
  
  // Relations
  final String? authorId;
  final String? categoryId;
  
  // Expanded for UI (Optional)
  final MediaAuthor? author;
  final MediaCategory? category;

  MediaVideo({
    required this.id,
    required this.youtubeId,
    required this.title,
    this.description,
    this.duration,
    this.publishedAt,
    this.customSubtitleUrl,
    this.authorId,
    this.categoryId,
    this.author,
    this.category,
  });

  factory MediaVideo.fromJson(Map<String, dynamic> json) {
    return MediaVideo(
      id: json['id'],
      youtubeId: json['youtube_id'],
      title: json['title'],
      description: json['description'],
      duration: json['duration'],
      publishedAt: json['published_at'] != null 
          ? DateTime.parse(json['published_at']) 
          : null,
      customSubtitleUrl: json['custom_subtitle_url'],
      authorId: json['author_id'],
      categoryId: json['category_id'],
      author: json['media_authors'] != null ? MediaAuthor.fromJson(json['media_authors']) : null,
      category: json['media_categories'] != null ? MediaCategory.fromJson(json['media_categories']) : null,
    );
  }
  
  String get thumbnailUrl => 'https://img.youtube.com/vi/$youtubeId/maxresdefault.jpg';
}
