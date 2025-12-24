import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/tijani_article.dart';
import '../providers/tijani_article_provider.dart';
import '../widgets/article_card.dart';

/// Article Detail Screen
/// Displays full article content with reading experience optimized
class ArticleDetailScreen extends StatefulWidget {
  final TijaniArticle article;

  const ArticleDetailScreen({
    Key? key,
    required this.article,
  }) : super(key: key);

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _isLiked = false;
  bool _showArabic = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadArticle();
  }

  Future<void> _loadArticle() async {
    final provider = context.read<TijaniArticleProvider>();
    await provider.setCurrentArticle(widget.article);
    
    // Check like status if user is authenticated
    final userId = 'current-user-id'; // Get from auth provider
    _isLiked = provider.likedArticleIds.contains(widget.article.id);
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildContent(context),
                _buildTags(context),
                _buildRelatedArticles(context),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildActionButtons(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: widget.article.imageUrl != null ? 300 : 100,
      pinned: true,
      backgroundColor: const Color(0xFF0FA958),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.article.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3,
                color: Colors.black45,
              ),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        background: widget.article.imageUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.article.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : null,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareArticle,
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_border),
          onPressed: () {
            // TODO: Implement bookmark
          },
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category & badges
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryChip(context),
              if (widget.article.isNew) _buildNewChip(),
              if (widget.article.isFeatured) _buildFeaturedChip(),
              if (widget.article.isVerified) _buildVerifiedChip(),
            ],
          ),

          const SizedBox(height: 16),

          // Title (if no image)
          if (widget.article.imageUrl == null)
            Text(
              widget.article.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),

          const SizedBox(height: 8),

          // Arabic title toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.article.titleAr,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
              IconButton(
                icon: Icon(
                  _showArabic ? Icons.translate : Icons.translate_outlined,
                  color: const Color(0xFF0FA958),
                ),
                onPressed: () {
                  setState(() {
                    _showArabic = !_showArabic;
                  });
                },
                tooltip: _showArabic ? 'Afficher en français' : 'Afficher en arabe',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Author info
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF0FA958),
                child: Text(
                  widget.article.authorName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.article.authorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.article.authorNameAr != null)
                      Text(
                        widget.article.authorNameAr!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Cairo',
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Meta info
          Row(
            children: [
              _buildMetaItem(
                Icons.access_time,
                '${widget.article.estimatedReadTime} min de lecture',
              ),
              const SizedBox(width: 16),
              _buildMetaItem(
                Icons.calendar_today,
                widget.article.formattedPublishDate,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Stats
          Row(
            children: [
              _buildStatItem(Icons.visibility, widget.article.viewCount, 'vues'),
              const SizedBox(width: 16),
              _buildStatItem(Icons.favorite, widget.article.likeCount, 'j\'aime'),
              const SizedBox(width: 16),
              _buildStatItem(Icons.share, widget.article.shareCount, 'partages'),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SelectableText(
        _showArabic ? widget.article.contentAr : widget.article.content,
        style: TextStyle(
          fontSize: 17,
          height: 1.7,
          color: Colors.grey[800],
          fontFamily: _showArabic ? 'Cairo' : null,
        ),
        textDirection: _showArabic ? TextDirection.rtl : TextDirection.ltr,
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    final tags = _showArabic ? widget.article.tagsAr : widget.article.tags;
    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Mots-clés',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) => Chip(
              label: Text(tag),
              backgroundColor: Colors.grey[200],
              labelStyle: const TextStyle(fontSize: 13),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedArticles(BuildContext context) {
    return Consumer<TijaniArticleProvider>(
      builder: (context, provider, child) {
        if (provider.relatedArticles.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Articles liés',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...provider.relatedArticles.map((article) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ArticleCard(
                  article: article,
                  compact: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArticleDetailScreen(article: article),
                      ),
                    );
                  },
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'like',
          backgroundColor: _isLiked ? Colors.red : Colors.grey[300],
          onPressed: _toggleLike,
          child: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.white : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'scroll',
          backgroundColor: const Color(0xFF0FA958),
          onPressed: _scrollToTop,
          child: const Icon(Icons.arrow_upward, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(BuildContext context) {
    final color = Color(int.parse(widget.article.category.color.replaceFirst('#', '0xFF')));
    
    return Chip(
      avatar: Text(widget.article.category.icon),
      label: Text(widget.article.category.label),
      backgroundColor: color.withOpacity(0.1),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildNewChip() {
    return const Chip(
      label: Text('Nouveau'),
      backgroundColor: Colors.green,
      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  Widget _buildFeaturedChip() {
    return const Chip(
      avatar: Text('⭐'),
      label: Text('À la Une'),
      backgroundColor: Color(0xFFD4AF37),
      labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildVerifiedChip() {
    return const Chip(
      avatar: Icon(Icons.verified, size: 16, color: Colors.white),
      label: Text('Vérifié'),
      backgroundColor: Colors.blue,
      labelStyle: TextStyle(color: Colors.white, fontSize: 12),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, int count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Future<void> _toggleLike() async {
    final provider = context.read<TijaniArticleProvider>();
    final userId = 'current-user-id'; // Get from auth provider
    
    await provider.toggleLike(widget.article.id, userId);
    
    setState(() {
      _isLiked = !_isLiked;
    });
  }

  void _shareArticle() {
    final provider = context.read<TijaniArticleProvider>();
    provider.shareArticle(widget.article.id);
    
    Share.share(
      '${widget.article.title}\n\n${widget.article.summary}\n\nLire sur Silkoul Ahzabou Tidiani',
      subject: widget.article.title,
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
}
