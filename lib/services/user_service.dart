import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class UserService {
  final SupabaseClient _supabase = SupabaseService.client;
  static const String _baseUrl = 'http://localhost:3000/api';

  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
  }) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final url = Uri.parse('$_baseUrl/users/$userId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    try {
      final response =
          await http.put(url, headers: headers, body: json.encode(updates));

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors de la mise à jour du profil utilisateur: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    final url = Uri.parse('$_baseUrl/users');
    final headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(responseData['data']);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs: $e');
    }
  }
}
