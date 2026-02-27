import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../utils/error_handler.dart';

const String _kGuestModeKey = 'is_guest_mode';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  Profile? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGuest = false;

  User? get user => _user;
  Profile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get isGuest => _isGuest;

  // Role Check Helpers
  bool get isAdmin => _profile?.role == 'ADMIN' || _profile?.role == 'SUPER_ADMIN';
  bool get isSuperAdmin => _profile?.role == 'SUPER_ADMIN';

  AuthProvider() {
    _initAuthListener();
  }

  /// Initialiser le listener d'état d'authentification
  void _initAuthListener() {
    ErrorHandler.log('🔐 [AuthProvider] Initializing auth listener...');

    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      ErrorHandler.log('🔐 [AuthProvider] ======= AUTH EVENT RECEIVED =======');
      ErrorHandler.log('🔐 [AuthProvider] Event: $event');
      ErrorHandler.log('🔐 [AuthProvider] Session exists: ${session != null}');
      ErrorHandler.log('🔐 [AuthProvider] ===================================');

      if (event == AuthChangeEvent.signedIn) {
        ErrorHandler.log('🔐 [AuthProvider] ✅ User signed in! Updating state...');
        _user = session?.user;
        if (kDebugMode && kIsWeb) {
          print('🔐 [AuthProvider] Web Session: ${session?.accessToken.substring(0, 10)}...');
          print('🔐 [AuthProvider] Web User: ${_user?.id}');
        }
        _isGuest = false;
        SharedPreferences.getInstance()
            .then((p) => p.remove(_kGuestModeKey));
        _loadProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        ErrorHandler.log('🔐 [AuthProvider] User signed out');
        _user = null;
        _profile = null;
        _isGuest = false;
        SharedPreferences.getInstance()
            .then((p) => p.remove(_kGuestModeKey));
        notifyListeners();
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        ErrorHandler.log('🔐 [AuthProvider] Token refreshed');
        _user = session?.user;
        notifyListeners();
      } else if (event == AuthChangeEvent.initialSession) {
        ErrorHandler.log('🔐 [AuthProvider] Initial session event');
        _user = session?.user;
        if (_user != null) {
          _isGuest = false;
          _loadProfile();
        } else {
          // Restore guest mode if user previously chose it
          SharedPreferences.getInstance().then((p) {
            _isGuest = p.getBool(_kGuestModeKey) ?? false;
            notifyListeners();
          });
        }
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
      ErrorHandler.log('Erreur lors du chargement du profil: $e');
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
      _errorMessage = ErrorHandler.sanitize(e);
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
      _errorMessage = ErrorHandler.sanitize(e);
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
      _errorMessage = ErrorHandler.sanitize(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Entrer en mode invité (sans compte)
  Future<void> enterGuestMode() async {
    _isGuest = true;
    _user = null;
    _profile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kGuestModeKey, true);
    notifyListeners();
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _profile = null;
      _isGuest = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kGuestModeKey);
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.sanitize(e);
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
      _errorMessage = ErrorHandler.sanitize(e);
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
