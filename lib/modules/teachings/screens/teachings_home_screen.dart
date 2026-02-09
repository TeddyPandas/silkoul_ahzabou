import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/teachings_provider.dart';
import '../models/teaching.dart';
import '../models/podcast_show.dart';
import 'player_screen.dart';
import 'podcast_details_screen.dart';
import 'article_reader_screen.dart';
import 'search_screen.dart';
import '../widgets/mini_player.dart';
import '../../../screens/nafahat/media_tab.dart'; // Import MediaTab
import '../../../config/app_theme.dart';

class TeachingsHomeScreen extends StatefulWidget {
  const TeachingsHomeScreen({super.key});

  @override
  State<TeachingsHomeScreen> createState() => _TeachingsHomeScreenState();
}

class _TeachingsHomeScreenState extends State<TeachingsHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TeachingsProvider>(context, listen: false).loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text("Enseignements", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: AppColors.tealPrimary,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(),
          indicatorColor: AppColors.tealAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Vidéos"),
            Tab(text: "Podcasts"),
            Tab(text: "Textes"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Global Category Filter (Optional, can be hidden for Podcast tab if needed)
          _buildCategoryFilters(context),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                MediaTab(), // New Netflix-style Video UI
                _PodcastTab(), // Distinct UI for Podcasts
                _ArticlesList(),
              ],
            ),
          ),
          const MiniPlayer(), // Persistent Mini Player
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context) {
    final provider = Provider.of<TeachingsProvider>(context);
    final categories = provider.categories;

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = provider.selectedCategoryId == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text("Tous"),
                selected: isSelected,
                selectedColor: AppColors.tealPrimary.withOpacity(0.2),
                checkmarkColor: AppColors.tealPrimary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.tealPrimary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => provider.setCategory(null),
              ),
            );
          }
          final category = categories[index - 1];
          final isSelected = provider.selectedCategoryId == category.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category.nameFr),
              selected: isSelected,
              selectedColor: AppColors.tealPrimary.withOpacity(0.2),
              checkmarkColor: AppColors.tealPrimary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.tealPrimary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => provider.setCategory(category.id),
            ),
          );
        },
      ),
    );
  }
}

// --- Podcast Tab Implementation (Apple Podcasts Style) ---

class _PodcastTab extends StatelessWidget {
  const _PodcastTab();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeachingsProvider>(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Data Preparation
    // "Up Next" -> Ideally the last played or latest episode. For now, let's take the latest audio.
    // "You Might Like" -> Featured Shows or Random selection.
    
    final allAudio = provider.teachings.where((t) => t.type == TeachingType.AUDIO).toList();
    // Sort by date new -> old
    // allAudio.sort((a, b) => b.publishedAt.compareTo(a.publishedAt)); 
    
    final upNextEpisode = allAudio.isNotEmpty ? allAudio.first : null;
    final recentEpisodes = allAudio.skip(1).take(10).toList();
    
    final featuredShows = provider.podcastShows;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),

          // "À la une" Section (Slider)
          if (recentEpisodes.isNotEmpty) ...[
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "À la une",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160, // Adjusted height for slider
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                padEnds: false, // Start from left (requires padding handling)
                itemCount: recentEpisodes.take(5).length,
                itemBuilder: (context, index) {
                  // Add left padding for the first item to align with title
                  final item = recentEpisodes[index];
                   return Padding(
                     padding: EdgeInsets.only(
                       left: index == 0 ? 20 : 0, 
                       right: 12 // Gap between cards
                     ),
                     child: _buildUpNextTxCard(context, item),
                   );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // "Vos Émissions" (You Might Like / Shows)
          if (featuredShows.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Émissions",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200, // Adjusted height
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: featuredShows.length,
                itemBuilder: (context, index) {
                  return _buildShowSquareCard(context, featuredShows[index]);
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // "Nouveautés" (Recent Episodes List)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "Nouveautés",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: recentEpisodes.length,
            separatorBuilder: (c, i) => Divider(height: 1, indent: 80, color: Colors.grey.withOpacity(0.2)),
            itemBuilder: (context, index) {
              return _buildLightEpisodeTile(context, recentEpisodes[index]);
            },
          ),

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }

  // Large Horizontal Card for "Up Next"
  Widget _buildUpNextTxCard(BuildContext context, Teaching item) {
    return GestureDetector(
      onTap: () => _openPlayer(context, item),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 140, // Compact but wide
        decoration: BoxDecoration(
          color: Colors.white, // Light Card Bg
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            // Artwork Left
            Container(
              width: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                image: item.thumbnailUrl != null
                    ? DecorationImage(image: NetworkImage(item.thumbnailUrl!), fit: BoxFit.cover)
                    : null,
                color: AppColors.tealLight.withOpacity(0.2),
              ),
               child: item.thumbnailUrl == null 
                  ? const Center(child: Icon(Icons.music_note, color: AppColors.tealPrimary, size: 40)) 
                  : null,
            ),
            
            // Info Right
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "NOUVEL ÉPISODE",
                       style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tealPrimary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.titleFr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                     Text(
                      item.author?.name ?? "Inconnu",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
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

  // Square Vertical Card for "Shows"
  Widget _buildShowSquareCard(BuildContext context, PodcastShow show) {
    return GestureDetector(
      onTap: () => _openShowDetails(context, show),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Square Image
            Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ],
                image: show.imageUrl != null
                    ? DecorationImage(image: NetworkImage(show.imageUrl!), fit: BoxFit.cover)
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              show.titleFr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
             Text(
              show.author?.name ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Minimal List Tile for "Recent"
  Widget _buildLightEpisodeTile(BuildContext context, Teaching item) {
    return InkWell(
      onTap: () => _openPlayer(context, item),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
             Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey[200],
                image: item.thumbnailUrl != null
                    ? DecorationImage(image: NetworkImage(item.thumbnailUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: item.thumbnailUrl == null ? const Icon(Icons.play_arrow, color: AppColors.textSecondary) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    item.titleFr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                   Text(
                    "${item.publishedAt.day}/${item.publishedAt.month} • ${_formatDuration(item.durationSeconds)}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
             const Icon(Icons.play_circle_outline, color: AppColors.tealPrimary),
          ],
        ),
      ),
    );
  }

  void _openShowDetails(BuildContext context, PodcastShow show) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PodcastDetailsScreen(show: show),
      ),
    );
  }

  void _openPlayer(BuildContext context, Teaching item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlayerScreen(teaching: item)),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return "${duration.inHours}h ${duration.inMinutes.remainder(60)}m";
    } else {
      return "${duration.inMinutes}m";
    }
  }
}

// --- Standard Lists for Video & Text ---

class _TeachingsList extends StatelessWidget {
  final TeachingType type;
  const _TeachingsList({required this.type});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeachingsProvider>(context);
    final list = provider.teachings.where((t) => t.type == type).toList();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return Center(child: Text("Aucun contenu", style: GoogleFonts.poppins()));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(teaching: item),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: item.thumbnailUrl != null
                        ? DecorationImage(image: NetworkImage(item.thumbnailUrl!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      size: 50,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.titleFr, 
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.author?.name ?? "Inconnu",
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ArticlesList extends StatelessWidget {
  const _ArticlesList();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeachingsProvider>(context);
    
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.articles.isEmpty) {
      return Center(child: Text("Aucun article", style: GoogleFonts.poppins()));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.articles.length,
      itemBuilder: (context, index) {
        final article = provider.articles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: const Icon(Icons.article, size: 40, color: AppColors.tealPrimary),
            title: Text(article.titleFr, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text("${article.readTimeMinutes} min de lecture", style: GoogleFonts.poppins(fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleReaderScreen(article: article),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
