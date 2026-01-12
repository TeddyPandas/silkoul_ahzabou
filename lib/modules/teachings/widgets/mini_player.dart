import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/teachings_provider.dart';
import '../screens/player_screen.dart';
import '../models/teaching.dart';
import '../../../utils/app_theme.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TeachingsProvider>(
      builder: (context, provider, child) {
        final teaching = provider.currentTeaching;
        if (teaching == null || teaching.type != TeachingType.AUDIO) return const SizedBox.shrink();

        // Calculate progress
        final duration = provider.audioDuration.inSeconds.toDouble();
        final position = provider.audioPosition.inSeconds.toDouble();
        final progress = (duration > 0) ? (position / duration) : 0.0;

        return SafeArea(
          top: false,
          child: GestureDetector(
            onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(teaching: teaching),
                ),
              );
            },
            child: Container(
              height: 72, // Capsule Height
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24), // High bottom margin for floating look
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E), // Dark Theme Capsule
                borderRadius: BorderRadius.circular(50), // Fully Rounded (Stadium)
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Stack(
                children: [
                   // Subtle Gradient Background (Optional, for premium feel)
                   Container(
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(50),
                       gradient: LinearGradient(
                         begin: Alignment.centerLeft,
                         end: Alignment.centerRight,
                         colors: [Colors.white.withOpacity(0.05), Colors.transparent],
                       ),
                     ),
                   ),
                   
                   Row(
                    children: [
                      // Circular Artwork
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: teaching.thumbnailUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(teaching.thumbnailUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Colors.grey[800],
                            border: Border.all(color: Colors.white12, width: 1),
                          ),
                          child: teaching.thumbnailUrl == null
                              ? const Icon(Icons.music_note, color: Colors.white, size: 24)
                              : null,
                        ),
                      ),
                      
                      const SizedBox(width: 6),
                      
                      // Info Text
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teaching.titleFr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              teaching.author?.name ?? "Cheikh",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[400],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10_rounded, color: Colors.white70, size: 24),
                            onPressed: () {
                              provider.seekAudio(provider.audioPosition - const Duration(seconds: 10));
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              provider.isAudioPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                              color: Colors.white,
                              size: 40,
                            ),
                            onPressed: () {
                              if (provider.isAudioPlaying) {
                                provider.pauseAudio();
                              } else {
                                provider.resumeAudio();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.forward_10_rounded, color: Colors.white70, size: 24),
                            onPressed: () {
                              provider.seekAudio(provider.audioPosition + const Duration(seconds: 10));
                            },
                          ),
                          // Close Button
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                              onPressed: () {
                                provider.stopAudio();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
