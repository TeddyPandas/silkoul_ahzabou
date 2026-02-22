import 'package:flutter/material.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';
import '../../admin/services/admin_quiz_service.dart';
import '../../../utils/error_handler.dart';

class QuizProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();
  final AdminQuizService _adminService = AdminQuizService();

  List<Quiz> _quizzes = [];
  List<Quiz> get quizzes => _quizzes;

  List<Map<String, dynamic>> _leaderboard = [];
  List<Map<String, dynamic>> get leaderboard => _leaderboard;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<String> _completedQuizIds = [];
  List<String> get completedQuizIds => _completedQuizIds;

  /// Load all available quizzes and user completion status
  Future<void> loadQuizzes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _quizzes = await _quizService.fetchQuizzes();
      _completedQuizIds = await _quizService.fetchUserCompletedQuizzes();
    } catch (e) {
      _error = ErrorHandler.sanitize(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- ADMIN OPERATIONS ---

  Future<void> createQuiz(Map<String, dynamic> data) async {
    try {
      final newQuiz = await _adminService.createQuiz(data);
      _quizzes.insert(0, newQuiz);
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.sanitize(e);
      rethrow;
    }
  }

  Future<void> updateQuiz(String id, Map<String, dynamic> data) async {
    try {
      final updatedQuiz = await _adminService.updateQuiz(id, data);
      final index = _quizzes.indexWhere((q) => q.id == id);
      if (index != -1) {
        _quizzes[index] = updatedQuiz;
        notifyListeners();
      }
    } catch (e) {
      _error = ErrorHandler.sanitize(e);
      rethrow;
    }
  }

  Future<void> deleteQuiz(String id) async {
    try {
      await _adminService.deleteQuiz(id);
      _quizzes.removeWhere((q) => q.id == id);
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.sanitize(e);
      rethrow;
    }
  }

  Future<void> addQuestion(String quizId, String text, String? explanation, List<Map<String, dynamic>> answers) async {
    try {
      await _adminService.addQuestionWithAnswers(quizId, text, explanation, answers);
      // No local state update for questions list yet, we'll reload when needed
    } catch (e) {
      _error = ErrorHandler.sanitize(e);
      rethrow;
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    try {
      await _adminService.deleteQuestion(questionId);
    } catch (e) {
      _error = ErrorHandler.sanitize(e);
      rethrow;
    }
  }

  // --- USER OPERATIONS ---

  /// Load current leaderboard
  Future<void> loadLeaderboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _leaderboard = await _quizService.getLeaderboard();
    } catch (e) {
      _error = ErrorHandler.sanitize(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get questions for a specific quiz
  Future<List<Question>> loadQuestions(String quizId) async {
    try {
      return await _quizService.fetchQuizQuestions(quizId);
    } catch (e) {
      _error = ErrorHandler.sanitize(e);
      rethrow;
    }
  }

  /// Submit a finished quiz result
  Future<void> submitResult({
    required String quizId,
    required int score,
    required int totalQuestions,
    required int xpEarned,
  }) async {
    try {
      await _quizService.submitQuizAttempt(
        quizId: quizId,
        score: score,
        totalQuestions: totalQuestions,
        xpEarned: xpEarned,
      );
      // Reload leaderboard after submission
      loadLeaderboard();
    } catch (e) {
      ErrorHandler.log('Error submitting quiz result: $e');
      rethrow;
    }
  }
}
