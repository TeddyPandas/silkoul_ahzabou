
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/teaching.dart';
import '../models/article.dart';
import '../models/category.dart';
import '../models/podcast_show.dart';
import '../services/teaching_service.dart';

class TeachingsProvider with ChangeNotifier {
  final TeachingService _service = TeachingService.instance;

  // Data State
  List<Category> _categories = [];
  List<Teaching> _teachings = [];
  List<PodcastShow> _podcastShows = [];
  List<Article> _articles = [];
  
  bool _isLoading = false;
  String? _selectedCategoryId;
  TeachingType? _filterType;

  // Audio Player State
  final AudioPlayer _audioPlayer = AudioPlayer();
  Teaching? _currentTeaching;
  bool _isAudioPlaying = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  // Getters
  List<Category> get categories => _categories;
  List<Teaching> get teachings => _teachings;
  List<PodcastShow> get podcastShows => _podcastShows; // NEW
  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;
  String? get selectedCategoryId => _selectedCategoryId;
  
  // Audio Getters
  Teaching? get currentTeaching => _currentTeaching;
  bool get isAudioPlaying => _isAudioPlaying;
  Duration get audioPosition => _audioPosition;
  Duration get audioDuration => _audioDuration;
  AudioPlayer get audioPlayer => _audioPlayer;
  
  Set<String> _favoriteIds = {};
  bool isFavorite(String id) => _favoriteIds.contains(id);

  TeachingsProvider() {
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _audioPlayer.positionStream.listen((p) {
      _audioPosition = p;
      notifyListeners();
    });
    
    _audioPlayer.durationStream.listen((d) {
      _audioDuration = d ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.playerStateStream.listen((state) {
      _isAudioPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
         _isAudioPlaying = false;
         _audioPosition = Duration.zero;
      }
      notifyListeners();
    });
  }

  // --- Data Methods ---

  Future<void> loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _service.getCategories();
      await fetchTeachings();
      await fetchTeachings();
      await fetchPodcastShows();
      await fetchArticles();
      await _loadFavorites();
    } catch (e) {
      debugPrint("Error loading initial data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTeachings() async {
    try {
      _teachings = await _service.getTeachings(
        categoryId: _selectedCategoryId,
        type: _filterType,
      );
    } catch (e) {
      debugPrint("Error fetching teachings: $e");
    }
    notifyListeners();
  }

  Future<void> fetchArticles() async {
    try {
      _articles = await _service.getArticles(
        categoryId: _selectedCategoryId,
      );
    } catch (e) {
      debugPrint("Error fetching articles: $e");
    }
    notifyListeners();
  }

  Future<void> createArticle(Article article) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.createArticle(article);
      await fetchArticles();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateArticle(Article article) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.updateArticle(article);
      await fetchArticles();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteArticle(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.deleteArticle(id);
      await fetchArticles();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPodcastShows() async {
    try {
      _podcastShows = await _service.getPodcastShows();
    } catch (e) {
      debugPrint("Error fetching podcast shows: $e");
    }
    notifyListeners();
  }

  void setCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    _isLoading = true;
    notifyListeners();
    
    Future.wait([
      fetchTeachings(),
      fetchArticles(),
      _loadFavorites(),
    ]).then((_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> _loadFavorites() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    if (userId != null && userId.isNotEmpty) {
      try {
        final favs = await _service.getFavoriteIds(userId, 'TEACHING'); // Only Teachings for now
        _favoriteIds = favs.toSet();
        notifyListeners();
      } catch (e) {
        debugPrint("Error loading favorites: $e");
      }
    }
  }

  Future<void> toggleFavorite(Teaching item) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    
    final isFav = _favoriteIds.contains(item.id);
    
    // Optimistic Update
    if (isFav) {
      _favoriteIds.remove(item.id);
    } else {
      _favoriteIds.add(item.id);
    }
    notifyListeners();

    try {
      await _service.toggleFavorite(
        userId: userId, 
        itemId: item.id, 
        itemType: 'TEACHING'
      );
    } catch (e) {
      // Revert if error
      if (isFav) {
        _favoriteIds.add(item.id);
      } else {
        _favoriteIds.remove(item.id);
      }
      notifyListeners();
      debugPrint("Error toggling favorite: $e");
    }
  }

  // --- Audio Control Methods ---

  Future<void> playAudio(Teaching teaching) async {
    // If playing same audio, just toggle/resume
    if (_currentTeaching?.id == teaching.id) {
       if (!_isAudioPlaying) {
         _audioPlayer.play();
       }
       return;
    }

    // New audio
    try {
      _currentTeaching = teaching;
      // Configure session for background
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      await _audioPlayer.setUrl(teaching.mediaUrl);
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing audio: $e");
      _currentTeaching = null;
    }
    notifyListeners();
  }

  void pauseAudio() {
    _audioPlayer.pause();
  }

  void resumeAudio() {
    _audioPlayer.play();
  }

  void seekAudio(Duration position) {
    _audioPlayer.seek(position);
  }

  void stopAudio() {
    _audioPlayer.stop();
    _currentTeaching = null;
    notifyListeners();
  }

  // Speed Control
  double get playbackSpeed => _audioPlayer.speed;

  Future<void> setPlaybackSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
