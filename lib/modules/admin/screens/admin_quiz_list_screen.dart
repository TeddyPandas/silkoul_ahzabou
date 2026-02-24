import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../quizzes/providers/quiz_provider.dart';
import '../../quizzes/models/quiz_models.dart';
import '../screens/admin_scaffold.dart';
import 'admin_edit_quiz_screen.dart';

class AdminQuizListScreen extends StatefulWidget {
  const AdminQuizListScreen({super.key});

  @override
  State<AdminQuizListScreen> createState() => _AdminQuizListScreenState();
}

class _AdminQuizListScreenState extends State<AdminQuizListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadQuizzes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: '/admin/quizzes',
      title: 'Gestion des Quizz',
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminEditQuizScreen()),
            );
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text("NOUVEAU QUIZZ"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009688),
            foregroundColor: Colors.white,
          ),
        ),
      ],
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.quizzes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Aucun quizz trouvé", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.loadQuizzes(),
                    child: const Text("ACTUALISER"),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.quizzes.length,
            itemBuilder: (context, index) {
              final quiz = provider.quizzes[index];
              return _buildQuizTile(quiz);
            },
          );
        },
      ),
    );
  }

  Widget _buildQuizTile(Quiz quiz) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
          child: quiz.imageUrl != null
              ? (quiz.imageUrl!.startsWith('assets/')
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(quiz.imageUrl!, fit: BoxFit.cover),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: quiz.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.black12),
                        errorWidget: (context, url, error) => Container(color: Colors.black12),
                      ),
                    ))
              : const Icon(Icons.quiz, color: Colors.amber, size: 30),
        ),
        title: Text(
          quiz.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildBadge(quiz.category, Colors.teal),
                const SizedBox(width: 8),
                _buildBadge(quiz.difficulty, _getDifficultyColor(quiz.difficulty)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminEditQuizScreen(quiz: quiz),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              onPressed: () => _confirmDelete(quiz),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _confirmDelete(Quiz quiz) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Supprimer le Quizz ?", style: TextStyle(color: Colors.white)),
        content: Text("Voulez-vous vraiment supprimer '${quiz.title}' ?\nCette action est irréversible.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANNULER"),
          ),
          TextButton(
            onPressed: () async {
              // TODO: Implement delete in provider/service
              Navigator.pop(context);
            },
            child: const Text("SUPPRIMER", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
