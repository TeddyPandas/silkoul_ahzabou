import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/app_theme.dart';
import '../../teachings/models/author.dart';
import '../../teachings/services/teaching_service.dart';
import 'admin_scaffold.dart';
import '../widgets/admin_form_fields.dart';

class AdminAuthorsScreen extends StatefulWidget {
  const AdminAuthorsScreen({super.key});

  @override
  State<AdminAuthorsScreen> createState() => _AdminAuthorsScreenState();
}

class _AdminAuthorsScreenState extends State<AdminAuthorsScreen> {
  late Future<List<Author>> _authorsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAuthors();
  }

  void _refreshAuthors() {
    setState(() {
      _authorsFuture = TeachingService.instance.getAuthors();
    });
  }

  Future<void> _showAuthorDialog({Author? author}) async {
    final nameController = TextEditingController(text: author?.name ?? '');
    final bioController = TextEditingController(text: author?.bio ?? '');
    final imageController = TextEditingController(text: author?.imageUrl ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          author == null ? "Ajouter un auteur" : "Modifier l'auteur",
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AdminTextField(
              controller: nameController,
              label: "Nom",
            ),
            const SizedBox(height: 16),
            AdminTextField(
              controller: bioController,
              label: "Biographie (Arabe/Français)",
              maxLines: 3,
            ),
            const SizedBox(height: 16),
             AdminTextField(
              controller: imageController,
              label: "URL de l'image",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary),
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              final newAuthor = Author(
                id: author?.id ?? '', // ID handled by DB on insert usually but object needs one. 
                                      // Actually our model might enforce ID. Let's see. 
                                      // The service create method will just pass fields, ID ignored by Supabase insert.
                                      // But our model constructor needs an ID. UUID placehoder?
                                      // Actually the service uses Map or object. 
                                      // Let's create a temporary object. The service ignores ID for insert.
                name: nameController.text,
                bio: bioController.text,
                imageUrl: imageController.text.isEmpty ? null : imageController.text,
              );

              try {
                if (author == null) {
                  await TeachingService.instance.createAuthor(newAuthor);
                } else {
                  await TeachingService.instance.updateAuthor(
                    newAuthor.copyWith(id: author.id), // Ensure we keep the ID for update
                  );
                }
                Navigator.pop(context);
                _refreshAuthors();
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enregistré avec succès !")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAuthor(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Confirmer la suppression", style: TextStyle(color: Colors.white)),
        content: const Text("Voulez-vous vraiment supprimer cet auteur ? Cela peut impacter les podcasts liés.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await TeachingService.instance.deleteAuthor(id);
      _refreshAuthors();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: '/admin/authors',
      title: 'Gestion des Auteurs',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _showAuthorDialog(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Ajouter un auteur", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary),
        ),
      ],
      body: FutureBuilder<List<Author>>(
        future: _authorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final authors = snapshot.data ?? [];

          if (authors.isEmpty) {
            return const Center(child: Text("Aucun auteur trouvé.", style: TextStyle(color: Colors.white)));
          }

          return Card(
             color: const Color(0xFF1E1E1E),
             child: ListView.separated(
              itemCount: authors.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final author = authors[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: author.imageUrl != null ? NetworkImage(author.imageUrl!) : null,
                    backgroundColor: Colors.grey[800],
                    child: author.imageUrl == null ? Text(author.name[0], style: const TextStyle(color: Colors.white)) : null,
                  ),
                  title: Text(author.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    author.bio ?? "Pas de biographie",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => _showAuthorDialog(author: author),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteAuthor(author.id),
                      ),
                    ],
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
