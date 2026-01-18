
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/teaching.dart';
import '../models/article.dart';
import '../models/category.dart';
import '../models/category.dart';
import '../models/author.dart';
import '../models/podcast_show.dart';
import '../models/transcript_segment.dart';
import '../../../services/supabase_service.dart';

class TeachingService {
  TeachingService._();
  static final TeachingService instance = TeachingService._();

  final SupabaseClient _client = SupabaseService.client;

  // --- Authors ---
  Future<List<Author>> getAuthors() async {
    final response = await _client
        .from('authors')
        .select()
        .order('name', ascending: true);
    return (response as List).map((e) => Author.fromJson(e)).toList();
  }

  Future<void> createAuthor(Author author) async {
    await _client.from('authors').insert({
      'name': author.name,
      'bio': author.bio,
      'image_url': author.imageUrl,
    });
  }

  Future<void> updateAuthor(Author author) async {
    await _client.from('authors').update({
      'name': author.name,
      'bio': author.bio,
      'image_url': author.imageUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', author.id);
  }

  Future<void> deleteAuthor(String authorId) async {
    await _client.from('authors').delete().eq('id', authorId);
  }

  // --- Categories ---
  Future<List<Category>> getCategories() async {
    final response = await _client
        .from('categories')
        .select()
        .order('name_fr', ascending: true);
    return (response as List).map((e) => Category.fromJson(e)).toList();
  }

  // --- Teachings (Video/Audio) ---
  Future<List<Teaching>> getTeachings({
    String? categoryId,
    TeachingType? type,
    bool featuredOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client.from('teachings').select('*, authors(*), categories(*)');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (type != null) {
      query = query.eq('type', type.name);
    }
    if (featuredOnly) {
      query = query.eq('is_featured', true);
    }

    final response = await query
        .order('published_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => Teaching.fromJson(e)).toList();
  }

  // --- Podcast Shows ---
  Future<List<PodcastShow>> getPodcastShows() async {
    final response = await _client
        .from('podcast_shows')
        .select('*, authors(*), categories(*)'); // Fetch full data
    
    return (response as List).map((e) => PodcastShow.fromJson(e)).toList();
  }

  Future<void> createPodcastShow(PodcastShow show) async {
    await _client.from('podcast_shows').insert({
      'title_fr': show.titleFr,
      'title_ar': show.titleAr,
      'description_fr': show.descriptionFr,
      'description_ar': show.descriptionAr,
      'image_url': show.imageUrl,
      'author_id': show.authorId,
      'category_id': show.categoryId,
    });
  }

  Future<void> updatePodcastShow(PodcastShow show) async {
    await _client.from('podcast_shows').update({
      'title_fr': show.titleFr,
      'title_ar': show.titleAr,
      'description_fr': show.descriptionFr,
      'description_ar': show.descriptionAr,
      'image_url': show.imageUrl,
      'author_id': show.authorId,
      'category_id': show.categoryId,
    }).eq('id', show.id);
  }

  Future<void> deletePodcastShow(String showId) async {
    await _client.from('podcast_shows').delete().eq('id', showId);
  }

  Future<void> linkEpisodeToShow(String teachingId, String? showId) async {
    await _client.from('teachings').update({
      'podcast_show_id': showId,
    }).eq('id', teachingId);
  }

  Future<List<Teaching>> getShowEpisodes(String showId) async {
    final response = await _client
        .from('teachings')
        .select('*, authors(*), categories(*)')
        .eq('podcast_show_id', showId)
        .eq('type', 'AUDIO')
        .order('published_at', ascending: false);
    
    return (response as List).map((e) => Teaching.fromJson(e)).toList();
  }

  // --- Articles ---
  Future<List<Article>> getArticles({
    String? categoryId,
    bool featuredOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _client.from('articles').select('*, authors(*), categories(*)');

    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    if (featuredOnly) {
      query = query.eq('is_featured', true);
    }

    final response = await query
        .order('published_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => Article.fromJson(e)).toList();
  }

  // --- User Interactions (Favorites) ---
  Future<bool> toggleFavorite({
    required String userId,
    required String itemId,
    required String itemType, // 'TEACHING' or 'ARTICLE'
  }) async {
    final exists = await _client
        .from('user_interactions')
        .select()
        .eq('user_id', userId)
        .eq('item_id', itemId)
        .eq('item_type', itemType)
        .maybeSingle();

    if (exists != null) {
      // Toggle
      final currentStatus = exists['is_favorite'] as bool;
      await _client.from('user_interactions').update({
        'is_favorite': !currentStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).match({
          'user_id': userId,
          'item_id': itemId, 
          'item_type': itemType
      });
      return !currentStatus;
    } else {
      // Insert
      await _client.from('user_interactions').insert({
        'user_id': userId,
        'item_id': itemId,
        'item_type': itemType,
        'is_favorite': true,
      });
      return true;
    }
  }

  Future<List<String>> getFavoriteIds(String userId, String itemType) async {
    final response = await _client
        .from('user_interactions')
        .select('item_id')
        .eq('user_id', userId)
        .eq('item_type', itemType)
        .eq('is_favorite', true);
    return (response as List).map((e) => e['item_id'] as String).toList();
  }

  Future<bool> checkFavoriteStatus(String userId, String itemId, String itemType) async {
    final response = await _client
        .from('user_interactions')
        .select('is_favorite')
        .eq('user_id', userId)
        .eq('item_id', itemId)
        .eq('item_type', itemType)
        .maybeSingle();
    
    return response != null && (response['is_favorite'] as bool);
  }

  // --- Search ---
  Future<Map<String, dynamic>> searchContent(String query) async {
    if (query.isEmpty) return {'teachings': <Teaching>[], 'articles': <Article>[]};

    // Note: This relies on the gin indexes created in the migration
    // We search both French and Arabic titles/descriptions
    // Since Supabase textSearch is single-column driven, using 'or' with ilike is a simple alternative
    // for multi-column search without complex RPC, but FTS is better. 
    // For now, let's use a simple ilike approach for MVP or basic textSearch if configured.
    // Ideally, we'd use an RPC for cross-table search or complex OR logic.
    // Let's implement a simple client-side filtration for now or multiple queries.
    
    // Better approach: RPC 'search_content' (we didn't create it yet, but relying on ilike is safer without RPC)
    
    // Search Podcast Shows
    final showsResponse = await _client
        .from('podcast_shows')
        .select('*, authors(*), categories(*)')
        .or('title_fr.ilike.%$query%, description_fr.ilike.%$query%') // Include description
        .limit(5);

    // Search Teachings
    final teachingsResponse = await _client
        .from('teachings')
        .select('*, authors(*), categories(*)')
        .or('title_fr.ilike.%$query%, title_ar.ilike.%$query%, description_fr.ilike.%$query%')
        .limit(10);
        
    // Search Articles
    final articlesResponse = await _client
        .from('articles')
        .select('*, authors(*), categories(*)')
        .or('title_fr.ilike.%$query%, title_ar.ilike.%$query%')
        .limit(10);

    return {
      'shows': (showsResponse as List).map((e) => PodcastShow.fromJson(e)).toList(),
      'teachings': (teachingsResponse as List).map((e) => Teaching.fromJson(e)).toList(),
      'articles': (articlesResponse as List).map((e) => Article.fromJson(e)).toList(),
    };
  }

  // --- Views ---
  Future<void> incrementViews(String id, String table) async {
    // table should be 'teachings' or 'articles'
    // Uses RPC is atomic, but for simple increment we can just use an RPC if available, 
    // or ignore race conditions for simple view counts for now.
    // Let's assuming we might want an RPC for this later. 
    // For now, let's try to update if we have an RPC, otherwise skip to avoid massive calls.
    // We can define a simple RPC later.
  }
  // --- Transcripts ---
  Future<List<TranscriptSegment>> getTranscript(String teachingId) async {
    final response = await _client
        .from('transcripts')
        .select('content')
        .eq('teaching_id', teachingId)
        .maybeSingle();

    if (response == null || response['content'] == null) {
      return [];
    }

    final List<dynamic> jsonList = response['content'];
    return jsonList.map((e) => TranscriptSegment.fromJson(e)).toList();
  }

  Future<void> saveTranscript(String teachingId, List<TranscriptSegment> segments) async {
    final segmentsJson = segments.map((e) => e.toJson()).toList();
    
    final existing = await _client.from('transcripts').select('id').eq('teaching_id', teachingId).maybeSingle();
    
    if (existing != null) {
      await _client.from('transcripts').update({
        'content': segmentsJson,
        'language': 'fr'
      }).eq('teaching_id', teachingId);
    } else {
      await _client.from('transcripts').insert({
        'teaching_id': teachingId,
        'content': segmentsJson,
        'language': 'fr'
      });
    }
  }

  Future<String> createPodcastEpisode(Teaching teaching) async {
     final response = await _client.from('teachings').insert({
       'type': 'AUDIO',
       'title_fr': teaching.titleFr,
       'title_ar': teaching.titleAr,
       'description_fr': teaching.descriptionFr,
       'author_id': teaching.authorId,
       'category_id': teaching.categoryId,
       'podcast_show_id': teaching.podcastShowId,
       'media_url': teaching.mediaUrl,
       'duration_seconds': teaching.durationSeconds,
       'published_at': DateTime.now().toIso8601String(),
     }).select().single();
     
     return response['id'];
  }

  Future<void> updatePodcastEpisode(Teaching teaching) async {
     await _client.from('teachings').update({
       'title_fr': teaching.titleFr,
       'title_ar': teaching.titleAr,
       'description_fr': teaching.descriptionFr,
       'author_id': teaching.authorId,
       'category_id': teaching.categoryId,
       'podcast_show_id': teaching.podcastShowId,
       // Media URL might not change, but let's allow it if re-uploaded
       'media_url': teaching.mediaUrl, 
       // Duration might change content changed
       'duration_seconds': teaching.durationSeconds,
       'updated_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
     }).eq('id', teaching.id);
  }

  // --- Video Management ---

  Future<void> createVideoTeaching(Teaching teaching) async {
    // Determine thumbnail from YouTube URL if not provided
    String? thumbUrl = teaching.thumbnailUrl;
    if ((thumbUrl == null || thumbUrl.isEmpty) && teaching.mediaUrl.contains('youtube.com') || teaching.mediaUrl.contains('youtu.be')) {
      // Basic extraction
       try {
         final videoId = _extractYoutubeId(teaching.mediaUrl);
         if (videoId != null) {
           thumbUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
         }
       } catch (e) {
         print("Error extracting thumbnail: $e");
       }
    }

    await _client.from('teachings').insert({
      'type': 'VIDEO',
      'title_fr': teaching.titleFr,
      'title_ar': teaching.titleAr,
      'description_fr': teaching.descriptionFr,
      'author_id': teaching.authorId,
      'category_id': teaching.categoryId,
      'media_url': teaching.mediaUrl, // YouTube URL
      'thumbnail_url': thumbUrl,
      'published_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateVideoTeaching(Teaching teaching) async {
     String? thumbUrl = teaching.thumbnailUrl;
      if ((thumbUrl == null || thumbUrl.isEmpty) && (teaching.mediaUrl.contains('youtube.com') || teaching.mediaUrl.contains('youtu.be'))) {
       try {
         final videoId = _extractYoutubeId(teaching.mediaUrl);
         if (videoId != null) {
           thumbUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
         }
       } catch (e) { print("Error extracting thumbnail: $e"); }
    }

    await _client.from('teachings').update({
      'title_fr': teaching.titleFr,
      'title_ar': teaching.titleAr,
      'description_fr': teaching.descriptionFr,
      'author_id': teaching.authorId,
      'category_id': teaching.categoryId,
      'media_url': teaching.mediaUrl,
      'thumbnail_url': thumbUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', teaching.id);
  }

  Future<void> deleteTeaching(String id) async {
    await _client.from('teachings').delete().eq('id', id);
  }

  String? _extractYoutubeId(String url) {
    if (url.contains('youtu.be/')) {
      return url.split('youtu.be/')[1].split('?')[0];
    }
    if (url.contains('v=')) {
      return url.split('v=')[1].split('&')[0];
    }
    return null;
  }
}
