import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../config/app_theme.dart';
import '../../../../providers/media_provider.dart';
import '../../../../models/media_models.dart';
import 'admin_scaffold.dart';

class AdminVideosScreen extends StatefulWidget {
  const AdminVideosScreen({super.key});

  @override
  State<AdminVideosScreen> createState() => _AdminVideosScreenState();
}

class _AdminVideosScreenState extends State<AdminVideosScreen> {
  late Future<({List<MediaVideo> videos, int count})> _videosFuture;
  int _currentPage = 1;
  final int _limit = 20;
  int _totalCount = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _refreshVideos();
  }

  void _refreshVideos() {
    setState(() {
      // Access provider without listening to fetch data
      _videosFuture = Provider.of<MediaProvider>(context, listen: false).getAllVideos(page: _currentPage, limit: _limit);
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
        await Provider.of<MediaProvider>(context, listen: false).deleteVideo(id);
        _refreshVideos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vidéo supprimée.")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _editVideo(MediaVideo video) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Modification non supportée pour le moment.")));
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: '/admin/videos',
      title: 'Gestion des Vidéos',
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            // Re-using the Video Create screen if we want to create manually, or Import
            Navigator.pushNamed(context, '/admin/media/import').then((_) => _refreshVideos());
          },
          icon: const Icon(Icons.cloud_download, color: Colors.white),
          label: const Text("Importer depuis YouTube", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary),
        ),
      ],
      body: FutureBuilder<({List<MediaVideo> videos, int count})>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final result = snapshot.data;
          final videos = result?.videos ?? [];
          _totalCount = result?.count ?? 0;
          final totalPages = (_totalCount / _limit).ceil().clamp(1, 9999);
          _hasMore = _currentPage < totalPages;

          if (videos.isEmpty && _currentPage == 1) {
             return const Center(child: Text("Aucune vidéo trouvée.", style: TextStyle(color: Colors.white)));
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
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
                    final isHidden = video.status == 'HIDDEN';

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        side: isHidden ? const BorderSide(color: Colors.orange, width: 2) : BorderSide.none,
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (video.thumbnailUrl.isNotEmpty)
                                   Image.network(video.thumbnailUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey)),
                                const Center(child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 48)),
                                if (isHidden)
                                  Container(
                                    color: Colors.black54,
                                    child: const Center(child: Icon(Icons.visibility_off, color: Colors.white)),
                                  )
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video.title, 
                                  maxLines: 2, 
                                  overflow: TextOverflow.ellipsis, 
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  video.author?.name ?? "Sans auteur", 
                                  style: const TextStyle(color: Colors.grey, fontSize: 11)
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                                      onPressed: () => _editVideo(video),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
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
                ),
              ),
              
              // Pagination Controls
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: _currentPage > 1 ? () {
                        setState(() => _currentPage--);
                        _refreshVideos();
                      } : null,
                    ),
                    Text(
                      "Page $_currentPage / $totalPages", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                      onPressed: _hasMore ? () {
                        setState(() => _currentPage++);
                        _refreshVideos();
                      } : null,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
