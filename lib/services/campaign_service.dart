import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/campaign.dart';
import '../models/task.dart';
import 'supabase_service.dart';

class CampaignService {
  final SupabaseClient _supabase = SupabaseService.client;
  // TODO: Externalize to environment configuration
  static const String _baseUrl = 'http://localhost:3000/api';

  /// Créer une nouvelle campagne avec ses tâches via le backend API
  Future<String> createCampaign({
    required String name,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    String? category,
    bool isPublic = true,
    String? accessCode,
    required List<Map<String, dynamic>> tasks,
    required String createdBy,
    required bool isWeekly,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final url = Uri.parse('$_baseUrl/campaigns');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // Assurer la correspondance avec le backend
    final tasksPayload = tasks
        .map((task) => {
              'name': task['name'],
              'total_number':
                  task['number'], // Le backend attend 'total_number'
              'daily_goal': task['daily_goal'],
            })
        .toList();

    final body = json.encode({
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'category': category,
      'is_public': isPublic,
      'access_code': accessCode,
      'tasks': tasksPayload,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        // Le backend retourne la campagne complète, on extrait l'ID
        return responseData['data']['id'] as String;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Erreur lors de la création de la campagne: $e');
    }
  }

  /// Obtenir toutes les campagnes publiques via le backend API
  Future<List<Campaign>> getPublicCampaigns({
    String? category,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (category != null && category.isNotEmpty) 'category': category,
      if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
    };

    final uri =
        Uri.parse('$_baseUrl/campaigns').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> campaignList = responseData['data'];
        return campaignList.map((json) => Campaign.fromJson(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des campagnes publiques: $e');
    }
  }

  /// Obtenir les campagnes d'un utilisateur (créées ou souscrites) via le backend API
  Future<List<Campaign>> getUserCampaigns({
    required String userId,
    bool onlyCreated = false,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final queryParams = {
      'type': onlyCreated ? 'created' : 'subscribed',
    };

    final uri = Uri.parse('$_baseUrl/campaigns/my')
        .replace(queryParameters: queryParams);
    final headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> campaignList = responseData['data'];
        return campaignList.map((json) => Campaign.fromJson(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des campagnes de l\'utilisateur: $e');
    }
  }

  /// Obtenir une campagne par son ID via le backend API
  Future<Campaign?> getCampaignById(String campaignId) async {
    final token = _supabase.auth.currentSession?.accessToken;
    final headers = {
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$_baseUrl/campaigns/$campaignId');

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Campaign.fromJson(responseData['data']);
      } else if (response.statusCode == 404) {
        return null; // Campagne non trouvée
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la campagne: $e');
    }
  }

  /// Obtenir les tâches d'une campagne en utilisant getCampaignById
  Future<List<Task>> getCampaignTasks(String campaignId) async {
    try {
      final campaign = await getCampaignById(campaignId);
      if (campaign == null) {
        throw Exception('Campagne non trouvée');
      }
      return campaign.tasks ?? [];
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des tâches de la campagne: $e');
    }
  }

  /// S'abonner à une campagne avec sélection de tâches via le backend API
  Future<void> subscribeToCampaign({
    required String campaignId,
    String? accessCode,
    required List<Map<String, dynamic>> taskSubscriptions,
    required String userId,
    required List<Map<String, dynamic>> selectedTasks,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final url = Uri.parse('$_baseUrl/tasks/subscribe');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = json.encode({
      'campaign_id': campaignId,
      'access_code': accessCode,
      'task_subscriptions': taskSubscriptions,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Erreur lors de la souscription à la campagne: $e');
    }
  }

  /// Vérifier si un utilisateur est abonné à une campagne via le backend API
  Future<bool> isUserSubscribed({
    required String userId,
    required String campaignId,
  }) async {
    try {
      final subscribedCampaigns =
          await getUserCampaigns(userId: userId, onlyCreated: false);
      return subscribedCampaigns.any((campaign) => campaign.id == campaignId);
    } catch (e) {
      // Log the error if necessary, but return false for subscription check failures
      return false;
    }
  }
}
