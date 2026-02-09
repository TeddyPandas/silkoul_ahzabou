import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import '../../teachings/models/teaching.dart';
import '../../teachings/services/teaching_service.dart';
import 'admin_scaffold.dart';
import '../widgets/admin_form_fields.dart';

class AdminShowEpisodesScreen extends StatefulWidget {
  const AdminShowEpisodesScreen({super.key});

  @override
  State<AdminShowEpisodesScreen> createState() => _AdminShowEpisodesScreenState();
}

class _AdminShowEpisodesScreenState extends State<AdminShowEpisodesScreen> {
  late String showId;
  late String showName;
  late Future<List<Teaching>> _episodesFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      showId = args['showId'];
      showName = args['showName'];
      _refreshEpisodes();
      _initialized = true;
    }
  }

  void _refreshEpisodes() {
    setState(() {
      _episodesFuture = TeachingService.instance.getShowEpisodes(showId);
    });
  }

  Future<void> _unlinkEpisode(String teachingId) async {
    // Unlink by setting podcast_show_id to null
    await TeachingService.instance.linkEpisodeToShow(teachingId, null);
    _refreshEpisodes();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Épisode retiré de l'émission")));
  }

  Future<void> _showAddEpisodeDialog() async {
    // Simple search/list dialog
    // Ideally we should search for teachings types AUDIO
    String searchQuery = '';
    List<Teaching> searchResults = [];
    final searchController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Ajouter un épisode", style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: 500,
            height: 400,
            child: Column(
              children: [
                AdminTextField(
                  controller: searchController,
                  hintText: "Rechercher un audio...",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: Colors.grey),
                    onPressed: () async {
                       if (searchQuery.isNotEmpty) {
                         final results = await TeachingService.instance.searchContent(searchQuery);
                         final teachings = results['teachings'] as List<Teaching>;
                         setState(() {
                           searchResults = teachings.where((t) => t.type == TeachingType.AUDIO).toList();
                         });
                       }
                    },
                  ),
                  onChanged: (val) => searchQuery = val,
                  onSubmitted: (val) async {
                       final results = await TeachingService.instance.searchContent(val);
                       final teachings = results['teachings'] as List<Teaching>;
                       setState(() {
                         searchResults = teachings.where((t) => t.type == TeachingType.AUDIO).toList();
                       });
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: searchResults.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final t = searchResults[index];
                      return ListTile(
                        title: Text(t.titleFr, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(t.author?.name ?? '', style: const TextStyle(color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.tealPrimary),
                          onPressed: () async {
                            await TeachingService.instance.linkEpisodeToShow(t.id, showId);
                            if (context.mounted) Navigator.pop(context); // Close dialog
                            _refreshEpisodes(); // Refresh list
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Épisode ajouté !")));
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: '/admin/shows', // Keep 'Shows' highlighted in sidebar
      title: 'Épisodes : $showName',
      actions: [
         ElevatedButton.icon(
          onPressed: () => _showAddEpisodeDialog(),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Ajouter un épisode", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary),
        ),
      ],
      body: FutureBuilder<List<Teaching>>(
        future: _episodesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final episodes = snapshot.data ?? [];
          
          if (episodes.isEmpty) {
             return const Center(child: Text("Aucun épisode dans cette émission.", style: TextStyle(color: Colors.white)));
          }

          return Card(
             color: const Color(0xFF1E1E1E),
             child: ListView.separated(
              itemCount: episodes.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white10),
              itemBuilder: (context, index) {
                final episode = episodes[index];
                return ListTile(
                  leading: const Icon(Icons.audiotrack, color: Colors.grey),
                  title: Text(episode.titleFr, style: const TextStyle(color: Colors.white)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                           Navigator.pushNamed(
                            context, 
                            '/admin/podcasts/create', // Reuse screen
                            arguments: episode,
                          ).then((_) => _refreshEpisodes());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.link_off, color: Colors.redAccent),
                        onPressed: () => _unlinkEpisode(episode.id),
                        tooltip: "Retirer de l'émission",
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
