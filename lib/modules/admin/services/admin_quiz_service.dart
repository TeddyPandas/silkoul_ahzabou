import 'package:supabase_flutter/supabase_flutter.dart';
import '../../quizzes/models/quiz_models.dart';

class AdminQuizService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Create a new quiz
  Future<Quiz> createQuiz(Map<String, dynamic> data) async {
    final response = await _client
        .from('quizzes')
        .insert(data)
        .select()
        .single();
    return Quiz.fromJson(response);
  }

  /// Update an existing quiz
  Future<Quiz> updateQuiz(String id, Map<String, dynamic> data) async {
    final response = await _client
        .from('quizzes')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Quiz.fromJson(response);
  }

  /// Delete a quiz
  Future<void> deleteQuiz(String id) async {
    await _client.from('quizzes').delete().eq('id', id);
  }

  /// Add a question with its answers to a quiz
  Future<void> addQuestionWithAnswers(
    String quizId,
    String questionText,
    String? explanation,
    List<Map<String, dynamic>> answers,
  ) async {
    // 1. Create the question
    final questionResponse = await _client
        .from('questions')
        .insert({
          'quiz_id': quizId,
          'question_text': questionText,
          'explanation': explanation,
        })
        .select()
        .single();

    final questionId = questionResponse['id'];

    // 2. Create the answers
    final answersData = answers.map((a) => {
      'question_id': questionId,
      'text': a['text'],
      'is_correct': a['is_correct'],
    }).toList();

    await _client.from('answers').insert(answersData);
  }

  /// Delete a question
  Future<void> deleteQuestion(String questionId) async {
    await _client.from('questions').delete().eq('id', questionId);
  }
}
