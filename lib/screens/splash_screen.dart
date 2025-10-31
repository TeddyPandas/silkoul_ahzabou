import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/app_constants.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    print('[SplashScreen] Starting navigation logic...');
    // Attendre la durée de l'écran de démarrage ET laisser le temps aux services de s'initialiser.
    await Future.delayed(AppConstants.splashDuration);

    if (!mounted) {
      print('[SplashScreen] Widget not mounted, aborting navigation.');
      return;
    }

    print('[SplashScreen] Getting AuthProvider...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    print('[SplashScreen] Auth state check: isAuthenticated = $isAuthenticated');

    if (isAuthenticated) {
      print('[SplashScreen] Navigating to HomeScreen...');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      print('[SplashScreen] Navigating to LoginScreen...');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou icône
              const Icon(
                Icons.mosque,
                size: 100,
                color: AppColors.white,
              ),
              const SizedBox(height: 24),

              // Nom de l'application
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                'Pratique collective du Zikr',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 48),

              // Indicateur de chargement
              const CircularProgressIndicator(
                color: AppColors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
