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
  /// Returns a record with the list of videos and the total count.
  Future<({List<MediaVideo> videos, int count})> getVideos({
    String? authorId,
    String? categoryId,
    int? page,
    int limit = 50,
  }) async {
    // 1. Get Count
    var countQuery = _client.from('media_videos').count(CountOption.exact).eq('status', 'PUBLISHED');
    if (authorId != null) countQuery = countQuery.eq('author_id', authorId);
    if (categoryId != null) countQuery = countQuery.eq('category_id', categoryId);
    
    final countResponse = await countQuery;
    final int count = countResponse;

    // 2. Get Data
    dynamic dataQuery = _client
        .from('media_videos')
        .select('*, media_authors(*), media_categories(*)')
        .eq('status', 'PUBLISHED');

    if (authorId != null) dataQuery = dataQuery.eq('author_id', authorId);
    if (categoryId != null) dataQuery = dataQuery.eq('category_id', categoryId);

    if (page != null) {
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      dataQuery = dataQuery.range(from, to);
    }

    final dataResponse = await (dataQuery as PostgrestTransformBuilder)
        .order('published_at', ascending: false)
        .limit(limit);

    final videos = (dataResponse as List).map((e) => MediaVideo.fromJson(e)).toList();

    return (videos: videos, count: count);
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

  /// ADMIN: Update a video
  Future<void> updateVideo(String id, {
    String? title,
    String? description,
    String? authorId,
    String? categoryId,
    String? status,
    String? customSubtitleUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (authorId != null) updates['author_id'] = authorId.isEmpty ? null : authorId;
    if (categoryId != null) updates['category_id'] = categoryId.isEmpty ? null : categoryId;
    if (status != null) updates['status'] = status;
    if (customSubtitleUrl != null) updates['custom_subtitle_url'] = customSubtitleUrl;

    if (updates.isEmpty) return;

    await _client.from('media_videos').update(updates).eq('id', id);
  }

  /// ADMIN: Delete a video
  Future<void> deleteVideo(String id) async {
    await _client.from('media_videos').delete().eq('id', id);
  }

  /// ADMIN: Fetch ALL videos (including hidden ones) for management
  /// Returns a record with the list of videos and the total count.
  Future<({List<MediaVideo> videos, int count})> getAllVideos({int? page, int limit = 20}) async {
    // 1. Get Count
    final count = await _client.from('media_videos').count(CountOption.exact);

    // 2. Get Data
    dynamic dataQuery = _client
        .from('media_videos')
        .select('*, media_authors(*), media_categories(*)');

    if (page != null) {
      final from = (page - 1) * limit;
      final to = from + limit - 1;
      dataQuery = dataQuery.range(from, to);
    }

    final dataResponse = await (dataQuery as PostgrestTransformBuilder)
        .order('published_at', ascending: false)
        .limit(limit);
    
    final videos = (dataResponse as List).map((e) => MediaVideo.fromJson(e)).toList();

    return (videos: videos, count: count);
  }
}
