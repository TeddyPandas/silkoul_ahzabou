import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tijani_article.dart';

/// Service for managing Tijani Articles
class TijaniArticleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all published articles
  /// 
  /// [limit] - Maximum number of articles to return
  /// [offset] - Number of articles to skip
  /// [category] - Filter by category
  /// [featured] - Filter only featured articles
  Future<List<TijaniArticle>> getArticles({
    int limit = 20,
    int offset = 0,
    ArticleCategory? category,
    bool? featured,
  }) async {
    try {
      var query = _supabase
          .from('tijani_articles')
          .select()
          .eq('status', 'published')
          .order('published_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (category != null) {
        query = query.eq('category', category.value);
      }

      if (featured != null && featured) {
        query = query.eq('is_featured', true);
      }

      final response = await query;
      
      return (response as List)
          .map((json) => TijaniArticle.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching articles: $e');
      return [];
    }
  }

  /// Get article by ID
  Future<TijaniArticle?> getArticleById(String id) async {
    try {
      final response = await _supabase
          .from('tijani_articles')
          .select()
          .eq('id', id)
          .single();

      return TijaniArticle.fromJson(response);
    } catch (e) {
      print('Error fetching article: $e');
      return null;
    }
  }

  /// Get featured articles
  Future<List<TijaniArticle>> getFeaturedArticles({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('tijani_articles')
          .select()
          .eq('status', 'published')
          .eq('is_featured', true)
          .order('published_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TijaniArticle.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching featured articles: $e');
      return [];
    }
  }

  /// Get articles by category
  Future<List<TijaniArticle>> getArticlesByCategory(
    ArticleCategory category, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('tijani_articles')
          .select()
          .eq('status', 'published')
          .eq('category', category.value)
          .order('published_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TijaniArticle.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching articles by category: $e');
      return [];
    }
  }

  /// Search articles by title or content
  Future<List<TijaniArticle>> searchArticles(String query) async {
    try {
      // Search in title (French and Arabic) and content
      final response = await _supabase
          .from('tijani_articles')
          .select()
          .eq('status', 'published')
          .or('title.ilike.%$query%,title_ar.ilike.%$query%,content.ilike.%$query%,content_ar.ilike.%$query%')
          .order('published_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((json) => TijaniArticle.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching articles: $e');
      return [];
    }
  }

  /// Get articles by tag
  Future<List<TijaniArticle>> getArticlesByTag(String tag) async {
    try {
      final response = await _supabase
          .from('tijani_articles')
          .select()
          .eq('status', 'published')
          .contains('tags', [tag])
          .order('published_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => TijaniArticle.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching articles by tag: $e');
      return [];
    }
  }

  /// Get related articles based on tags and category
  Future<List<TijaniArticle>> getRelatedArticles(
    TijaniArticle article, {
    int limit = 5,
  }) async {
    try {
      // First try to get explicitly related articles
      if (article.relatedArticleIds != null && 
          article.relatedArticleIds!.isNotEmpty) {
        final response = await _supabase
            .from('tijani_articles')
            .select()
            .in_('id', article.relatedArticleIds!)
            .eq('status', 'published')
            .limit(limit);

        final relatedArticles = (response as List)
            .map((json) => TijaniArticle.fromJson(json))
            .toList();

        if (relatedArticles.length >= limit) {
          return relatedArticles;
        }
      }

      // Fall back to articles with similar tags or same category
      final response = await _supabase
          .from('tijani_articles')
          .select()
          .eq('status', 'published')
          .eq('category', article.category.value)
          .neq('id', article.id)
          .order('published_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TijaniArticle.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching related articles: $e');
      return [];
    }
  }

  /// Get latest articles
  Future<List<TijaniArticle>> getLatestArticles({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('tijani_articles')
          .select()
          .eq('status', 'published')
          .order('published_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TijaniArticle.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching latest articles: $e');
      return [];
    }
  }

  /// Get popular articles (by view count)
  Future<List<TijaniArticle>> getPopularArticles({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('tijani_articles')
          .select()
          .eq('status', 'published')
          .order('view_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TijaniArticle.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching popular articles: $e');
      return [];
    }
  }

  /// Get articles by author
  Future<List<TijaniArticle>> getArticlesByAuthor(
    String authorId, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('tijani_articles')
          .select()
          .eq('author_id', authorId)
          .eq('status', 'published')
          .order('published_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => TijaniArticle.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching articles by author: $e');
      return [];
    }
  }

  /// Increment view count
  Future<void> incrementViewCount(String articleId) async {
    try {
      await _supabase.rpc('increment_article_views', params: {
        'article_id': articleId,
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  /// Like article
  Future<bool> likeArticle(String articleId, String userId) async {
    try {
      // Check if already liked
      final existing = await _supabase
          .from('article_likes')
          .select()
          .eq('article_id', articleId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Unlike
        await _supabase
            .from('article_likes')
            .delete()
            .eq('article_id', articleId)
            .eq('user_id', userId);

        await _supabase.rpc('decrement_article_likes', params: {
          'article_id': articleId,
        });

        return false; // Unliked
      } else {
        // Like
        await _supabase.from('article_likes').insert({
          'article_id': articleId,
          'user_id': userId,
        });

        await _supabase.rpc('increment_article_likes', params: {
          'article_id': articleId,
        });

        return true; // Liked
      }
    } catch (e) {
      print('Error liking article: $e');
      return false;
    }
  }

  /// Check if user liked article
  Future<bool> hasUserLiked(String articleId, String userId) async {
    try {
      final response = await _supabase
          .from('article_likes')
          .select()
          .eq('article_id', articleId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  /// Increment share count
  Future<void> incrementShareCount(String articleId) async {
    try {
      await _supabase.rpc('increment_article_shares', params: {
        'article_id': articleId,
      });
    } catch (e) {
      print('Error incrementing share count: $e');
    }
  }

  /// Create article (admin/author only)
  Future<TijaniArticle?> createArticle(TijaniArticle article) async {
    try {
      final response = await _supabase
          .from('tijani_articles')
          .insert(article.toJson())
          .select()
          .single();

      return TijaniArticle.fromJson(response);
    } catch (e) {
      print('Error creating article: $e');
      return null;
    }
  }

  /// Update article (admin/author only)
  Future<TijaniArticle?> updateArticle(TijaniArticle article) async {
    try {
      final response = await _supabase
          .from('tijani_articles')
          .update(article.toJson())
          .eq('id', article.id)
          .select()
          .single();

      return TijaniArticle.fromJson(response);
    } catch (e) {
      print('Error updating article: $e');
      return null;
    }
  }

  /// Delete article (admin only)
  Future<bool> deleteArticle(String articleId) async {
    try {
      await _supabase
          .from('tijani_articles')
          .delete()
          .eq('id', articleId);

      return true;
    } catch (e) {
      print('Error deleting article: $e');
      return false;
    }
  }

  /// Get all tags (for filtering)
  Future<List<String>> getAllTags() async {
    try {
      final response = await _supabase
          .from('tijani_articles')
          .select('tags')
          .eq('status', 'published');

      final allTags = <String>{};
      for (var article in response as List) {
        if (article['tags'] != null) {
          allTags.addAll(List<String>.from(article['tags']));
        }
      }

      return allTags.toList()..sort();
    } catch (e) {
      print('Error fetching tags: $e');
      return [];
    }
  }

  /// Get article count by category
  Future<Map<ArticleCategory, int>> getArticleCountByCategory() async {
    try {
      final response = await _supabase
          .from('tijani_articles')
          .select('category')
          .eq('status', 'published');

      final counts = <ArticleCategory, int>{};
      
      for (var article in response as List) {
        final category = ArticleCategory.fromString(article['category']);
        counts[category] = (counts[category] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error fetching category counts: $e');
      return {};
    }
  }
}
