import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_task.dart';
import 'supabase_service.dart';

class TaskService {
  final SupabaseClient _supabase = SupabaseService.client;
  static const String _baseUrl = 'http://localhost:3000/api';

  /// Obtenir les tâches d'un utilisateur pour une campagne spécifique via le backend API
  Future<List<UserTask>> getUserTasksForCampaign({
    required String userId,
    required String campaignId,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final queryParams = {
      'campaign_id': campaignId,
    };

    final uri =
        Uri.parse('$_baseUrl/tasks').replace(queryParameters: queryParams);
    final headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> userTaskList = responseData['data'];
        return userTaskList.map((json) => UserTask.fromJson(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des tâches de l\'utilisateur pour la campagne: $e');
    }
  }

  /// Obtenir toutes les tâches d'un utilisateur (toutes campagnes) via le backend API
  Future<List<UserTask>> getAllUserTasks({
    required String userId,
    bool onlyIncomplete = false,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final queryParams = <String, String>{};
    if (onlyIncomplete) {
      queryParams['is_completed'] = 'false';
    }

    final uri =
        Uri.parse('$_baseUrl/tasks').replace(queryParameters: queryParams);
    final headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> userTaskList = responseData['data'];
        return userTaskList.map((json) => UserTask.fromJson(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération de toutes les tâches de l\'utilisateur: $e');
    }
  }

  /// Mettre à jour la progression d'une tâche via le backend API
  Future<void> updateTaskProgress({
    required String userTaskId,
    required int completedQuantity,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final url = Uri.parse('$_baseUrl/tasks/$userTaskId/progress');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = json.encode({
      'completed_quantity': completedQuantity,
    });

    try {
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors de la mise à jour de la progression de la tâche: $e');
    }
  }

  /// Marquer une tâche comme complétée via le backend API
  Future<void> markTaskAsCompleted({
    required String userTaskId,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final url = Uri.parse('$_baseUrl/tasks/$userTaskId/complete');
    final headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.put(url, headers: headers);

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors du marquage de la tâche comme complétée: $e');
    }
  }

  /// Démarquer une tâche complétée via le backend API (en mettant la quantité complétée à 0)
  Future<void> unmarkTaskAsCompleted({
    required String userTaskId,
  }) async {
    try {
      await updateTaskProgress(userTaskId: userTaskId, completedQuantity: 0);
    } catch (e) {
      throw Exception('Erreur lors du démarquage de la tâche: $e');
    }
  }

  /// Obtenir les statistiques des tâches d'un utilisateur via le backend API
  Future<Map<String, dynamic>> getUserTaskStats({
    required String userId,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final url = Uri.parse('$_baseUrl/tasks/stats');
    final headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Map<String, dynamic>.from(responseData['data']);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// Obtenir les tâches quotidiennes d'aujourd'hui
  Future<List<UserTask>> getTodayTasks({
    required String userId,
  }) async {
    try {
      // Obtenir toutes les tâches non complétées
      final tasks = await getAllUserTasks(
        userId: userId,
        onlyIncomplete: true,
      );

      // TODO: Implémenter la logique de tâches quotidiennes
      // Pour l'instant, retourner toutes les tâches en cours
      return tasks;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des tâches du jour: $e');
    }
  }
}
