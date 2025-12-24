import 'package:flutter/foundation.dart';
import '../models/nafahat_article.dart';
import '../services/nafahat_service.dart';

/// Provider for managing Nafahat Articles state
class NafahatProvider with ChangeNotifier {
  final NafahatService _service = NafahatService();

  // Articles lists
  List<NafahatArticle> _allArticles = [];
  List<NafahatArticle> _featuredArticles = [];
  List<NafahatArticle> _latestArticles = [];
  List<NafahatArticle> _popularArticles = [];
  Map<ArticleCategory, List<NafahatArticle>> _articlesByCategory = {};

  // Current article
  NafahatArticle? _currentArticle;
  List<NafahatArticle> _relatedArticles = [];

  // Search & filter
  List<NafahatArticle> _searchResults = [];
  String _searchQuery = '';
  ArticleCategory? _selectedCategory;
  List<String> _selectedTags = [];

  // Liked articles
  Set<String> _likedArticleIds = {};

  // Loading states
  bool _isLoading = false;
  bool _isFeaturedLoading = false;
  bool _isSearching = false;

  // Error state
  String? _error;

  // Pagination
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;

  // Getters
  List<NafahatArticle> get allArticles => _allArticles;
  List<NafahatArticle> get featuredArticles => _featuredArticles;
  List<NafahatArticle> get latestArticles => _latestArticles;
  List<NafahatArticle> get popularArticles => _popularArticles;
  Map<ArticleCategory, List<NafahatArticle>> get articlesByCategory =>
      _articlesByCategory;
  NafahatArticle? get currentArticle => _currentArticle;
  List<NafahatArticle> get relatedArticles => _relatedArticles;
  List<NafahatArticle> get searchResults => _searchResults;
  String get searchQuery => _searchQuery;
  ArticleCategory? get selectedCategory => _selectedCategory;
  List<String> get selectedTags => _selectedTags;
  Set<String> get likedArticleIds => _likedArticleIds;
  bool get isLoading => _isLoading;
  bool get isFeaturedLoading => _isFeaturedLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// Initialize - fetch featured and latest articles
  Future<void> initialize() async {
    await Future.wait([
      fetchFeaturedArticles(),
      fetchLatestArticles(),
    ]);
  }

  /// Fetch all articles (with pagination)
  Future<void> fetchArticles({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 0;
      _allArticles = [];
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final articles = await _service.getArticles(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        category: _selectedCategory,
      );

      if (articles.length < _pageSize) {
        _hasMore = false;
      }

      if (refresh) {
        _allArticles = articles;
      } else {
        _allArticles.addAll(articles);
      }

      _currentPage++;
    } catch (e) {
      _error = 'Erreur de chargement des articles: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch featured articles
  Future<void> fetchFeaturedArticles() async {
    try {
      _isFeaturedLoading = true;
      notifyListeners();

      _featuredArticles = await _service.getFeaturedArticles(limit: 5);
    } catch (e) {
      debugPrint('Error fetching featured articles: $e');
    } finally {
      _isFeaturedLoading = false;
      notifyListeners();
    }
  }

  /// Fetch latest articles
  Future<void> fetchLatestArticles() async {
    try {
      _latestArticles = await _service.getLatestArticles(limit: 10);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching latest articles: $e');
    }
  }

  /// Fetch popular articles
  Future<void> fetchPopularArticles() async {
    try {
      _popularArticles = await _service.getPopularArticles(limit: 10);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching popular articles: $e');
    }
  }

  /// Fetch articles by category
  Future<void> fetchArticlesByCategory(ArticleCategory category) async {
    if (_articlesByCategory.containsKey(category)) {
      return; // Already cached
    }

    try {
      final articles = await _service.getArticlesByCategory(category);
      _articlesByCategory[category] = articles;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching articles by category: $e');
    }
  }

  /// Set current article and fetch related
  Future<void> setCurrentArticle(NafahatArticle article) async {
    _currentArticle = article;
    notifyListeners();

    // Increment view count (async, no await)
    _service.incrementViewCount(article.id);

    // Fetch related articles
    await fetchRelatedArticles(article);
  }

  /// Fetch current article by ID
  Future<void> fetchArticleById(String id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final article = await _service.getArticleById(id);

      if (article != null) {
        await setCurrentArticle(article);
      } else {
        _error = 'Article non trouvé';
      }
    } catch (e) {
      _error = 'Erreur de chargement de l\'article: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch related articles
  Future<void> fetchRelatedArticles(NafahatArticle article) async {
    try {
      _relatedArticles = await _service.getRelatedArticles(article);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching related articles: $e');
    }
  }

  /// Search articles
  Future<void> searchArticles(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchQuery = '';
      notifyListeners();
      return;
    }

    try {
      _isSearching = true;
      _searchQuery = query;
      notifyListeners();

      _searchResults = await _service.searchArticles(query);
    } catch (e) {
      debugPrint('Error searching articles: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear search
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    notifyListeners();
  }

  /// Set category filter
  void setCategory(ArticleCategory? category) {
    _selectedCategory = category;
    _currentPage = 0;
    _allArticles = [];
    _hasMore = true;
    fetchArticles(refresh: true);
  }

  /// Add tag filter
  void addTag(String tag) {
    if (!_selectedTags.contains(tag)) {
      _selectedTags.add(tag);
      notifyListeners();
    }
  }

  /// Remove tag filter
  void removeTag(String tag) {
    _selectedTags.remove(tag);
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _selectedCategory = null;
    _selectedTags = [];
    _currentPage = 0;
    _allArticles = [];
    _hasMore = true;
    fetchArticles(refresh: true);
  }

  /// Like/Unlike article
  Future<void> toggleLike(String articleId, String userId) async {
    try {
      final isLiked = await _service.likeArticle(articleId, userId);

      if (isLiked) {
        _likedArticleIds.add(articleId);
      } else {
        _likedArticleIds.remove(articleId);
      }

      // Update article in lists
      _updateArticleLikeCount(articleId, isLiked);

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  /// Check if article is liked by user
  Future<void> checkLikeStatus(String articleId, String userId) async {
    try {
      final isLiked = await _service.hasUserLiked(articleId, userId);

      if (isLiked) {
        _likedArticleIds.add(articleId);
      } else {
        _likedArticleIds.remove(articleId);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error checking like status: $e');
    }
  }

  /// Share article
  Future<void> shareArticle(String articleId) async {
    try {
      await _service.incrementShareCount(articleId);

      // Update article in lists
      _updateArticleShareCount(articleId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error sharing article: $e');
    }
  }

  /// Helper: Update article like count in all lists
  void _updateArticleLikeCount(String articleId, bool increment) {
    void updateList(List<NafahatArticle> list) {
      final index = list.indexWhere((a) => a.id == articleId);
      if (index != -1) {
        list[index] = increment
            ? list[index].incrementLikes()
            : list[index].decrementLikes();
      }
    }

    updateList(_allArticles);
    updateList(_featuredArticles);
    updateList(_latestArticles);
    updateList(_popularArticles);
    updateList(_searchResults);
    updateList(_relatedArticles);

    if (_currentArticle?.id == articleId) {
      _currentArticle = increment
          ? _currentArticle!.incrementLikes()
          : _currentArticle!.decrementLikes();
    }
  }

  /// Helper: Update article share count in all lists
  void _updateArticleShareCount(String articleId) {
    void updateList(List<NafahatArticle> list) {
      final index = list.indexWhere((a) => a.id == articleId);
      if (index != -1) {
        list[index] = list[index].incrementShares();
      }
    }

    updateList(_allArticles);
    updateList(_featuredArticles);
    updateList(_latestArticles);
    updateList(_popularArticles);
    updateList(_searchResults);
    updateList(_relatedArticles);

    if (_currentArticle?.id == articleId) {
      _currentArticle = _currentArticle!.incrementShares();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      fetchArticles(refresh: true),
      fetchFeaturedArticles(),
      fetchLatestArticles(),
    ]);
  }

  /// Clear all data
  void clear() {
    _allArticles = [];
    _featuredArticles = [];
    _latestArticles = [];
    _popularArticles = [];
    _articlesByCategory = {};
    _currentArticle = null;
    _relatedArticles = [];
    _searchResults = [];
    _searchQuery = '';
    _selectedCategory = null;
    _selectedTags = [];
    _likedArticleIds = {};
    _currentPage = 0;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}
