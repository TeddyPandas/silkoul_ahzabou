
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/teaching_service.dart';
import '../models/teaching.dart';
import '../models/article.dart';
import 'player_screen.dart';
import 'article_reader_screen.dart';

import '../models/podcast_show.dart';
import 'podcast_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TeachingService _service = TeachingService.instance;
  
  List<PodcastShow> _foundShows = [];
  List<Teaching> _foundTeachings = [];
  List<Article> _foundArticles = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _service.searchContent(query);
      setState(() {
        _foundShows = (results['shows'] as List?)?.cast<PodcastShow>() ?? [];
        _foundTeachings = results['teachings'] as List<Teaching>;
        _foundArticles = results['articles'] as List<Article>;
      });
    } catch (e) {
      debugPrint("Search error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la recherche: $e")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Rechercher...",
            border: InputBorder.none,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
          ),
          style: GoogleFonts.poppins(color: Colors.black, fontSize: 18),
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildResults(),
    );
  }

  Widget _buildResults() {
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "Recherchez des émissions, enseignements ou articles",
              style: GoogleFonts.poppins(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (_foundShows.isEmpty && _foundTeachings.isEmpty && _foundArticles.isEmpty) {
      return Center(
        child: Text("Aucun résultat trouvé", style: GoogleFonts.poppins()),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_foundShows.isNotEmpty) ...[
          Text("Émissions", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          ..._foundShows.map((s) => _buildShowTile(s)),
          const SizedBox(height: 24),
        ],

        if (_foundTeachings.isNotEmpty) ...[
          Text("Vidéos & Audios", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          ..._foundTeachings.map((t) => _buildTeachingTile(t)),
          const SizedBox(height: 24),
        ],
        
        if (_foundArticles.isNotEmpty) ...[
          Text("Articles", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          ..._foundArticles.map((a) => _buildArticleTile(a)),
        ],
      ],
    );
  }

  Widget _buildShowTile(PodcastShow item) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          image: item.imageUrl != null
              ? DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: item.imageUrl == null
            ? const Icon(Icons.podcasts, color: Colors.grey)
            : null,
      ),
      title: Text(item.titleFr, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(item.author?.name ?? "Inconnu"),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PodcastDetailsScreen(show: item)),
        );
      },
    );
  }

  Widget _buildTeachingTile(Teaching item) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          image: item.thumbnailUrl != null
              ? DecorationImage(image: NetworkImage(item.thumbnailUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: item.thumbnailUrl == null
            ? Icon(item.type == TeachingType.VIDEO ? Icons.play_arrow : Icons.mic, color: Colors.grey)
            : null,
      ),
      title: Text(item.titleFr, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(item.author?.name ?? "Inconnu"),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlayerScreen(teaching: item)),
        );
      },
    );
  }

  Widget _buildArticleTile(Article item) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.article, size: 40, color: Colors.blueGrey),
      title: Text(item.titleFr, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text("${item.readTimeMinutes} min • ${item.author?.name ?? 'Inconnu'}"),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ArticleReaderScreen(article: item)),
        );
      },
    );
  }
}
