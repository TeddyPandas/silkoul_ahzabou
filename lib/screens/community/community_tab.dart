import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/user_provider.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userProvider.errorMessage != null) {
            return Center(
              child: Text(
                'Error: ${userProvider.errorMessage}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }
          if (userProvider.users.isEmpty) {
            return const Center(
              child: Text('No users found in the community.'),
            );
          }

          return ListView.builder(
            itemCount: userProvider.users.length,
            itemBuilder: (context, index) {
              final user = userProvider.users[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['avatar_url'] != null
                        ? NetworkImage(user['avatar_url']) as ImageProvider
                        : const AssetImage('assets/images/avatar_placeholder.png'), // Placeholder image
                  ),
                  title: Text(user['display_name'] ?? 'Unknown User'),
                  subtitle: Text('Level: ${user['level'] ?? 1}, Points: ${user['points'] ?? 0}'),
                  // TODO: Add navigation to user profile or other community features
                  onTap: () {
                    // Handle tap, e.g., navigate to user profile
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
