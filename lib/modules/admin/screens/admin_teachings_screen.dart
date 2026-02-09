import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/app_theme.dart';
import '../../teachings/providers/teachings_provider.dart';
import '../screens/admin_scaffold.dart';
import 'admin_teaching_editor_screen.dart';

class AdminTeachingsScreen extends StatefulWidget {
  const AdminTeachingsScreen({super.key});

  @override
  State<AdminTeachingsScreen> createState() => _AdminTeachingsScreenState();
}

class _AdminTeachingsScreenState extends State<AdminTeachingsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeachingsProvider>(context, listen: false).loadInitialData();
    });
  }

  void _deleteArticle(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Supprimer cet article ?", style: TextStyle(color: Colors.white)),
        content: const Text("Cette action est définitive.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Provider.of<TeachingsProvider>(context, listen: false).deleteArticle(id);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Article supprimé.")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeachingsProvider>(context);
    final articles = provider.articles;

    return AdminScaffold(
      currentRoute: '/admin/teachings', // Defines the route for the sidebar
      title: 'Gestion des Enseignements (Écrits)',
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminTeachingEditorScreen()),
            );
          },
          icon: const Icon(Icons.add_comment, color: Colors.white),
          label: const Text("Créer un Article", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary),
        ),
      ],
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : articles.isEmpty
              ? const Center(child: Text("Aucun article trouvé.", style: TextStyle(color: Colors.white)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.white.withOpacity(0.1))),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          article.titleFr,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (article.author != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text("Auteur: ${article.author!.name}", style: const TextStyle(color: Colors.white70)),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "Publié le ${article.publishedAt.toString().split(' ')[0]} • ${article.readTimeMinutes} min de lecture",
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => AdminTeachingEditorScreen(article: article)),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteArticle(article.id),
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
