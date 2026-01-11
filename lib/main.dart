// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/campaign_provider.dart';
import 'providers/user_provider.dart';
import 'providers/nafahat_provider.dart';
import 'providers/wazifa_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'modules/teachings/providers/teachings_provider.dart';
import 'modules/admin/screens/admin_dashboard_screen.dart';
import 'modules/admin/screens/admin_authors_screen.dart';
import 'modules/admin/screens/admin_shows_screen.dart'; // Shows Admin
import 'modules/admin/screens/admin_show_episodes_screen.dart'; // Episodes Admin
import 'modules/admin/screens/admin_wazifa_screen.dart'; // Wazifa Admin
import 'modules/admin/screens/admin_user_management_screen.dart'; // User Management
import 'modules/admin/screens/admin_podcast_create_screen.dart'; // Podcast Create
import 'config/app_theme.dart';

void main() async {
  // ✅ Initialisation Flutter
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 [main] ======== APP STARTING ========');
  print('🚀 [main] Time: ${DateTime.now()}');

  // ✅ CRITIQUE : Charger les variables d'environnement depuis .env
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Fichier .env chargé avec succès');

    // Vérifier que les variables critiques sont présentes
    final apiBaseUrl = dotenv.env['API_BASE_URL'];
    if (apiBaseUrl == null || apiBaseUrl.isEmpty) {
      print('⚠️ ATTENTION : API_BASE_URL non définie dans .env');
      print('   Créez un fichier .env à la racine du projet avec :');
      print('   API_BASE_URL=http://VOTRE_IP:3000/api');
    } else {
      print('✅ API_BASE_URL configurée : $apiBaseUrl');
    }
  } catch (e) {
    print('❌ ERREUR : Impossible de charger .env');
    print('   Assurez-vous que le fichier .env existe à la racine du projet');
    print('   Erreur : $e');
  }

  // ✅ Initialiser Supabase
  try {
    await SupabaseService.initialize();
    print('✅ Supabase initialisé avec succès');

    // Log initial auth state to help diagnose OAuth issues
    final supabase = Supabase.instance.client;
    final currentSession = supabase.auth.currentSession;
    final currentUser = supabase.auth.currentUser;
    print(
        '🔐 [main] Initial session: ${currentSession != null ? "EXISTS" : "null"}');
    print('🔐 [main] Initial user: ${currentUser?.id ?? "null"}');
    if (currentSession != null) {
      print('🔐 [main] Session expired: ${currentSession.isExpired}');
    }

    // Add auth state change listener for debugging OAuth callbacks
    supabase.auth.onAuthStateChange.listen(
      (data) {
        print('🔐 [main] ========== AUTH STATE CHANGED ==========');
        print('🔐 [main] Event: ${data.event}');
        print('🔐 [main] Session: ${data.session != null ? "EXISTS" : "null"}');
        if (data.session != null) {
          print('🔐 [main] User ID: ${data.session!.user.id}');
          print(
              '🔐 [main] Access Token: ${data.session!.accessToken.substring(0, 20)}...');
        }
        print('🔐 [main] ============================================');
      },
      onError: (error, stackTrace) {
        print('❌ [main] AUTH STATE CHANGE ERROR: $error');
        print('❌ [main] Stack trace: $stackTrace');
      },
    );
  } catch (e) {
    print('❌ ERREUR lors de l\'initialisation de Supabase : $e');
  }

  print('🚀 [main] ======== STARTING APP ========');

  // ✅ Lancer l'application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ Provider d'authentification
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        // ✅ Provider des campagnes
        ChangeNotifierProvider(create: (_) => CampaignProvider()),

        // ✅ Provider Nafahat (Articles)
        ChangeNotifierProvider(create: (_) => NafahatProvider()..initialize()),

        // ✅ Provider Wazifa (Localisation)
        ChangeNotifierProvider(create: (_) => WazifaProvider()),

        // ✅ Provider Teachings (Enseignements)
        ChangeNotifierProvider(create: (_) => TeachingsProvider()),

        // ✅ Provider utilisateur
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (context) =>
              UserProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previousUserProvider) =>
              previousUserProvider!..update(auth),
        ),
      ],
      child: MaterialApp(
        title: 'Silkoul Ahzabou Tidiani',
        debugShowCheckedModeBanner: false,

        // ✅ Thème de l'application (vert/blanc/mauve)
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Forcer le mode clair

        // ✅ Écran de démarrage
        home: const SplashScreen(),

        // ✅ Routes nommées
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
          '/admin/authors': (context) => const AdminAuthorsScreen(),
          '/admin/shows': (context) => const AdminShowsScreen(),
          '/admin/shows/episodes': (context) => const AdminShowEpisodesScreen(),
          '/admin/wazifa': (context) => const AdminWazifaScreen(),
          '/admin/users': (context) => const AdminUserManagementScreen(),
          '/admin/podcasts/create': (context) => const AdminPodcastCreateScreen(),
        },
      ),
    );
  }
}
