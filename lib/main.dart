// lib/main.dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart'; // Pour kDebugMode et PlatformDispatcher
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/error_handler.dart'; // Import ErrorHandler
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/campaigns/campaign_details_screen.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/campaign_provider.dart';
import 'providers/user_provider.dart';
import 'providers/nafahat_provider.dart';
import 'providers/media_provider.dart'; // Media Module
import 'providers/wazifa_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'modules/quizzes/providers/quiz_provider.dart';
import 'modules/calendar/providers/calendar_provider.dart';
import 'modules/teachings/providers/teachings_provider.dart';
import 'modules/admin/screens/admin_dashboard_screen.dart';
import 'modules/admin/screens/admin_authors_screen.dart';
import 'modules/admin/screens/admin_shows_screen.dart'; // Shows Admin
import 'modules/admin/screens/admin_show_episodes_screen.dart'; // Episodes Admin
import 'modules/admin/screens/admin_wazifa_screen.dart'; // Wazifa Admin
import 'modules/admin/screens/admin_user_management_screen.dart'; // User Management
import 'modules/admin/screens/admin_podcast_create_screen.dart'; // Podcast Create
import 'modules/admin/screens/admin_videos_screen.dart'; // Video Admin
import 'modules/admin/screens/admin_video_create_screen.dart'; // Video Create
import 'modules/admin/screens/admin_media_import_screen.dart'; // Media Import
import 'modules/admin/screens/admin_teachings_screen.dart'; // Teachings Admin
import 'modules/admin/screens/admin_silsila_list_screen.dart'; // Silsila Admin
import 'modules/admin/screens/admin_campaigns_screen.dart'; // Campaigns Admin
import 'modules/admin/screens/admin_settings_screen.dart'; // Settings Admin
import 'modules/admin/screens/admin_quiz_list_screen.dart'; // Quiz Admin Admin
import 'modules/admin/screens/admin_course_screen.dart'; // Courses Admin
import 'config/app_theme.dart';

void main() async {
  // ✅ Initialisation Flutter
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Global Error Handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      ErrorHandler.log('🔴 Flutter Error: ${details.exception}');
      ErrorHandler.log('🔴 Stack: ${details.stack}');
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorHandler.log('🔴 Platform Error: $error');
      ErrorHandler.log('🔴 Stack: $stack');
      return true;
    };

    ErrorHandler.log('🚀 [main] ======== APP STARTING ========');
    ErrorHandler.log('🚀 [main] Time: ${DateTime.now()}');

    // ✅ CRITIQUE : Charger les variables d'environnement depuis .env
    try {
      await dotenv.load(fileName: ".env");
      ErrorHandler.log('✅ Fichier .env chargé avec succès');

      // Vérifier que les variables critiques sont présentes
      final apiBaseUrl = dotenv.env['API_BASE_URL'];
      if (apiBaseUrl == null || apiBaseUrl.isEmpty) {
        ErrorHandler.log('⚠️ ATTENTION : API_BASE_URL non définie dans .env');
      } else {
        ErrorHandler.log('✅ API_BASE_URL configurée');
      }
    } catch (e) {
      ErrorHandler.log('❌ ERREUR : Impossible de charger .env');
      ErrorHandler.log('   Erreur : $e');
    }

    // ✅ Initialiser Supabase
    try {
      await SupabaseService.initialize();
      ErrorHandler.log('✅ Supabase initialisé avec succès');

      // Add auth state change listener (Sanitized)
      Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) {
          if (kDebugMode) {
             print('🔐 [main] Auth State Changed: ${data.event}');
             print('🔐 [main] Session Active: ${data.session != null}');
          }
        },
        onError: (error, stackTrace) {
          ErrorHandler.log('❌ [main] Auth Error: $error');
        },
      );
    } catch (e) {
      ErrorHandler.log('❌ ERREUR lors de l\'initialisation de Supabase : $e');
    }

    // ✅ Initialiser NotificationService
    try {
      await NotificationService().initialize();
      ErrorHandler.log('✅ NotificationService initialisé avec succès');
    } catch (e) {
      ErrorHandler.log('❌ ERREUR lors de l\'initialisation de NotificationService : $e');
    }

    ErrorHandler.log('🚀 [main] ======== STARTING APP ========');

    // ✅ Lancer l'application
    runApp(const MyApp());
  }, (error, stack) {
     ErrorHandler.log('🔴 LOW-LEVEL ERROR: $error');
     ErrorHandler.log('🔴 Stack: $stack');
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links when app is opened from a link (cold start)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        ErrorHandler.log('🔗 [DeepLink] Initial link: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      ErrorHandler.log('❌ [DeepLink] Error getting initial link: $e');
    }

    // Handle links when app is already running (warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        ErrorHandler.log('🔗 [DeepLink] Received link: $uri');
        _handleDeepLink(uri);
      },
      onError: (error) {
        ErrorHandler.log('❌ [DeepLink] Stream error: $error');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    // Handle campaign deep links: silkoulahzabou://campaign/{campaignId}
    if (uri.scheme == 'silkoulahzabou' && uri.host == 'campaign') {
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final campaignId = pathSegments.first;
        ErrorHandler.log('🔗 [DeepLink] Opening campaign: $campaignId');
        
        // Navigate to campaign details screen
        // Use a small delay to ensure the app is fully initialized
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => CampaignDetailsScreen(campaignId: campaignId),
            ),
          );
        });
      }
    }
  }

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

        // ✅ Provider Media (Vidéos/Enseignements)
        ChangeNotifierProvider(create: (_) => MediaProvider()),

        // ✅ Provider Wazifa (Localisation)
        ChangeNotifierProvider(create: (_) => WazifaProvider()),

        // ✅ Provider Teachings (Enseignements)
        ChangeNotifierProvider(create: (_) => TeachingsProvider()),

        // ✅ Provider Quizzes
        ChangeNotifierProvider(create: (_) => QuizProvider()),

        // ✅ Provider Calendrier
        ChangeNotifierProvider(create: (_) => CalendarProvider()),

        // ✅ Provider utilisateur
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (context) =>
              UserProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previousUserProvider) =>
              previousUserProvider!..update(auth),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'MarkazTijani',
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
          '/admin/teachings': (context) => const AdminTeachingsScreen(),
          '/admin/silsila': (context) => const AdminSilsilaListScreen(),
          '/admin/campaigns': (context) => const AdminCampaignsScreen(),
          '/admin/videos': (context) => const AdminVideosScreen(),
          '/admin/videos/create': (context) => const AdminVideoCreateScreen(),
          '/admin/media/import': (context) => const AdminMediaImportScreen(),
          '/admin/settings': (context) => const AdminSettingsScreen(),
          '/admin/quizzes': (context) => const AdminQuizListScreen(),
          '/admin/calendar': (context) => const AdminCourseScreen(), // Added route
        },
      ),
    );
  }
}
