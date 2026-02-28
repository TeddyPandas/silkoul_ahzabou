import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/locale_provider.dart';
import '../../utils/l10n_extensions.dart';
import '../../widgets/guest_gate_banner.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profile = authProvider.profile;
    if (profile != null) {
      _displayNameController.text = profile.displayName ?? '';
      _emailController.text = authProvider.user?.email ?? '';
    }
  }

  Future<void> _updateProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.userNotAuthenticated)),
      );
      return;
    }

    try {
      await userProvider.updateUserProfile(
        userId: userId,
        displayName: _displayNameController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileUpdatedSuccess)),
      );
      setState(() {
        _isEditing = false; 
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.profileUpdateFailed(e.toString()))),
      );
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.signOut();
    // Navigate to login screen or home screen after logout
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.profile),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final profile = authProvider.profile;
          final user = authProvider.user;

          // Invité ou non connecté : afficher le banner de connexion
          if (authProvider.isGuest || user == null) {
            return const GuestGateBanner();
          }

          if (profile == null && authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async => _loadProfileData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primaryLight,
                    child: profile?.avatarUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: profile!.avatarUrl!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              placeholder: (context, url) => const Icon(Icons.person, size: 60, color: AppColors.white),
                              errorWidget: (context, url, error) => const Icon(Icons.person, size: 60, color: AppColors.white),
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 60,
                            color: AppColors.white,
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _displayNameController
                    ..text = profile?.displayName ?? '',
                  decoration: InputDecoration(labelText: context.l10n.displayName),
                  readOnly: !_isEditing,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController..text = user?.email ?? '',
                  decoration: InputDecoration(labelText: context.l10n.email),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                if (profile != null) ...[
                  TextFormField(
                    initialValue: profile.level.toString(),
                    decoration: InputDecoration(labelText: context.l10n.level),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: profile.points.toString(),
                    decoration: InputDecoration(labelText: context.l10n.points),
                    readOnly: true,
                  ),
                ],
                const SizedBox(height: 32),
                
                // --- Language Settings Section ---
                const Divider(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.l10n.settings,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<LocaleProvider>(
                  builder: (context, localeProvider, child) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.language, color: AppColors.primary),
                      ),
                      title: Text(context.l10n.language),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${localeProvider.currentFlag} ${localeProvider.currentLanguageName}",
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => localeProvider.toggleLocale(),
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: Text(context.l10n.logout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          );
        },
      ),
    );
  }
}
