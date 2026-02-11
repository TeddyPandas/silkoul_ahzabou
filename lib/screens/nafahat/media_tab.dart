import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/media_provider.dart';
import '../../models/media_models.dart';
import '../../config/app_theme.dart';
import 'video_player_screen.dart';
import 'video_grid_screen.dart';
import 'author_profile_screen.dart';

class MediaTab extends StatefulWidget {
  const MediaTab({super.key});

  @override
  State<MediaTab> createState() => _MediaTabState();
}

class _MediaTabState extends State<MediaTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MediaProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: provider.initialize,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HERO SECTION (Featured Video)
                if (provider.featuredVideo != null)
                  _buildHeroSection(context, provider.featuredVideo!),

                const SizedBox(height: 24),

                // 2. AUTHORS RAIL
                if (provider.authors.isNotEmpty) ...[
                  _buildSectionTitle('Guides & Conférenciers'),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.authors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        return _buildAuthorCard(provider.authors[index]);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 3. RECENT VIDEOS (Vertical List)
                if (provider.allVideos.isNotEmpty) ...[
                  _buildSectionTitle(
                    'Vidéos récentes',
                    onSeeAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VideoGridScreen(
                            title: 'Toutes les vidéos',
                          ),
                        ),
                      );
                    },
                  ),
                  ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.allVideos.length > 5 ? 5 : provider.allVideos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildVerticalVideoCard(provider.allVideos[index]);
                    },
                  ),
                  const SizedBox(height: 32),
                ],

                // 4. FOOTER PADDING
                const SizedBox(height: 50),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(BuildContext context, MediaVideo video) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video))
        );
      },
      child: Container(
        height: 380, // Immersive height
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(video.thumbnailUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
            // Content
            Positioned(
              left: 20,
              right: 20,
              bottom: 40,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.tealPrimary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      video.category?.name ?? 'Nouveauté',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    video.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (video.author != null)
                    Text(
                      video.author!.name,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video))
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Regarder maintenant"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Tout voir',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tealPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuthorCard(MediaAuthor author) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AuthorProfileScreen(author: author)),
        );
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: author.avatarUrl != null
                    ? NetworkImage(author.avatarUrl!)
                    : const NetworkImage('https://via.placeholder.com/80') as ImageProvider,
                fit: BoxFit.cover,
              ),
              border: Border.all(color: AppColors.tealPrimary.withOpacity(0.3), width: 2),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 100,
            child: Text(
              author.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalVideoCard(MediaVideo video) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video)),
        );
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: Container(
                width: 140,
                height: 100,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(video.thumbnailUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    if (video.author != null)
                      Text(
                        video.author!.name,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

  Widget _buildVideoCard(MediaVideo video, {bool compact = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: video))
        );
      },
      child: Container(
      width: compact ? 180 : 160,
      color: Colors.transparent, // Hit test
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            height: compact ? 100 : 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(video.thumbnailUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Icon(Icons.play_circle_fill, color: Colors.white.withOpacity(0.8), size: 30),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: compact ? 12 : 13),
          ),
        ],
      ),
      ),
    );
  }
}
