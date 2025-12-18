import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  Profile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initAuthListener();
  }

  /// Initialiser le listener d'état d'authentification
  void _initAuthListener() {
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn) {
        _user = session?.user;
        _loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        _user = null;
        _profile = null;
        notifyListeners();
      }
    });

    // Charger l'utilisateur actuel si déjà connecté
    _user = SupabaseService.client.auth.currentUser;
    if (_user != null) {
      _loadProfile();
    }
  }

  /// Charger le profil de l'utilisateur
  Future<void> _loadProfile() async {
    try {
      _profile = await _authService.getCurrentProfile();
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement du profil: $e');
    }
  }

  /// Inscription par email
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final responseData = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );

      final session = responseData['session'];
      if (session != null) {
        // This triggers the onAuthStateChange listener which handles the rest
        await SupabaseService.client.auth.recoverSession(jsonEncode(session));
      } else {
        // Handle cases where email confirmation might be needed
        _errorMessage =
            "Inscription réussie. Veuillez vérifier vos emails pour confirmer votre compte.";
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Connexion par email
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final responseData = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      final session = responseData['session'];
      if (session != null) {
        // This triggers the onAuthStateChange listener which handles the rest
        await SupabaseService.client.auth.recoverSession(jsonEncode(session));
      } else {
        throw Exception("Les données de session sont manquantes.");
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Connexion avec Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final success = await _authService.signInWithGoogle();

      if (success) {
        await _loadProfile();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _profile = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Mettre à jour le profil
  Future<bool> updateProfile({
    String? displayName,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    String? silsilaId,
    String? avatarUrl,
  }) async {
    if (_user == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      await _authService.updateProfile(
        userId: _user!.id,
        displayName: displayName,
        phone: phone,
        address: address,
        dateOfBirth: dateOfBirth,
        silsilaId: silsilaId,
        avatarUrl: avatarUrl,
      );

      await _loadProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Effacer le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
