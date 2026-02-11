import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/media_models.dart';
import '../../providers/media_provider.dart';
import '../../config/app_theme.dart';
import 'video_player_screen.dart';
import '../../widgets/primary_app_bar.dart';

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaProvider>().fetchFirstPage();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<MediaProvider>().fetchNextPage();
    }
  }

  // No longer using FutureBuilder for pagination

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: widget.title,
      ),
      body: Consumer<MediaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.allVideos.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.tealPrimary));
          }
          
          final videos = provider.allVideos;
          if (videos.isEmpty) {
            return const Center(child: Text('Aucune vidéo trouvée.'));
          }

          return ListView(
            controller: _scrollController,
            children: [
              GridView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  return _buildGridCard(context, videos[index]);
                },
              ),
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: AppColors.tealPrimary)),
                ),
              if (!provider.hasMore && videos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Fin des vidéos',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  ),
                ),
            ],
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
