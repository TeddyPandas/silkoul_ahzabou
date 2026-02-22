import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quiz_models.dart';

class QuizService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch all available quizzes
  Future<List<Quiz>> fetchQuizzes() async {
    try {
      final response = await _client
          .from('quizzes')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => Quiz.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching quizzes: $e');
      rethrow;
    }
  }

  /// Fetch quizzes that the user has already completed
  Future<List<String>> fetchUserCompletedQuizzes() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('user_quiz_attempts')
          .select('quiz_id')
          .eq('user_id', user.id);

      return (response as List).map((json) => json['quiz_id'].toString()).toSet().toList(); // Use toSet() to remove duplicates if any
    } catch (e) {
      debugPrint('Error fetching completed quizzes: $e');
      return []; // Return empty list on failure rather than breaking the menu
    }
  }

  /// Fetch questions for a specific quiz, including multiple choice answers
  Future<List<Question>> fetchQuizQuestions(String quizId) async {
    try {
      final response = await _client
          .from('questions')
          .select('*, answers(*)')
          .eq('quiz_id', quizId);

      return (response as List).map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching questions for quiz $quizId: $e');
      rethrow;
    }
  }

  /// Submit a quiz attempt result and earn XP
  Future<Map<String, dynamic>> submitQuizAttempt({
    required String quizId,
    required int score,
    required int totalQuestions,
    required int xpEarned,
  }) async {
    try {
      final response = await _client.rpc('submit_quiz_attempt', params: {
        'p_quiz_id': quizId,
        'p_score': score,
        'p_total_questions': totalQuestions,
        'p_xp_earned': xpEarned,
      });

      return response as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error submitting quiz attempt: $e');
      rethrow;
    }
  }

  /// Get the current leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final response = await _client
          .from('leaderboard')
          .select()
          .order('total_xp', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      rethrow;
    }
  }
}
