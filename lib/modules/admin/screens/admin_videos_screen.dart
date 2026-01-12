import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../utils/app_theme.dart';
import '../../teachings/models/teaching.dart';
import '../../teachings/services/teaching_service.dart';
import 'admin_scaffold.dart';

class AdminVideosScreen extends StatefulWidget {
  const AdminVideosScreen({super.key});

  @override
  State<AdminVideosScreen> createState() => _AdminVideosScreenState();
}

class _AdminVideosScreenState extends State<AdminVideosScreen> {
  late Future<List<Teaching>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _refreshVideos();
  }

  void _refreshVideos() {
    setState(() {
      _videosFuture = TeachingService.instance.getTeachings(type: TeachingType.VIDEO, limit: 100);
    });
  }

  Future<void> _deleteVideo(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Supprimer cette vidéo ?", style: TextStyle(color: Colors.white)),
        content: const Text("Cette action est définitive.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await TeachingService.instance.deleteTeaching(id);
        _refreshVideos();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vidéo supprimée.")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: '/admin/videos',
      title: 'Gestion des Vidéos',
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/admin/videos/create').then((_) => _refreshVideos());
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Ajouter une Vidéo", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary),
        ),
      ],
      body: FutureBuilder<List<Teaching>>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final videos = snapshot.data ?? [];

          if (videos.isEmpty) {
             return const Center(child: Text("Aucune vidéo trouvée.", style: TextStyle(color: Colors.white)));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              childAspectRatio: 0.8, // Taller cards
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Card(
                color: const Color(0xFF1E1E1E),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (video.thumbnailUrl != null)
                            Image.network(video.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey)),
                          const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 48)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(video.titleFr, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text(video.authorName ?? "Inconnu", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                                onPressed: () {
                                   Navigator.pushNamed(context, '/admin/videos/create', arguments: video).then((_) => _refreshVideos());
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                                onPressed: () => _deleteVideo(video.id),
                              ),
                            ],
                          )
                        ],
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
