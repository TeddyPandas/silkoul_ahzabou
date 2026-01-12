import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';

/// Service d'authentification unifié utilisant UNIQUEMENT Supabase Auth
///
/// Tous les types d'authentification (Email, Google, Phone) passent par Supabase.
/// Le backend Node.js vérifie ensuite les tokens JWT générés par Supabase.
class AuthService {
  final SupabaseClient _supabase = SupabaseService.client;

  /// ════════════════════════════════════════════════════════════════════════
  /// INSCRIPTION PAR EMAIL
  /// ════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // 1. Créer l'utilisateur dans Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
        },
      );

      // 2. Le profil est créé automatiquement par le trigger Supabase (handle_new_user)
      // On ne l'appelle plus manuellement pour éviter les conflits RLS / Duplication
      /*
      if (response.user != null) {
        await _createProfile(
          userId: response.user!.id,
          email: email,
          displayName: displayName,
        );
      }
      */

      return {
        'user': response.user,
        'session': response.session,
      };
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// CONNEXION PAR EMAIL
  /// ════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return {
        'user': response.user,
        'session': response.session,
      };
    } catch (e) {
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// CONNEXION AVEC GOOGLE (OAuth)
  /// ════════════════════════════════════════════════════════════════════════
  Future<bool> signInWithGoogle() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseConfig.redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      // Note: Le profil sera créé automatiquement lors du callback OAuth
      // via le trigger Supabase ou dans le AuthProvider
      return response;
    } catch (e) {
      throw Exception('Erreur lors de la connexion Google: $e');
    }
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// CONNEXION PAR TÉLÉPHONE (OTP)
  /// ════════════════════════════════════════════════════════════════════════
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

  /// ════════════════════════════════════════════════════════════════════════
  /// RÉINITIALISATION DU MOT DE PASSE
  /// ════════════════════════════════════════════════════════════════════════
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Erreur lors de la réinitialisation: $e');
    }
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// DÉCONNEXION
  /// ════════════════════════════════════════════════════════════════════════
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  /// ════════════════════════════════════════════════════════════════════════
  /// GESTION DU PROFIL
  /// ════════════════════════════════════════════════════════════════════════

  /// Créer un profil utilisateur dans la table profiles
  Future<void> _createProfile({
    required String userId,
    required String email,
    required String displayName,
    String? phone,
  }) async {
    try {
      final now = DateTime.now();
      await _supabase.from(SupabaseConfig.profilesTable).upsert({
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
