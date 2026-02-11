import 'package:flutter/material.dart';
import '../models/media_models.dart';
import '../services/media_service.dart';

class MediaProvider with ChangeNotifier {
  final MediaService _service = MediaService();

  List<MediaAuthor> _authors = [];
  List<MediaCategory> _categories = [];
  List<MediaVideo> _featuredVideos = [];
  
  // Cache for category-specific video lists to avoid refetching
  final Map<String, List<MediaVideo>> _videosByCategory = {}; 
  // Cache for author-specific video lists
  final Map<String, List<MediaVideo>> _videosByAuthor = {};

  bool _isLoading = false;
  
  // Pagination management
  final List<MediaVideo> _allVideos = [];
  int _currentPage = 1;
  bool _hasMore = true;
  int _totalCount = 0;

  List<MediaAuthor> get authors => _authors;
  List<MediaCategory> get categories => _categories;
  MediaVideo? get featuredVideo => _featuredVideos.isNotEmpty ? _featuredVideos.first : null;
  bool get isLoading => _isLoading;
  List<MediaVideo> get allVideos => _allVideos;
  bool get hasMore => _hasMore;
  int get totalCount => _totalCount;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Parallel fetch
      final results = await Future.wait([
        _service.getAuthors(),
        _service.getCategories(),
        _service.getVideos(limit: 5), // For Hero/Featured
      ]);

      _authors = results[0] as List<MediaAuthor>;
      _categories = results[1] as List<MediaCategory>;
      _featuredVideos = (results[2] as ({List<MediaVideo> videos, int count})).videos;
      
      // Also fetch first page for "Recent Videos" list
      await fetchFirstPage();
    } catch (e) {
      debugPrint('❌ Error loading media data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get videos for a specific category (with caching)
  Future<List<MediaVideo>> getVideosForCategory(String categoryId) async {
    if (_videosByCategory.containsKey(categoryId)) {
      return _videosByCategory[categoryId]!;
    }

    final result = await _service.getVideos(categoryId: categoryId, limit: 12);
    _videosByCategory[categoryId] = result.videos;
    notifyListeners();
    return result.videos;
  }
  
  /// Get videos for a specific author (with caching)
  Future<List<MediaVideo>> getVideosForAuthor(String authorId) async {
    if (_videosByAuthor.containsKey(authorId)) {
      return _videosByAuthor[authorId]!;
    }

    final result = await _service.getVideos(authorId: authorId, limit: 12);
    _videosByAuthor[authorId] = result.videos;
    notifyListeners();
    return result.videos;
  }

  /// Reset and fetch first page of all videos
  Future<void> fetchFirstPage() async {
    _currentPage = 1;
    _allVideos.clear();
    _hasMore = true;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.getVideos(page: _currentPage, limit: 12);
      _allVideos.addAll(result.videos);
      _totalCount = result.count;
      _hasMore = _allVideos.length < _totalCount;
      _currentPage++;
    } catch (e) {
      debugPrint('❌ Error fetching first page: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch next page of all videos
  Future<void> fetchNextPage() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.getVideos(page: _currentPage, limit: 12);
      _allVideos.addAll(result.videos);
      _totalCount = result.count;
      _hasMore = _allVideos.length < _totalCount;
      _currentPage++;
    } catch (e) {
      debugPrint('❌ Error fetching next page: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // ADMIN METHODS
  // ===========================================================================

  Future<({List<MediaVideo> videos, int count})> getAllVideos({int? page, int limit = 20}) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _service.getAllVideos(page: page, limit: limit);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateVideo(String id, {
    String? title,
    String? description,
    String? authorId,
    String? categoryId,
    String? status,
    String? customSubtitleUrl,
  }) async {
    await _service.updateVideo(
      id,
      title: title,
      description: description,
      authorId: authorId,
      categoryId: categoryId,
      status: status,
      customSubtitleUrl: customSubtitleUrl,
    );
    // Invalidate caches to force refresh on next view
    _videosByCategory.clear();
    _videosByAuthor.clear();
    initialize(); // Refresh home widgets
  }

  Future<void> deleteVideo(String id) async {
    await _service.deleteVideo(id);
    _videosByCategory.clear();
    _videosByAuthor.clear();
    initialize();
  }
}
