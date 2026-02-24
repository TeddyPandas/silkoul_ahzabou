import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

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
        const SnackBar(content: Text('Utilisateur non authentifié.')),
      );
      return;
    }

    try {
      await userProvider.updateUserProfile(
        userId: userId,
        displayName: _displayNameController.text,
        // avatarUrl: 'new_avatar_url', // TODO: Implement avatar upload
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès !')),
      );
      setState(() {
        _isEditing = false; 
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la mise à jour : $e')),
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
        title: const Text('Profil'),
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

          // Si pas de profil mais utilisateur connecté, on affiche au moins l'email et le bouton logout
          if (user == null) {
            return const Center(
              child: Text(
                'Veuillez vous connecter pour voir votre profil.',
                style: TextStyle(fontSize: 16),
              ),
            );
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
                  decoration: const InputDecoration(labelText: 'Nom d\'affichage'),
                  readOnly: !_isEditing,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController..text = user?.email ?? '',
                  decoration: const InputDecoration(labelText: 'Email'),
                  readOnly: true,
                ),
                const SizedBox(height: 16),
                if (profile != null) ...[
                  TextFormField(
                    initialValue: profile.level.toString(),
                    decoration: const InputDecoration(labelText: 'Niveau'),
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: profile.points.toString(),
                    decoration: const InputDecoration(labelText: 'Points'),
                    readOnly: true,
                  ),
                  const SizedBox(height: 32),
                ],
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Déconnexion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(double.infinity, 50),
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
