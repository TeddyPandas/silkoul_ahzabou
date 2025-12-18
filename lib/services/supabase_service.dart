import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
          'Supabase client not initialized. Call initialize() first.');
    }
    return _client!;
  }

  @visibleForTesting
  static set client(SupabaseClient client) {
    _client = client;
  }

  /// Initialiser Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      debug: true, // Enable debug logging for OAuth troubleshooting
    );
    _client = Supabase.instance.client;
  }

  /// Obtenir l'utilisateur actuel
  User? get currentUser => _client?.auth.currentUser;

  /// Obtenir le stream d'état d'authentification
  Stream<AuthState> get authStateChanges => _client!.auth.onAuthStateChange;

  /// Vérifier si l'utilisateur est connecté
  bool get isAuthenticated => currentUser != null;

  /// Obtenir l'ID de l'utilisateur actuel
  String? get currentUserId => currentUser?.id;
}
