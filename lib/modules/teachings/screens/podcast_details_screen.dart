import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/teaching.dart';
import '../models/podcast_show.dart';
import '../providers/teachings_provider.dart';
import '../services/teaching_service.dart';
import 'player_screen.dart';
import '../widgets/mini_player.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/app_theme.dart';

class PodcastDetailsScreen extends StatefulWidget {
  final PodcastShow show;

  const PodcastDetailsScreen({super.key, required this.show});

  @override
  State<PodcastDetailsScreen> createState() => _PodcastDetailsScreenState();
}

class _PodcastDetailsScreenState extends State<PodcastDetailsScreen> {
  List<Teaching> _episodes = [];
  bool _isLoading = true;
  bool _isFollowed = false; // Follow State

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
    _checkFollowStatus(); // Check on init
  }

  Future<void> _checkFollowStatus() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user != null) {
      final isFollowed = await TeachingService.instance.checkFavoriteStatus(
        user.id,
        widget.show.id,
        'PODCAST_SHOW',
      );
      if (mounted) {
        setState(() => _isFollowed = isFollowed);
      }
    }
  }

  Future<void> _toggleFollow() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connectez-vous pour suivre une émission")),
      );
      return;
    }

    // Optimistic Update
    setState(() => _isFollowed = !_isFollowed);

    try {
      await TeachingService.instance.toggleFavorite(
        userId: user.id,
        itemId: widget.show.id,
        itemType: 'PODCAST_SHOW',
      );
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() => _isFollowed = !_isFollowed);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e")),
        );
      }
    }
  }

  Future<void> _loadEpisodes() async {
    try {
      final episodes = await TeachingService.instance.getShowEpisodes(widget.show.id);
      if (mounted) {
        setState(() {
          _episodes = episodes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeachingsProvider>(context);
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight, // Fixed: Light background
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              SliverToBoxAdapter(
                child: _buildShowHeader(context),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    "Épisodes",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary, // Fixed: Dark title
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_episodes.isEmpty)
                 SliverToBoxAdapter(
                   child: Center(
                     child: Padding(
                       padding: const EdgeInsets.all(32.0),
                       child: Text("Aucun épisode pour le moment", style: GoogleFonts.poppins(color: Colors.grey)),
                     ),
                   ),
                 )
              else
                _buildEpisodesList(context, _episodes, provider),
              
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)), // Space for MiniPlayer
            ],
          ),
          
          // Mini Player Overlay
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.backgroundLight, // Light background
      iconTheme: const IconThemeData(color: AppColors.tealPrimary), // Teal back button
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Light Gradient Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.tealLight.withOpacity(0.3),
                    AppColors.backgroundLight,
                  ],
                ),
              ),
            ),
            
            // Content
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Hero(
                    tag: widget.show.id,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15), // Softer shadow
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        image: widget.show.imageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(widget.show.imageUrl!), 
                                fit: BoxFit.cover,
                              )
                            : null,
                         color: Colors.grey[200],
                      ),
                       child: widget.show.imageUrl == null
                          ? const Icon(Icons.podcasts, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      color: AppColors.backgroundLight, // Light background
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            widget.show.titleFr,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary, // Dark text
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
           Text(
            widget.show.author?.name.toUpperCase() ?? "AUTEUR INCONNU",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.tealPrimary, // Teal subtitle
            ),
          ),
          const SizedBox(height: 24),
          
          // Primary Action Button (Play Latest)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _episodes.isNotEmpty ? () {
                  _playEpisode(context, _episodes.first);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.play_arrow_rounded, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    "Lancer le dernier épisode",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Secondary Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSecondaryAction(
                _isFollowed ? Icons.check_circle : Icons.add_circle_outline_rounded,
                _isFollowed ? "Suivi" : "Suivre",
                onTap: _toggleFollow,
                isAnimated: true, // Enable animation for this button
              ),
              const SizedBox(width: 24),
              _buildSecondaryAction(Icons.share_outlined, "Partager", onTap: () {
                final String text = "Découvrez l'émission ${widget.show.titleFr} sur Silkoul Ahzabou !\n\n${widget.show.descriptionFr ?? ''}";
                Share.share(text);
              }),
              const SizedBox(width: 24),
              _buildSecondaryAction(Icons.more_horiz_rounded, "Plus"),
            ],
          ),

          const SizedBox(height: 24),
          
          if (widget.show.descriptionFr != null)
             Text(
              widget.show.descriptionFr!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700], // Darker grey description
                height: 1.5,
              ),
            ),
          
          const SizedBox(height: 32),
           Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
        ],
      ),
    );
  }

  Widget _buildSecondaryAction(IconData icon, String label, {VoidCallback? onTap, bool isAnimated = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          if (isAnimated)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                icon, 
                key: ValueKey<String>(label), // Key for animation
                color: (label == "Suivi") ? AppColors.tealPrimary : AppColors.tealPrimary, 
                size: 28
              ),
            )
          else
            Icon(icon, color: AppColors.tealPrimary, size: 28), 
            
          const SizedBox(height: 4),
          Text(
            label, 
            style: GoogleFonts.poppins(
              fontSize: 10, 
              color: AppColors.tealPrimary, 
              fontWeight: FontWeight.w500
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEpisodesList(BuildContext context, List<Teaching> episodes, TeachingsProvider provider) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = episodes[index];
          final duration = Duration(seconds: item.durationSeconds);
          final isPlaying = provider.currentTeaching?.id == item.id && provider.isAudioPlaying;

          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                onTap: () => _playEpisode(context, item),
                title: Text(
                  "${item.publishedAt.day}/${item.publishedAt.month} • ${item.titleFr}",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isPlaying ? AppColors.tealPrimary : AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    if (item.descriptionFr != null)
                      Text(
                        item.descriptionFr!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]), 
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      "${duration.inMinutes} min",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.tealPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.play_circle_outline,
                    color: AppColors.tealPrimary,
                    size: 32,
                  ),
                  onPressed: () {
                    if (isPlaying) {
                       provider.pauseAudio();
                    } else {
                       provider.playAudio(item);
                    }
                  },
                ),
              ),
              Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.withOpacity(0.2)),
            ],
          );
        },
        childCount: episodes.length,
      ),
    );
  }

  void _playEpisode(BuildContext context, Teaching item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlayerScreen(teaching: item)),
    );
  }
}
