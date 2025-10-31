import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseService.client;
  final Dio _dio = Dio();
  final String? _apiBaseUrl = dotenv.env['API_BASE_URL'];

  AuthService() {
    if (_apiBaseUrl == null) {
      // This check is important for debugging.
      print("CRITICAL: API_BASE_URL not found in .env file. Make sure it's loaded.");
    }
  }

  /// Inscription par email et mot de passe via le backend Node.js
  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (_apiBaseUrl == null) throw Exception('API_BASE_URL is not configured');
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/auth/signup',
        data: {
          'email': email,
          'password': password,
          'display_name': displayName,
        },
      );
      return response.data;
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? e.message;
      throw Exception('Erreur lors de l\'inscription: $errorMessage');
    } catch (e) {
      throw Exception('Erreur inattendue lors de l\'inscription: $e');
    }
  }

  /// Connexion par email et mot de passe via le backend Node.js
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_apiBaseUrl == null) throw Exception('API_BASE_URL is not configured');
    try {
      final response = await _dio.post(
        '$_apiBaseUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return response.data;
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? e.message;
      throw Exception('Erreur lors de la connexion: $errorMessage');
    } catch (e) {
      throw Exception('Erreur inattendue lors de la connexion: $e');
    }
  }

  /// Connexion avec Google
  Future<bool> signInWithGoogle() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.redirectUrl,
      );
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la connexion Google: $e');
    }
  }

  /// Connexion par numéro de téléphone (OTP)
  Future<void> signInWithPhone({
    required String phoneNumber,
  }) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: phoneNumber,
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'OTP: $e');
    }
  }

  /// Vérifier l'OTP du téléphone
  Future<AuthResponse> verifyPhoneOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: phone,
        token: token,
      );

      // Créer le profil si c'est la première connexion
      if (response.user != null) {
        final existingProfile = await _getProfile(response.user!.id);
        if (existingProfile == null) {
          await _createProfile(
            userId: response.user!.id,
            email: response.user!.email ?? '',
            displayName: phone,
            phone: phone,
          );
        }
      }

      return response;
    } catch (e) {
      throw Exception('Erreur lors de la vérification de l\'OTP: $e');
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Erreur lors de la réinitialisation: $e');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  /// Créer un profil utilisateur
  Future<void> _createProfile({
    required String userId,
    required String email,
    required String displayName,
    String? phone,
  }) async {
    try {
      final now = DateTime.now();
      await _supabase.from(SupabaseConfig.profilesTable).insert({
        'id': userId,
        'email': email,
        'display_name': displayName,
        'phone': phone,
        'points': 0,
        'level': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la création du profil: $e');
    }
  }

  /// Obtenir le profil utilisateur
  Future<Profile?> _getProfile(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir le profil de l'utilisateur actuel
  Future<Profile?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return _getProfile(user.id);
  }

  /// Mettre à jour le profil
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    String? silsilaId,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (displayName != null) updates['display_name'] = displayName;
      if (phone != null) updates['phone'] = phone;
      if (address != null) updates['address'] = address;
      if (dateOfBirth != null) {
        updates['date_of_birth'] = dateOfBirth.toIso8601String();
      }
      if (silsilaId != null) updates['silsila_id'] = silsilaId;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await _supabase
          .from(SupabaseConfig.profilesTable)
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du profil: $e');
    }
  }
}
