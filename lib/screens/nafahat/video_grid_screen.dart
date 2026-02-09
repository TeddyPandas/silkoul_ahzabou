import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/media_models.dart';
import '../../providers/media_provider.dart';
import '../../config/app_theme.dart';
import 'video_player_screen.dart';

class VideoGridScreen extends StatefulWidget {
  final String title;
  final String? categoryId;
  final String? authorId;

  const VideoGridScreen({
    super.key,
    required this.title,
    this.categoryId,
    this.authorId,
  });

  @override
  State<VideoGridScreen> createState() => _VideoGridScreenState();
}

class _VideoGridScreenState extends State<VideoGridScreen> {
  late Future<List<MediaVideo>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  void _loadVideos() {
    final provider = context.read<MediaProvider>();
    if (widget.categoryId != null) {
      // Fetch more for the grid (e.g. 100)
      // We might need to add a 'limit' param to provider methods or just use what's cached if enough.
      // For now calling getVideosForCategory returns what's cached (50) or fetches.
      // Ideally we want to force fetch more?
      // Let's rely on the provider's logic for now.
      _videosFuture = provider.getVideosForCategory(widget.categoryId!);
    } else if (widget.authorId != null) {
      _videosFuture = provider.getVideosForAuthor(widget.authorId!);
    } else {
      _videosFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<MediaVideo>>(
        future: _videosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }
          
          final videos = snapshot.data ?? [];
          if (videos.isEmpty) {
            return const Center(child: Text('Aucune vidéo trouvée.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8, // Adjust based on card content
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              return _buildGridCard(context, videos[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, MediaVideo video) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    if (video.publishedAt != null)
                      Text(
                        _formatDate(video.publishedAt!),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple formatter, can use intl package later
    return "${date.day}/${date.month}/${date.year}";
  }
}
