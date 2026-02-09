import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/nafahat_article.dart';
import '../../providers/nafahat_provider.dart';
import '../../widgets/nafahat/article_card.dart';
import 'article_detail_screen.dart';

/// Main Nafahat Screen - Articles List
class NafahatScreen extends StatefulWidget {
  const NafahatScreen({super.key});

  @override
  State<NafahatScreen> createState() => _NafahatScreenState();
}

class _NafahatScreenState extends State<NafahatScreen> {
  final ScrollController _scrollController = ScrollController();
  ArticleCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NafahatProvider>();
      provider.initialize();
      provider.fetchArticles(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more articles when near bottom
      context.read<NafahatProvider>().fetchArticles();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<NafahatProvider>().refresh();
  }

  void _onCategorySelected(ArticleCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    context.read<NafahatProvider>().setCategory(category);
  }

  void _navigateToArticle(NafahatArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArticleDetailScreen(article: article),
      ),
    );
  }

  void _navigateToSearch() {
    showSearch(
      context: context,
      delegate: _ArticleSearchDelegate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.tealPrimary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  const Text(
                    'نفحات',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.tealPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nafahat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: Colors.grey.shade700),
                  onPressed: _navigateToSearch,
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Featured Articles Carousel
            SliverToBoxAdapter(
              child: Consumer<NafahatProvider>(
                builder: (context, provider, child) {
                  if (provider.isFeaturedLoading) {
                    return Container(
                      height: 220,
                      padding: const EdgeInsets.all(16),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (provider.featuredArticles.isEmpty) {
                    return const SizedBox();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.tealPrimary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '⭐ À la une',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: provider.featuredArticles.length,
                          itemBuilder: (context, index) {
                            final article = provider.featuredArticles[index];
                            return FeaturedArticleCard(
                              article: article,
                              onTap: () => _navigateToArticle(article),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Category Filter Chips
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.tealPrimary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '📂 Catégories',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // All categories chip
                          _buildCategoryChip(
                            label: 'Tous',
                            icon: '📚',
                            isSelected: _selectedCategory == null,
                            onTap: () => _onCategorySelected(null),
                          ),
                          // Category chips
                          ...ArticleCategory.values.map((category) {
                            return _buildCategoryChip(
                              label: category.label,
                              icon: category.icon,
                              color: Color(category.colorValue),
                              isSelected: _selectedCategory == category,
                              onTap: () => _onCategorySelected(category),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Articles Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.tealPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategory != null
                          ? '${_selectedCategory!.icon} ${_selectedCategory!.label}'
                          : '📰 Articles récents',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Consumer<NafahatProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          '${provider.allArticles.length} articles',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Articles List
            Consumer<NafahatProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.allArticles.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (provider.error != null && provider.allArticles.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _onRefresh,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (provider.allArticles.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '📭',
                            style: TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun article trouvé',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_selectedCategory != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => _onCategorySelected(null),
                              child: const Text('Voir tous les articles'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == provider.allArticles.length) {
                          // Loading indicator at bottom
                          if (provider.hasMore) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          return const SizedBox();
                        }

                        final article = provider.allArticles[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ArticleCard(
                            article: article,
                            onTap: () => _navigateToArticle(article),
                          ),
                        );
                      },
                      childCount: provider.allArticles.length + 1,
                    ),
                  ),
                );
              },
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required String icon,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final chipColor = color ?? AppColors.tealPrimary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : chipColor,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.white,
        selectedColor: chipColor,
        showCheckmark: false,
        side: BorderSide(
          color: isSelected ? chipColor : chipColor.withOpacity(0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

/// Search Delegate for Articles
class _ArticleSearchDelegate extends SearchDelegate<NafahatArticle?> {
  @override
  String get searchFieldLabel => 'Rechercher un article...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Recherchez en français ou en arabe',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Exemple: tariqa, ورد, dhikr...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    // Trigger search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NafahatProvider>().searchArticles(query);
    });

    return Consumer<NafahatProvider>(
      builder: (context, provider, child) {
        if (provider.isSearching) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.searchResults.isEmpty && query.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun résultat pour "$query"',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.searchResults.length,
          itemBuilder: (context, index) {
            final article = provider.searchResults[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ArticleCard(
                article: article,
                compact: true,
                onTap: () {
                  close(context, article);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleDetailScreen(article: article),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
