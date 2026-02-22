import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../providers/quiz_provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<QuizProvider>().loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement'),
        centerTitle: true,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.leaderboard.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.leaderboard.isEmpty) {
            return const Center(child: Text("Pas encore de score enregistré."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.leaderboard.length,
            itemBuilder: (context, index) {
              final user = provider.leaderboard[index];
              final rank = user['rank'];
              final xp = user['total_xp'];
              final avatar = user['avatar_url'];
              final username = user['display_name'] ?? 'Utilisateur';

              return Card(
                elevation: index == 0 ? 4 : 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: _buildRankBadge(rank),
                  title: Text(
                    username,
                    style: TextStyle(
                      fontWeight: index < 3 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    '$xp XP',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color? color;
    if (rank == 1) color = AppColors.gold;
    else if (rank == 2) color = Colors.grey[400];
    else if (rank == 3) color = Colors.brown[300];

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color ?? Colors.grey[100],
        shape: BoxShape.circle,
        border: color != null ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color != null ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}
