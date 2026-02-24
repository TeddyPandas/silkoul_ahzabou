import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../providers/quiz_provider.dart';
import '../models/quiz_models.dart';
import 'quiz_game_screen.dart';
import 'leaderboard_screen.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QuizProvider>().loadQuizzes();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _initializeTabs(List<String> categories) {
    if (_tabController == null || _tabController!.length != categories.length) {
      _tabController?.dispose();
      _tabController = TabController(length: categories.length, vsync: this);
      _categories = categories;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Soft background to let glassmorphism pop
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.quizzes.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.error != null && provider.quizzes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => provider.loadQuizzes(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.quizzes.isEmpty) {
            return const Center(
              child: Text('Aucun quiz disponible pour le moment.',
                  style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          // Extract unique categories
          final categoriesSet = provider.quizzes.map((q) => q.category).toSet().toList();
          categoriesSet.sort(); // Sort alphabetically
          
          // Re-initialize tabs if categories changed
          if (_categories.length != categoriesSet.length || 
              !_categories.every((c) => categoriesSet.contains(c))) {
            _initializeTabs(categoriesSet);
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              if (_categories.isNotEmpty)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: AppColors.gold,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.gold,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                      tabs: _categories.map((category) => Tab(text: category)).toList(),
                    ),
                  ),
                ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: _categories.map((category) {
                    final categoryQuizzes = provider.quizzes.where((q) => q.category == category).toList();
                    return _buildQuizGrid(categoryQuizzes, provider.completedQuizIds);
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primaryDark,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.leaderboard_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
              ),
            ),
            // Decorative Pattern Overlay (Using an icon as a subtle pattern)
            Positioned(
              right: -50,
              top: -50,
              child: Icon(
                Icons.mosque_rounded,
                size: 300,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            // Header Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                      ),
                      child: const Text(
                        'Apprentissage',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Quizz Islamique',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Testez et enrichissez vos connaissances',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
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

  Widget _buildQuizGrid(List<Quiz> quizzes, List<String> completedQuizIds) {
    if (quizzes.isEmpty) {
      return const Center(child: Text("Aucun quiz dans cette catégorie."));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 40),
      itemCount: quizzes.length,
      itemBuilder: (context, index) {
        final quiz = quizzes[index];
        final isCompleted = completedQuizIds.contains(quiz.id);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: _buildGlassmorphicQuizCard(quiz, isCompleted),
        );
      },
    );
  }

  Widget _buildGlassmorphicQuizCard(Quiz quiz, bool isCompleted) {
    return GestureDetector(
      onTap: () => _handleQuizTap(quiz, isCompleted),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image
              if (quiz.imageUrl != null)
                quiz.imageUrl!.startsWith('assets/')
                    ? Image.asset(quiz.imageUrl!, fit: BoxFit.cover)
                    : CachedNetworkImage(
                        imageUrl: quiz.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppColors.primary),
                        errorWidget: (context, url, error) => Container(color: AppColors.primary),
                      )
              else
                Container(color: AppColors.primary),

              // 2. Dark Gradient Overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // 3. Glassmorphism Info Panel (Bottom)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  quiz.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCompleted)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildDifficultyBadge(quiz.difficulty),
                              const Spacer(),
                              Text(
                                isCompleted ? 'Terminé' : 'Commencer',
                                style: TextStyle(
                                  color: isCompleted ? AppColors.success : AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isCompleted ? Icons.check_circle_outline : Icons.play_circle_fill,
                                color: isCompleted ? AppColors.success : AppColors.gold,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleQuizTap(Quiz quiz, bool isCompleted) {
    if (!isCompleted) {
      // Normal flow: Start the quiz
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizGameScreen(quiz: quiz, isReviewMode: false, isPracticeMode: false),
        ),
      );
      return;
    }

    // Completed flow: Show options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(quiz.title),
        content: const Text("Vous avez déjà complété ce quiz. Que souhaitez-vous faire ?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizGameScreen(quiz: quiz, isReviewMode: true, isPracticeMode: false),
                ),
              );
            },
            icon: const Icon(Icons.visibility),
            label: const Text("Revoir", style: TextStyle(fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizGameScreen(quiz: quiz, isReviewMode: false, isPracticeMode: true),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text("S'entraîner"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'easy':
        color = const Color(0xFF4ADE80); // Bright Green
        break;
      case 'medium':
        color = const Color(0xFFFBBF24); // Warm amber
        break;
      case 'hard':
        color = const Color(0xFFF87171); // Soft red
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        difficulty,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white, // Background behind the tabs
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
