import 'package:flutter/material.dart';

import 'package:provider/provider.dart';



import '../../models/campaign.dart';

import '../../providers/auth_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/user_provider.dart';

import '../../utils/app_theme.dart';
import '../../widgets/custom_drawer.dart'; // Import CustomDrawer

import '../campaigns/campaign_details_screen.dart';
import '../campaigns/create_campaign_screen.dart';
import '../wazifa/wazifa_map_screen.dart';
import '../nafahat/nafahat_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _showMyCampaignsOnTab = false;

  // Method to refresh data, can be passed down or called after navigation
  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    debugPrint('🔄 [HomeScreen] _refreshData called. userId: $userId');

    if (userId != null) {
      final campaignProvider =
          Provider.of<CampaignProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      try {
        await Future.wait([
          campaignProvider.fetchCampaigns(),
          campaignProvider.fetchMyCampaigns(userId: userId, onlyCreated: false),
          userProvider.loadAllUserTasks(userId: userId, onlyIncomplete: true),
          userProvider.loadUserStats(userId: userId),
        ]);
        debugPrint(
            '✅ [HomeScreen] Data refresh complete. Campaigns: ${campaignProvider.campaigns.length}, My Campaigns: ${campaignProvider.myCampaigns.length}');
      } catch (e) {
        debugPrint('❌ [HomeScreen] Error during data refresh: $e');
      }
    } else {
      debugPrint('⚠️ [HomeScreen] No userId found, skipping data refresh');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _onTabChange(int index, {bool showMyCampaigns = false}) {
    setState(() {
      _currentIndex = index;
      _showMyCampaignsOnTab = showMyCampaigns;
    });
  }

  void _navigateToCreateCampaign() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateCampaignScreen()),
    );

    // Refresh data after returning from create screen
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    // We build screens dynamically to access 'context' and pass methods
    final List<Widget> screens = [
      DashboardTab(
        onTabChange: _onTabChange,
        onRefresh: _refreshData,
      ),
      CampaignsTab(
          key: ValueKey('campaigns_$_showMyCampaignsOnTab'),
          showMyCampaigns: _showMyCampaignsOnTab),
      const WazifaMapScreen(), // Wazifa Finder
      const NafahatScreen(), // Nafahat
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: const CustomDrawer(), // Add CustomDrawer here
      body: screens[_currentIndex],
      floatingActionButton: Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.only(top: 30), // Adjust to sit nicely in notch
        child: FloatingActionButton(
          heroTag: 'create_campaign_fab',
          onPressed: _navigateToCreateCampaign,
          backgroundColor: AppColors.tealPrimary,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 32, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomAppBar(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 70,
          color: Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_rounded, 'Accueil', 0),
              _buildNavItem(Icons.auto_stories_rounded, 'Campagnes', 1),
              const SizedBox(width: 48), // Spacer for FAB
              _buildNavItem(Icons.search_rounded, 'Wazifa', 2),
              _buildNavItem(Icons.article_rounded, 'Nafahat', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () async {
          setState(() => _currentIndex = index);
          // Refresh data when switching tabs to ensure up-to-date content
          if (index == 1) {
            // Campaigns tab
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final userId = authProvider.user?.id;
            if (userId != null) {
              Provider.of<CampaignProvider>(context, listen: false)
                  .fetchMyCampaigns(userId: userId, onlyCreated: false);
            }
          }
        },
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.tealPrimary.withValues(alpha: 0.1)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.tealPrimary : Colors.grey[400],
                size: isSelected ? 26 : 24,
              ),
            ),
            if (isSelected)
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.tealPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ... DashboardTab remains mostly same ...
class DashboardTab extends StatefulWidget {
  final Function(int, {bool showMyCampaigns}) onTabChange;
  final Future<void> Function() onRefresh;

  const DashboardTab({
    super.key,
    required this.onTabChange,
    required this.onRefresh,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _currentCampaignIndex = 0;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: AppColors.tealPrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildInfoBanner(),
            const SizedBox(height: 24),
            // Mes campagnes header with Voir tout button
            Consumer<CampaignProvider>(
              builder: (context, provider, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mes Campagnes',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    if (provider.myCampaigns.length > 5)
                      TextButton(
                        onPressed: () =>
                            widget.onTabChange(1, showMyCampaigns: true),
                        child: const Text('Voir tout'),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Consumer<CampaignProvider>(
              builder: (context, provider, _) {
                if (provider.myCampaigns.isEmpty) {
                  return SizedBox(
                    height: 180,
                    child: _buildHeroCard(
                      context: context,
                      title: 'Bienvenue sur Ahzab',
                      subtitle: 'Rejoignez votre première campagne !',
                      subscribersCount: 0,
                      imageUrl:
                          'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?q=80&w=200&auto=format&fit=crop',
                      tag: 'Info',
                    ),
                  );
                }

                final int displayCount = provider.myCampaigns.length > 5
                    ? 5
                    : provider.myCampaigns.length;

                return SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.92),
                    onPageChanged: (index) {
                      setState(() {
                        _currentCampaignIndex = index;
                      });
                    },
                    itemCount: displayCount,
                    itemBuilder: (context, index) {
                      final campaign = provider.myCampaigns[index];
                      return _buildHeroCard(
                        context: context,
                        campaignId: campaign.id,
                        title: campaign.name,
                        subtitle: campaign.description ?? 'Campagne Zikr',
                        subscribersCount: campaign.subscribersCount,
                        imageUrl:
                            'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?q=80&w=800&auto=format&fit=crop',
                        tag: campaign.isWeekly ? 'Hebdomadaire' : 'Ponctuelle',
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Indicators
            Consumer<CampaignProvider>(builder: (context, provider, _) {
              if (provider.myCampaigns.length <= 1) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    provider.myCampaigns.length.clamp(0, 5),
                    (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: _currentCampaignIndex == index
                                  ? AppColors.tealPrimary
                                  : AppColors.tealPrimary.withValues(alpha: 0.3),
                              shape: BoxShape.circle),
                        )),
              );
            }),
            const SizedBox(height: 24),
            Consumer<CampaignProvider>(
              builder: (context, provider, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Campagnes Recommandées',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    if (provider.campaigns.length > 5)
                      TextButton(
                        onPressed: () => widget.onTabChange(1),
                        child: const Text('Voir tout'),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            // Responsive campaign thumbnails using LayoutBuilder
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate thumbnail width based on available space
                // Show ~3 items on small screens, more on larger
                final screenWidth = constraints.maxWidth;
                final thumbnailWidth = (screenWidth / 3).clamp(100.0, 140.0);
                final imageHeight = thumbnailWidth * 0.85; // Aspect ratio
                // Fixed text space (4px spacing + 13px title + 11px subtitle + buffer)
                final containerHeight = imageHeight + 50;

                return Consumer<CampaignProvider>(
                  builder: (context, provider, _) {
                    if (provider.campaigns.isEmpty) {
                      return const SizedBox(
                          height: 100,
                          child: Center(child: Text("Aucune campagne")));
                    }
                    return SizedBox(
                      height: containerHeight,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.campaigns.length > 5
                            ? 5
                            : provider.campaigns.length,
                        itemBuilder: (context, index) {
                          final campaign = provider.campaigns[index];
                          return _buildCampaignThumbnail(
                            campaign.name,
                            'Par ${campaign.createdByName ?? "Inconnu"}',
                            null,
                            thumbnailWidth,
                            imageHeight,
                            () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CampaignDetailsScreen(campaignId: campaign.id),
                                ),
                              );
                              if (mounted) {
                                widget.onRefresh();
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickAction(Icons.link, 'Silsila', AppColors.tealPrimary),
                _buildQuickAction(
                    Icons.place, 'Wazifa Finder', AppColors.tealAccent,
                    onTap: () => widget.onTabChange(2)),
                _buildQuickAction(Icons.emoji_events, 'Badges', Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          style: IconButton.styleFrom(
              backgroundColor: Colors.white, padding: EdgeInsets.zero),
        ),
        const Text(
          'Découvrir',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Consumer<CampaignProvider>(
          builder: (context, provider, child) {
            final hasNotifications = provider.hasUnreadNotifications;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: Colors.black87),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsScreen()),
                    );
                  },
                  style: IconButton.styleFrom(
                      backgroundColor: Colors.white, padding: EdgeInsets.zero),
                ),
                if (hasNotifications)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeroCard(
      {required BuildContext context,
      String? campaignId,
      required String title,
      required String subtitle,
      required int subscribersCount,
      required String imageUrl,
      required String tag}) {
    return GestureDetector(
      onTap: campaignId != null
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CampaignDetailsScreen(campaignId: campaignId),
                ),
              );
              // Refresh my campaigns on return
              if (context.mounted) {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                final userId = authProvider.user?.id;
                if (userId != null) {
                  Provider.of<CampaignProvider>(context, listen: false)
                      .fetchMyCampaigns(userId: userId, onlyCreated: false);
                }
              }
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: DecorationImage(
                image: NetworkImage(imageUrl), fit: BoxFit.cover),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ]),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_alt,
                        color: Colors.blueAccent, size: 16),
                    const SizedBox(width: 4),
                    Text('$subscribersCount',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.tealPrimary,
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(tag,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(subtitle,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    // ... Same implementation ...
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5))
          ]),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                  image: NetworkImage(
                      'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?q=80&w=200&auto=format&fit=crop'),
                  fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Section d'information",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Cliquez pour voir plus de détails.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  // Responsive campaign thumbnail
  Widget _buildCampaignThumbnail(
      String title, String subtitle, String? imageUrl,
      [double width = 120, double imageHeight = 100, VoidCallback? onTap]) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: imageHeight,
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[300],
              image: const DecorationImage(
                image: AssetImage('assets/images/miniature_zikr.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
    );
  }

  // Responsive quick action - uses Expanded in parent Row
  Widget _buildQuickAction(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5))
            ]),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
          ],
        ),
        ),
      ),
    );
  }
}

// ============================================
// Tab 2: Campaigns (Full Implementation with Filter)
// ============================================
class CampaignsTab extends StatefulWidget {
  final bool showMyCampaigns;

  const CampaignsTab({super.key, this.showMyCampaigns = false});

  @override
  State<CampaignsTab> createState() => _CampaignsTabState();
}

class _CampaignsTabState extends State<CampaignsTab> {
  late bool _showMyCampaigns;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _showMyCampaigns = widget.showMyCampaigns;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CampaignsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showMyCampaigns != widget.showMyCampaigns) {
      setState(() {
        _showMyCampaigns = widget.showMyCampaigns;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Column(
      children: [
        // App Bar with title
        Container(
          padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 8),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _showMyCampaigns ? 'Mes Campagnes' : 'Toutes les Campagnes',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Filter Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showMyCampaigns = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _showMyCampaigns
                                ? AppColors.tealPrimary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Mes campagnes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _showMyCampaigns
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showMyCampaigns = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_showMyCampaigns
                                ? AppColors.tealPrimary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Toutes',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_showMyCampaigns
                                  ? Colors.white
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Rechercher une campagne...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: Consumer<CampaignProvider>(
            builder: (context, provider, _) {
              // Note: We move isLoading check inside RefreshIndicator content to allow refresh even if empty

              final allCampaigns =
                  _showMyCampaigns ? provider.myCampaigns : provider.campaigns;

              // Filter campaigns based on search query
              final campaigns = _searchQuery.isEmpty
                  ? allCampaigns
                  : allCampaigns.where((c) {
                      final name = c.name.toLowerCase();
                      final description = (c.description ?? '').toLowerCase();
                      final creatorName = (c.createdByName ?? '').toLowerCase();
                      return name.contains(_searchQuery) ||
                          description.contains(_searchQuery) ||
                          creatorName.contains(_searchQuery);
                    }).toList();

              Widget content;
              if (provider.isLoading && campaigns.isEmpty) {
                content = const Center(child: CircularProgressIndicator());
              } else if (campaigns.isEmpty) {
                content = SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _showMyCampaigns
                                ? Icons.bookmark_border
                                : Icons.search_off,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showMyCampaigns
                                ? "Vous n'avez pas encore rejoint de campagne."
                                : "Aucune campagne publique disponible.",
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                content = ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 180),
                  itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = campaigns[index];
                    return _buildCampaignCard(context, campaign);
                  },
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  final userId = authProvider.user?.id;

                  // Refresh both lists to be safe, or just the current one
                  final campaignProvider =
                      Provider.of<CampaignProvider>(context, listen: false);
                  await Future.wait([
                    campaignProvider.fetchCampaigns(),
                    if (userId != null)
                      campaignProvider.fetchMyCampaigns(
                          userId: userId, onlyCreated: false),
                  ]);
                },
                color: AppColors.tealPrimary,
                child: content,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCampaignCard(BuildContext context, Campaign campaign) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CampaignDetailsScreen(campaignId: campaign.id),
            ),
          );
          // Refresh my campaigns on return to update subscription status
          if (context.mounted) {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            final userId = authProvider.user?.id;
            if (userId != null) {
              Provider.of<CampaignProvider>(context, listen: false)
                  .fetchMyCampaigns(userId: userId, onlyCreated: false);
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage(
                          'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?q=80&w=200&auto=format&fit=crop'),
                      fit: BoxFit.cover,
                    )),
                child: const Center(
                    child: Icon(Icons.mosque, color: Colors.white)),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaign.description ?? "Pas de description",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 14, color: AppColors.tealPrimary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  campaign.createdByName ?? 'Inconnu',
                                  style: const TextStyle(
                                      color: AppColors.tealPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (campaign.isPublic)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(4)),
                            child: Text('Public',
                                style: TextStyle(
                                    color: Colors.green[800], fontSize: 10)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(4)),
                            child: Text('Privé',
                                style: TextStyle(
                                    color: Colors.amber[800], fontSize: 10)),
                          ),
                        const SizedBox(width: 8),
                        if (campaign.isFinished)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4)),
                            child: Text('Terminée',
                                style: TextStyle(
                                    color: Colors.grey[800], fontSize: 10)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4)),
                            child: Text('En cours',
                                style: TextStyle(
                                    color: Colors.blue[800], fontSize: 10)),
                          ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ... CommunityTab remains placeholder ...
class CommunityTab extends StatelessWidget {
  const CommunityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 180),
      child: const Center(child: Text('Communauté - À venir')),
    );
  }
}
