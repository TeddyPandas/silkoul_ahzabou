import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/campaign_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase
  await SupabaseService.initialize();

  runApp(const SilkoulApp());
}

class SilkoulApp extends StatelessWidget {
  const SilkoulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CampaignProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider(Provider.of<AuthProvider>(context, listen: false))),
      ],
      child: MaterialApp(
        title: 'Silkoul Ahzabou Tidiani',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
