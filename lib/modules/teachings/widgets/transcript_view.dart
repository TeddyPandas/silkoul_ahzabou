import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
// Actually, standard ListView with scrollToIndex is hard without a package. 
// I'll use standard ListView and basic offset calculation or just a simple manual scroll for MVP if package not available.
// Wait, I can't easily add packages without approval. I'll use a standard ListView and simplistic "jump to" if possible, or just let user scroll. 
// "Apple Style" usually auto-scrolls.
// I'll stick to standard ListView.Builder and try to animateTo if I know item height, or just highlight.

import '../providers/teachings_provider.dart';
import '../models/transcript_segment.dart';
import '../../../utils/app_theme.dart';

class TranscriptView extends StatefulWidget {
  final Future<List<TranscriptSegment>> Function() loadTranscript;

  const TranscriptView({super.key, required this.loadTranscript});

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  List<TranscriptSegment> _segments = [];
  bool _isLoading = true;
  // final ItemScrollController _itemScrollController = ItemScrollController(); 
  // Since I can't add packages easily, I will rely on user scrolling or basic ListView logic.
  // Actually, I can use ScrollController and estimate offset if fixed height, but text varies.
  // For MVP: Highlight the active text. User scrolls. Ideally "Tap to seek".

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await widget.loadTranscript();
    if (mounted) {
      setState(() {
        _segments = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.tealAccent));
    }

    if (_segments.isEmpty) {
      return Center(
        child: Text(
          "Aucune transcription disponible.",
          style: GoogleFonts.poppins(color: Colors.white60),
        ),
      );
    }

    return Consumer<TeachingsProvider>(
      builder: (context, provider, child) {
        final currentPosition = provider.audioPosition;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          itemCount: _segments.length,
          itemBuilder: (context, index) {
            final segment = _segments[index];
            final isActive = currentPosition.inMilliseconds >= segment.startTime && currentPosition.inMilliseconds < segment.endTime;

            return GestureDetector(
              onTap: () {
                provider.seekAudio(Duration(milliseconds: segment.startTime));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isActive ? Border.all(color: AppColors.tealAccent.withOpacity(0.3)) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transliteration (Main focus)
                    Text(
                      segment.transliteration,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        height: 1.5,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? Colors.white : Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Translation (Subtle)
                    Text(
                      segment.translation,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: isActive ? Colors.white70 : Colors.white30,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Arabic (Reference)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        segment.arabic,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.amiri( // Assuming Amiri font is available/setup
                          fontSize: 18,
                          color: AppColors.tealAccent.withOpacity(isActive ? 1.0 : 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
