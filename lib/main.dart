// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/campaign_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'config/app_theme.dart';

void main() async {
  // ✅ Initialisation Flutter
  WidgetsFlutterBinding.ensureInitialized();

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
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    print('✅ Supabase initialisé avec succès');
  } catch (e) {
    print('❌ ERREUR lors de l\'initialisation de Supabase : $e');
  }

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

        // ✅ Provider utilisateur
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (context) =>
              UserProvider(Provider.of<AuthProvider>(context, listen: false)),
          update: (context, auth, previousUserProvider) => UserProvider(auth),
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

        // ✅ Routes nommées (optionnel, à développer selon besoins)
        // routes: {
        //   '/login': (context) => const LoginScreen(),
        //   '/home': (context) => const HomeScreen(),
        //   '/campaigns': (context) => const CampaignsListScreen(),
        //   '/profile': (context) => const ProfileScreen(),
        // },
      ),
    );
  }
}
