import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/media_models.dart';

class MediaService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetches all authors
  Future<List<MediaAuthor>> getAuthors() async {
    final response = await _client
        .from('media_authors')
        .select()
        .order('name');
    
    return (response as List).map((e) => MediaAuthor.fromJson(e)).toList();
  }

  /// Fetches all categories sorted by rank
  Future<List<MediaCategory>> getCategories() async {
    final response = await _client
        .from('media_categories')
        .select()
        .order('rank');
    
    return (response as List).map((e) => MediaCategory.fromJson(e)).toList();
  }

  /// Fetches published videos, optionally filtered by Author or Category.
  /// Includes joined Author and Category data.
  Future<List<MediaVideo>> getVideos({
    String? authorId,
    String? categoryId,
    int limit = 50,
  }) async {
    // 1. Start filtering
    var query = _client
        .from('media_videos')
        .select('*, media_authors(*), media_categories(*)')
        .eq('status', 'PUBLISHED');

    // 2. Apply optional filters
    if (authorId != null) {
      query = query.eq('author_id', authorId);
    }
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }

    // 3. Apply sorting and limiting LAST
    // Note: We chain order() and limit() at the end because they return TransformBuilders
    final response = await query
        .order('published_at', ascending: false)
        .limit(limit);

    return (response as List).map((e) => MediaVideo.fromJson(e)).toList();
  }

  /// Fetches the latest "Featured" video (most recent published)
  Future<MediaVideo?> getFeaturedVideo() async {
    final response = await _client
        .from('media_videos')
        .select('*, media_authors(*), media_categories(*)')
        .eq('status', 'PUBLISHED')
        .order('published_at', ascending: false)
        .limit(1);

    if ((response as List).isEmpty) return null;
    return MediaVideo.fromJson(response[0]);
  }
}
