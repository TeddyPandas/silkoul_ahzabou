import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // For ImageFilter
import 'package:share_plus/share_plus.dart';
import '../models/teaching.dart';
import '../widgets/transcript_view.dart';
import '../services/teaching_service.dart';
import '../providers/teachings_provider.dart';
import '../../../utils/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  final Teaching teaching;

  const PlayerScreen({super.key, required this.teaching});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  // Video Controllers (State remains local for Video)
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    if (widget.teaching.type == TeachingType.VIDEO) {
      _initVideoPlayer();
    } else {
      // Audio starts automatically via Provider if not already playing this track
      WidgetsBinding.instance.addPostFrameCallback((_) {
         context.read<TeachingsProvider>().playAudio(widget.teaching);
      });
    }
  }

  void _initVideoPlayer() {
    String? videoId = YoutubePlayer.convertUrlToId(widget.teaching.mediaUrl);
    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Only dispose video controller. Audio is global.
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.teaching.type == TeachingType.AUDIO) {
      return _buildImmersiveAudioPlayer(context);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark: true),
            Expanded(
              child: Center(
                child: _buildVideoPlayer(),
              ),
            ),
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImmersiveAudioPlayer(BuildContext context) {
    return Consumer<TeachingsProvider>(
      builder: (context, provider, child) {
        final position = provider.audioPosition;
        final duration = provider.audioDuration;
        final isPlaying = provider.isAudioPlaying;

        return Scaffold(
          body: Stack(
            children: [
              // Background Image (Blurred)
              if (widget.teaching.thumbnailUrl != null)
                Positioned.fill(
                  child: Image.network(
                    widget.teaching.thumbnailUrl!,
                    fit: BoxFit.cover,
                  ),
                ),
              // Blur Overlay
              if (widget.teaching.thumbnailUrl != null)
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: Colors.black.withOpacity(0.6), // Darken the blur
                    ),
                  ),
                ),
                
              // Fallback Background if no image
              if (widget.teaching.thumbnailUrl == null)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.tealPrimary, Colors.black],
                    ),
                  ),
                ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, isDark: true), 
                    
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Artwork Shadow
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: widget.teaching.thumbnailUrl != null
                                    ? Image.network(
                                        widget.teaching.thumbnailUrl!,
                                        width: 300,
                                        height: 300,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 300,
                                        height: 300,
                                        color: Colors.white.withOpacity(0.1),
                                        child: const Icon(Icons.music_note, color: Colors.white, size: 80),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 48),
                            
                            // Title & Artist
                            Text(
                              widget.teaching.titleFr,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.teaching.author?.name ?? "Cheikh",
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24), // Reduced vertical padding
                        child: Column(
                          children: [
                            // Slider
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                activeTrackColor: AppColors.tealAccent,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0),
                                max: duration.inSeconds.toDouble() > 0 
                                    ? duration.inSeconds.toDouble() 
                                    : 1.0, 
                                onChanged: (value) {
                                  provider.seekAudio(Duration(seconds: value.toInt()));
                                },
                              ),
                            ),
                            
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                  Text(_formatDuration(duration), style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Main Controls (Seek & Play)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 36),
                                  onPressed: () {
                                     provider.seekAudio(position - const Duration(seconds: 10));
                                  },
                                ),
                                Container(
                                  height: 72,
                                  width: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: AppColors.tealPrimary,
                                      size: 42,
                                    ),
                                    onPressed: () {
                                      if (isPlaying) {
                                        provider.pauseAudio();
                                      } else {
                                        provider.resumeAudio();
                                      }
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 36),
                                  onPressed: () {
                                    provider.seekAudio(position + const Duration(seconds: 10));
                                  },
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),

                            // Bottom Actions (Speed, AirPlay, More)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Speed Control
                                TextButton(
                                  onPressed: () {
                                    _showSpeedSelector(context, provider);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  child: Text("${provider.playbackSpeed}x"),
                                ),
                                
                                // AirPlay / Cast (Placeholder / Visual only for now)
                                const Icon(Icons.airplay_rounded, color: Colors.white70, size: 20),
                                
                                // More / List
                                IconButton(
                                  icon: const Icon(Icons.list_rounded, color: Colors.white70),
                                  onPressed: () {
                                    _showEpisodeQueue(context, provider);
                                  },
                                ),
                                
                                // Transcript / Lyrics
                                IconButton(
                                  icon: const Icon(Icons.lyrics_outlined, color: Colors.white70),
                                  onPressed: () {
                                    _showTranscript(context);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  void _showSpeedSelector(BuildContext context, TeachingsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text("Vitesse de lecture", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ...[0.75, 1.0, 1.25, 1.5, 2.0].map((speed) => ListTile(
                title: Text("${speed}x", style: const TextStyle(color: Colors.white)),
                trailing: provider.playbackSpeed == speed ? const Icon(Icons.check, color: AppColors.tealAccent) : null,
                onTap: () {
                  provider.setPlaybackSpeed(speed);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showEpisodeQueue(BuildContext context, TeachingsProvider provider) {
    // Filter queue to same author/type context
    final queue = provider.teachings.where((t) => 
      t.type == TeachingType.AUDIO && 
      t.authorId == widget.teaching.authorId
    ).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Épisodes",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      final isCurrent = item.id == widget.teaching.id;
                      return ListTile(
                        leading: Container(
                          width: 48, 
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            image: item.thumbnailUrl != null 
                              ? DecorationImage(image: NetworkImage(item.thumbnailUrl!), fit: BoxFit.cover)
                              : null,
                            color: Colors.grey[800],
                          ),
                          child: isCurrent 
                            ? const Center(child: Icon(Icons.graphic_eq, color: AppColors.tealAccent, size: 20))
                            : null,
                        ),
                        title: Text(
                          item.titleFr,
                          maxLines: 1, 
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: isCurrent ? AppColors.tealAccent : Colors.white,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _formatDuration(Duration(seconds: item.durationSeconds)),
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert, color: Colors.white60),
                          onPressed: () {},
                        ),
                        onTap: () {
                          // Close sheet and play new item? 
                          // Or just play and update UI?
                          // For a smooth flow, replace current player content. 
                          // Since PlayerScreen is pushed, we might validly push a replacement or just update state if we want to stay in same screen.
                          // Ideally, PlayerScreen should listen to Provider's currentTeaching.
                          // But widget.teaching is final. 
                          // Let's create a cleaner way: Update Provider -> PlayerScreen (if listening) SHOULD update if it uses provider.currentTeaching instead of widget.teaching.
                          // Currently PlayerScreen uses widget.teaching for layout.
                          // It's better to pop and push (easiest) or refactor PlayerScreen to consume Provider.
                          
                          // Quickest fix for "Pro" feel: Play and update provider.
                          // But we need to update the UI too.
                          Navigator.pop(context); // Close sheet
                          
                          // If we play it, the MiniPlayer shows it. 
                          // But we are INSIDE the Full Player.
                          // Let's replace the route.
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => PlayerScreen(teaching: item)),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTranscript(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    "Transcription",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Expanded(
                  child: TranscriptView(
                    loadTranscript: () => TeachingService.instance.getTranscript(widget.teaching.id),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Widget _buildHeader(BuildContext context, {bool isDark = false}) {
    // We need to listen to provider here to update the heart icon
    final provider = context.watch<TeachingsProvider>();
    final isFav = provider.isFavorite(widget.teaching.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white : Colors.black, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            widget.teaching.type == TeachingType.VIDEO ? "Lecteur Vidéo" : "Lecture en cours",
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 16
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppColors.error : (isDark ? Colors.white : Colors.black),
                ),
                onPressed: () {
                  provider.toggleFavorite(widget.teaching);
                },
              ),
              IconButton(
                icon: Icon(Icons.share_outlined, color: isDark ? Colors.white : Colors.black),
                onPressed: () {
                  final url = widget.teaching.mediaUrl;
                  final title = widget.teaching.titleFr;
                  Share.share("Écoutez '$title' sur Silkoul Ahzabou:\n$url");
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_youtubeController == null) {
      return const Text("Erreur: URL non valide", style: TextStyle(color: Colors.white));
    }
    return YoutubePlayer(
      controller: _youtubeController!,
      showVideoProgressIndicator: true,
      progressIndicatorColor: AppColors.tealAccent,
      onReady: () {
        // Player ready
      },
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.grey[900],
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.teaching.titleFr,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.teaching.author?.name ?? "Inconnu",
            style: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? "$hours:$minutes:$seconds" : "$minutes:$seconds";
  }
}

