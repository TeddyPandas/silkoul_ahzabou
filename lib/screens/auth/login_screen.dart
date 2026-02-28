import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../modules/admin/screens/admin_dashboard_screen.dart';
import '../home/home_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../utils/l10n_extensions.dart';
import 'package:email_validator/email_validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _waitingForGoogleAuth = false;
  bool _hasNavigated = false;
  AuthProvider? _authProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen to auth changes to handle OAuth callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAuthListener();
    });
  }

  void _setupAuthListener() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.addListener(_onAuthChanged);
    debugPrint('🔐 [LoginScreen] Auth listener set up');
  }

  void _onAuthChanged() {
    if (!mounted || _hasNavigated) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    debugPrint(
        '🔐 [LoginScreen] Auth state changed! User: ${authProvider.user?.id}');

    if (authProvider.user != null && _waitingForGoogleAuth) {
      debugPrint(
          '🔐 [LoginScreen] ✅ User authenticated via OAuth! Navigating...');
      _hasNavigated = true;
      _waitingForGoogleAuth = false;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) =>
                kIsWeb ? const AdminDashboardScreen() : const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    // Remove auth listener
    _authProvider?.removeListener(_onAuthChanged);

    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 [LoginScreen] App lifecycle state: $state');
    if (state == AppLifecycleState.resumed && _waitingForGoogleAuth) {
      // App resumed after Google auth - check if we have a valid user
      _checkAuthAfterGoogleSignIn();
    }
  }

  Future<void> _checkAuthAfterGoogleSignIn() async {
    debugPrint('🔐 [LoginScreen] Checking auth after Google Sign-In resume...');

    if (_hasNavigated) return;

    // Wait for Supabase to process the deep link and token exchange
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted || _hasNavigated) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    debugPrint('🔐 [LoginScreen] After delay, user: ${authProvider.user?.id}');

    if (authProvider.user != null) {
      debugPrint(
          '🔐 [LoginScreen] ✅ Auth successful! Navigating to HomeScreen...');
      _hasNavigated = true;
      _waitingForGoogleAuth = false;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) =>
                kIsWeb ? const AdminDashboardScreen() : const HomeScreen()),
      );
    } else {
      debugPrint('🔐 [LoginScreen] ❌ No user yet, waiting for auth...');
      // User is still null, might still be processing
      // Don't do anything, user can retry
      _waitingForGoogleAuth = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.authFailed),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      if (kIsWeb) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? context.l10n.authFailed,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    debugPrint('🔐 [LoginScreen] Starting Google Sign-In...');

    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    setState(() => _isLoading = false);

    debugPrint('🔐 [LoginScreen] signInWithGoogle returned: $success');

    if (success) {
      // Set flag so lifecycle observer knows to check auth on resume
      _waitingForGoogleAuth = true;

      // IMPORTANT: For OAuth flows, signInWithGoogle() returns true when the
      // browser opens, NOT when authentication completes!
      //
      // The actual auth completion happens via deep link callback, which:
      // 1. Fires a signedIn event to AuthProvider
      // 2. App resumes and HomeScreen's lifecycle handler checks auth
      // 3. If user is valid, data is refreshed; if not, redirects to SplashScreen
      //
      // So we do NOT navigate here - just show a message and let the flow happen.
      debugPrint(
          '🔐 [LoginScreen] Browser opened for Google auth. Waiting for callback...');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.authInProgress),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? context.l10n.authFailed,
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: kIsWeb
                ? Card(
                    elevation: 4,
                    margin: const EdgeInsets.all(AppConstants.paddingLarge),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _buildLoginForm(),
                  )
                : _buildLoginForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),

            // Logo et titre
            Image.asset(
              'assets/images/app_logo_512.png',
              height: 120,
              width: 120,
            ),
            const SizedBox(height: 16),

            const Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              context.l10n.zikrPractice,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Champ Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: context.l10n.email,
                hintText: context.l10n.emailHint,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.emailRequired;
                }
                if (!EmailValidator.validate(value.trim())) {
                  return context.l10n.emailInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Champ Mot de passe
            TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: context.l10n.password,
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return context.l10n.passwordRequired;
                }
                if (value.length < 6) {
                  return context.l10n.passwordTooShort;
                }
                return null;
              },
            ),
            const SizedBox(height: 8),

            // Lien Mot de passe oublié
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implémenter mot de passe oublié
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.featureComingSoon),
                    ),
                  );
                },
                child: Text(context.l10n.forgotPassword),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton Se connecter
            ElevatedButton(
              onPressed: _isLoading ? null : _handleEmailLogin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      context.l10n.login,
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 24),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    context.l10n.orLabel,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),

            // Bouton Google
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _handleGoogleLogin,
              icon: const Icon(Icons.g_mobiledata, size: 32),
              label: Text(context.l10n.continueWithGoogle),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: const BorderSide(color: AppColors.divider),
              ),
            ),
            const SizedBox(height: 32),

            // Lien vers inscription
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${context.l10n.noAccountYet} ',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SignupScreen(),
                      ),
                    );
                  },
                  child: Text(
                    context.l10n.signup,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Continuer en mode invité
            TextButton(
              onPressed: _isLoading ? null : _handleContinueAsGuest,
              child: Text(
                AppLocalizations.of(context)!.continueAsGuest,
                style: const TextStyle(color: AppColors.textLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinueAsGuest() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.enterGuestMode();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}
