import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../utils/app_theme.dart';
import '../../teachings/models/podcast_show.dart';
import '../../teachings/models/author.dart';
import '../../teachings/models/category.dart';
import '../../teachings/services/teaching_service.dart';
import 'admin_scaffold.dart';
import '../widgets/admin_form_fields.dart';

class AdminShowsScreen extends StatefulWidget {
  const AdminShowsScreen({super.key});

  @override
  State<AdminShowsScreen> createState() => _AdminShowsScreenState();
}

class _AdminShowsScreenState extends State<AdminShowsScreen> {
  late Future<List<PodcastShow>> _showsFuture;
  List<Author> _authors = [];
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadDependencies();
    _refreshShows();
  }

  Future<void> _loadDependencies() async {
    final authors = await TeachingService.instance.getAuthors();
    final categories = await TeachingService.instance.getCategories();
    if (mounted) {
      setState(() {
        _authors = authors;
        _categories = categories;
      });
    }
  }

  void _refreshShows() {
    setState(() {
      _showsFuture = TeachingService.instance.getPodcastShows();
    });
  }

  Future<void> _showDialog({PodcastShow? show}) async {
    final titleFrController = TextEditingController(text: show?.titleFr ?? '');
    final titleArController = TextEditingController(text: show?.titleAr ?? '');
    final descFrController = TextEditingController(text: show?.descriptionFr ?? '');
    final descArController = TextEditingController(text: show?.descriptionAr ?? '');
    final imageController = TextEditingController(text: show?.imageUrl ?? '');
    
    String? selectedAuthorId = show?.authorId;
    String? selectedCategoryId = show?.categoryId;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            show == null ? "Ajouter une émission" : "Modifier l'émission",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AdminTextField(
                        controller: titleFrController,
                        label: "Titre (FR)",
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AdminTextField(
                        controller: titleArController,
                        label: "Titre (AR)",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AdminTextField(
                        controller: descFrController,
                        label: "Description (FR)",
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AdminTextField(
                        controller: descArController,
                        label: "Description (AR)",
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AdminTextField(
                  controller: imageController,
                  label: "Image URL",
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AdminDropdown<String>(
                        label: "Auteur",
                        value: selectedAuthorId,
                        items: _authors.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                        onChanged: (val) => setState(() => selectedAuthorId = val),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AdminDropdown<String>(
                        label: "Catégorie",
                        value: selectedCategoryId,
                        items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameFr))).toList(), 
                        onChanged: (val) => setState(() => selectedCategoryId = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary),
              onPressed: () async {
                if (titleFrController.text.isEmpty) return;

                final newShow = PodcastShow(
                  id: show?.id ?? '', 
                  titleFr: titleFrController.text,
                  titleAr: titleArController.text,
                  descriptionFr: descFrController.text,
                  descriptionAr: descArController.text,
                  imageUrl: imageController.text.isEmpty ? null : imageController.text,
                  authorId: selectedAuthorId,
                  categoryId: selectedCategoryId,

                );

                try {
                  if (show == null) {
                    await TeachingService.instance.createPodcastShow(newShow);
                  } else {
                    await TeachingService.instance.updatePodcastShow(newShow.copyWith(id: show.id));
                  }
                  Navigator.pop(context);
                  _refreshShows();
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enregistré avec succès !")));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
                }
              },
              child: const Text("Enregistrer", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteShow(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Confirmer la suppression", style: TextStyle(color: Colors.white)),
         content: const Text("Supprimer cette émission ? Les épisodes ne seront pas supprimés mais détachés.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
        await TeachingService.instance.deletePodcastShow(id);
        _refreshShows();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: '/admin/shows',
      title: 'Gestion des Podcasts (Émissions)',
      actions: [
        ElevatedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/admin/podcasts/create'),
          icon: const Icon(Icons.mic, color: Colors.white),
          label: const Text("Nouvel Épisode", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _showDialog(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Nouvelle Émission", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary),
        ),
      ],
      body: FutureBuilder<List<PodcastShow>>(
        future: _showsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final shows = snapshot.data ?? [];

          if (shows.isEmpty) {
             return const Center(child: Text("Aucune émission trouvée.", style: TextStyle(color: Colors.white)));
          }

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: shows.length,
            itemBuilder: (context, index) {
              final show = shows[index];
              return Card(
                color: const Color(0xFF1E1E1E),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: show.imageUrl != null 
                        ? Image.network(show.imageUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey[800], child: const Icon(Icons.broken_image, color: Colors.white54))) 
                        : Container(color: Colors.blueGrey[800], child: const Icon(Icons.mic, color: Colors.white54, size: 48)),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(show.titleFr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(show.author?.name ?? "Auteur inconnu", maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent), onPressed: () => _showDialog(show: show)),
                                IconButton(icon: const Icon(Icons.list, size: 20, color: AppColors.tealPrimary), onPressed: () {
                                  Navigator.pushNamed(
                                    context, 
                                    '/admin/shows/episodes',
                                    arguments: {'showId': show.id, 'showName': show.titleFr},
                                  );
                                }),
                                IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent), onPressed: () => _deleteShow(show.id)),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
