/// Model representing a Nafahat Article/Publication

/// Model representing a Nafahat Article/Publication
///
/// Supports various types of spiritual content including:
/// - Teachings (Enseignements)
/// - Biographies (Biographies)
/// - Litanies (Wird/Adhkar)
/// - Stories (Récits)
/// - Fatwas and Rulings
class NafahatArticle {
  final String id;
  final String title;
  final String titleAr;
  final String content;
  final String contentAr;
  final String summary;
  final String summaryAr;
  final ArticleCategory category;
  final String authorId;
  final String authorName;
  final String? authorNameAr;
  final String? imageUrl;
  final List<String> tags;
  final List<String> tagsAr;
  final String? silsilaReference;
  final String? source;
  final String? sourceAr;
  final DateTime publishedAt;
  final DateTime? updatedAt;
  final int viewCount;
  final int likeCount;
  final int shareCount;
  final bool isFeatured;
  final bool isVerified;
  final ArticleStatus status;
  final DifficultyLevel? difficultyLevel;
  final int estimatedReadTime; // in minutes
  final List<String>? relatedArticleIds;
  final Map<String, dynamic>? metadata;

  NafahatArticle({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.content,
    required this.contentAr,
    required this.summary,
    required this.summaryAr,
    required this.category,
    required this.authorId,
    required this.authorName,
    this.authorNameAr,
    this.imageUrl,
    this.tags = const [],
    this.tagsAr = const [],
    this.silsilaReference,
    this.source,
    this.sourceAr,
    required this.publishedAt,
    this.updatedAt,
    this.viewCount = 0,
    this.likeCount = 0,
    this.shareCount = 0,
    this.isFeatured = false,
    this.isVerified = false,
    this.status = ArticleStatus.published,
    this.difficultyLevel,
    this.estimatedReadTime = 5,
    this.relatedArticleIds,
    this.metadata,
  });

  /// Create from JSON (Supabase)
  factory NafahatArticle.fromJson(Map<String, dynamic> json) {
    return NafahatArticle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      titleAr: json['title_ar'] ?? '',
      content: json['content'] ?? '',
      contentAr: json['content_ar'] ?? '',
      summary: json['summary'] ?? '',
      summaryAr: json['summary_ar'] ?? '',
      category: ArticleCategory.fromString(json['category'] ?? 'teaching'),
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? '',
      authorNameAr: json['author_name_ar'],
      imageUrl: json['image_url'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      tagsAr: json['tags_ar'] != null ? List<String>.from(json['tags_ar']) : [],
      silsilaReference: json['silsila_reference'],
      source: json['source'],
      sourceAr: json['source_ar'],
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      shareCount: json['share_count'] ?? 0,
      isFeatured: json['is_featured'] ?? false,
      isVerified: json['is_verified'] ?? false,
      status: ArticleStatus.fromString(json['status'] ?? 'published'),
      difficultyLevel: json['difficulty_level'] != null
          ? DifficultyLevel.fromString(json['difficulty_level'])
          : null,
      estimatedReadTime: json['estimated_read_time'] ?? 5,
      relatedArticleIds: json['related_article_ids'] != null
          ? List<String>.from(json['related_article_ids'])
          : null,
      metadata: json['metadata'],
    );
  }

  /// Convert to JSON (Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_ar': titleAr,
      'content': content,
      'content_ar': contentAr,
      'summary': summary,
      'summary_ar': summaryAr,
      'category': category.value,
      'author_id': authorId,
      'author_name': authorName,
      'author_name_ar': authorNameAr,
      'image_url': imageUrl,
      'tags': tags,
      'tags_ar': tagsAr,
      'silsila_reference': silsilaReference,
      'source': source,
      'source_ar': sourceAr,
      'published_at': publishedAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'view_count': viewCount,
      'like_count': likeCount,
      'share_count': shareCount,
      'is_featured': isFeatured,
      'is_verified': isVerified,
      'status': status.value,
      'difficulty_level': difficultyLevel?.value,
      'estimated_read_time': estimatedReadTime,
      'related_article_ids': relatedArticleIds,
      'metadata': metadata,
    };
  }

  /// Copy with modifications
  NafahatArticle copyWith({
    String? id,
    String? title,
    String? titleAr,
    String? content,
    String? contentAr,
    String? summary,
    String? summaryAr,
    ArticleCategory? category,
    String? authorId,
    String? authorName,
    String? authorNameAr,
    String? imageUrl,
    List<String>? tags,
    List<String>? tagsAr,
    String? silsilaReference,
    String? source,
    String? sourceAr,
    DateTime? publishedAt,
    DateTime? updatedAt,
    int? viewCount,
    int? likeCount,
    int? shareCount,
    bool? isFeatured,
    bool? isVerified,
    ArticleStatus? status,
    DifficultyLevel? difficultyLevel,
    int? estimatedReadTime,
    List<String>? relatedArticleIds,
    Map<String, dynamic>? metadata,
  }) {
    return NafahatArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      content: content ?? this.content,
      contentAr: contentAr ?? this.contentAr,
      summary: summary ?? this.summary,
      summaryAr: summaryAr ?? this.summaryAr,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorNameAr: authorNameAr ?? this.authorNameAr,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      tagsAr: tagsAr ?? this.tagsAr,
      silsilaReference: silsilaReference ?? this.silsilaReference,
      source: source ?? this.source,
      sourceAr: sourceAr ?? this.sourceAr,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      shareCount: shareCount ?? this.shareCount,
      isFeatured: isFeatured ?? this.isFeatured,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      estimatedReadTime: estimatedReadTime ?? this.estimatedReadTime,
      relatedArticleIds: relatedArticleIds ?? this.relatedArticleIds,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Increment view count
  NafahatArticle incrementViews() {
    return copyWith(viewCount: viewCount + 1);
  }

  /// Increment like count
  NafahatArticle incrementLikes() {
    return copyWith(likeCount: likeCount + 1);
  }

  /// Decrement like count
  NafahatArticle decrementLikes() {
    return copyWith(likeCount: likeCount > 0 ? likeCount - 1 : 0);
  }

  /// Increment share count
  NafahatArticle incrementShares() {
    return copyWith(shareCount: shareCount + 1);
  }

  /// Check if article is new (published within last 7 days)
  bool get isNew {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);
    return difference.inDays <= 7;
  }

  /// Check if article was recently updated (updated within last 3 days)
  bool get isRecentlyUpdated {
    if (updatedAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(updatedAt!);
    return difference.inDays <= 3;
  }

  /// Get formatted publish date
  String get formattedPublishDate {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays == 0) {
      return "Aujourd'hui";
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }

  @override
  String toString() {
    return 'NafahatArticle(id: $id, title: $title, category: ${category.label})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NafahatArticle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Article Category Enum
enum ArticleCategory {
  teaching('teaching', 'Enseignement', 'تعليم', '📚', '#0FA958'),
  biography('biography', 'Biographie', 'السيرة الذاتية', '👤', '#9B7EBD'),
  litany('litany', 'Wird/Litanie', 'ورد', '📿', '#D4AF37'),
  story('story', 'Récit', 'قصة', '📖', '#3B82F6'),
  fatwa('fatwa', 'Fatwa', 'فتوى', '⚖️', '#EF4444'),
  poem('poem', 'Poème', 'قصيدة', '✍️', '#EC4899'),
  dhikr('dhikr', 'Dhikr', 'ذكر', '🌟', '#10B981'),
  dua('dua', 'Dua', 'دعاء', '🤲', '#8B5CF6'),
  wisdom('wisdom', 'Sagesse', 'حكمة', '💡', '#F59E0B'),
  history('history', 'Histoire', 'تاريخ', '📜', '#6366F1');

  final String value;
  final String label;
  final String labelAr;
  final String icon;
  final String color;

  const ArticleCategory(
      this.value, this.label, this.labelAr, this.icon, this.color);

  static ArticleCategory fromString(String value) {
    return ArticleCategory.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ArticleCategory.teaching,
    );
  }

  /// Get Color object from hex string
  int get colorValue {
    final hex = color.replaceFirst('#', '');
    return int.parse('FF$hex', radix: 16);
  }
}

/// Article Status Enum
enum ArticleStatus {
  draft('draft', 'Brouillon'),
  review('review', 'En révision'),
  published('published', 'Publié'),
  archived('archived', 'Archivé');

  final String value;
  final String label;

  const ArticleStatus(this.value, this.label);

  static ArticleStatus fromString(String value) {
    return ArticleStatus.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => ArticleStatus.published,
    );
  }
}

/// Difficulty Level Enum
enum DifficultyLevel {
  beginner('beginner', 'Débutant', 'مبتدئ', '#10B981'),
  intermediate('intermediate', 'Intermédiaire', 'متوسط', '#F59E0B'),
  advanced('advanced', 'Avancé', 'متقدم', '#EF4444'),
  scholar('scholar', 'Érudit', 'عالم', '#8B5CF6');

  final String value;
  final String label;
  final String labelAr;
  final String color;

  const DifficultyLevel(this.value, this.label, this.labelAr, this.color);

  static DifficultyLevel fromString(String value) {
    return DifficultyLevel.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => DifficultyLevel.beginner,
    );
  }

  /// Get Color object from hex string
  int get colorValue {
    final hex = color.replaceFirst('#', '');
    return int.parse('FF$hex', radix: 16);
  }
}
