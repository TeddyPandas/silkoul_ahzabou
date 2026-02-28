import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../config/app_theme.dart';
import '../../utils/l10n_extensions.dart';

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
        title: Text(context.l10n.community),
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
            return Center(
              child: Text(
                context.l10n.errorWithMessage(userProvider.errorMessage ?? ''),
                style: const TextStyle(color: AppColors.error),
              ),
            );
          if (userProvider.users.isEmpty) {
            return Center(
              child: Text(context.l10n.noUsersFound),
            );
          }

          return RefreshIndicator(
            onRefresh: () => userProvider.loadUsers(),
            child: ListView.builder(
              itemCount: userProvider.users.length,
              itemBuilder: (context, index) {
                final user = userProvider.users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['avatar_url'] != null
                          ? NetworkImage(user['avatar_url']) as ImageProvider
                          : const AssetImage('assets/images/avatar_placeholder.png'),
                    ),
                    title: Text(user['display_name'] ?? context.l10n.user),
                    subtitle: Text(context.l10n.userStats(user['level'] ?? 1, user['points'] ?? 0)),
                    onTap: () {},
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
