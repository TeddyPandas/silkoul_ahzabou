import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import '../../models/campaign.dart';

import '../../providers/auth_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/user_provider.dart';

import '../../config/app_theme.dart';
import '../../widgets/custom_drawer.dart';

import '../campaigns/campaign_details_screen.dart';
import '../campaigns/create_campaign_screen.dart';
import '../wazifa/wazifa_map_screen.dart';
import '../wazifa/add_wazifa_screen.dart';
import '../nafahat/nafahat_screen.dart';
import '../silsila/silsila_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../utils/l10n_extensions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _showMyCampaignsOnTab = false;
  bool _fabOpen = false;

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
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
      } catch (e) {
        debugPrint('❌ [HomeScreen] Error during data refresh: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  void _onTabChange(int index, {bool showMyCampaigns = false}) {
    setState(() {
      _currentIndex = index;
      _showMyCampaignsOnTab = showMyCampaigns;
      _fabOpen = false; // Close Speed Dial when switching tabs
    });
  }

  void _toggleFab() {
    HapticFeedback.mediumImpact();
    setState(() => _fabOpen = !_fabOpen);
  }

  void _closeFab() => setState(() => _fabOpen = false);

  void _navigateToCreateCampaign() async {
    _closeFab();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateCampaignScreen()),
    );
    _refreshData();
  }

  void _navigateToAddWazifa() async {
    _closeFab();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddWazifaScreen()),
    );
  }

  static const _tabIcons = [
    Icons.home_rounded,
    Icons.auto_stories_rounded,
    Icons.location_on_rounded,
    Icons.article_rounded,
  ];
  // Replaced static _tabLabels with dynamic labels in build()

  // The CurvedNavigationBar uses 5 items: 4 tabs + center "+" button.
  // Indices: 0=Accueil, 1=Campagnes, 2=FAB(+), 3=Wazifa, 4=Nafahat
  // We map _currentIndex (0-3 for tabs) to the CurvedNavigationBar index (0,1,3,4)
  int _toNavIndex(int tabIndex) {
    if (tabIndex < 2) return tabIndex;      // 0->0, 1->1
    return tabIndex + 1;                     // 2->3, 3->4
  }

  int _toTabIndex(int navIndex) {
    if (navIndex < 2) return navIndex;       // 0->0, 1->1
    if (navIndex > 2) return navIndex - 1;  // 3->2, 4->3
    return _currentIndex; // 2 = FAB, keep current tab
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardTab(onTabChange: _onTabChange, onRefresh: _refreshData),
      CampaignsTab(
        key: ValueKey('campaigns_$_showMyCampaignsOnTab'),
        showMyCampaigns: _showMyCampaignsOnTab,
      ),
      const WazifaMapScreen(),
      const NafahatScreen(),
    ];

    final isGuest = context.watch<AuthProvider>().isGuest;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          // ── Main content ──
          Positioned.fill(
            child: screens[_currentIndex],
          ),

          // ── Backdrop (tap outside to close Speed Dial) ──
          if (_fabOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeFab,
                child: Container(color: Colors.black45),
              ),
            ),

          // ── Speed Dial mini-buttons (hidden for guests) ──
          if (_fabOpen && !isGuest)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSpeedDialItem(
                    visible: true,
                    delay: 0,
                    icon: Icons.add_location_alt_rounded,
                    label: context.l10n.findWazifa,
                    color: AppColors.secondary,
                    onTap: _navigateToAddWazifa,
                  ),
                  const SizedBox(height: 12),
                  _buildSpeedDialItem(
                    visible: true,
                    delay: 50,
                    icon: Icons.campaign_rounded,
                    label: context.l10n.createCampaign,
                    color: AppColors.tealPrimary,
                    onTap: _navigateToCreateCampaign,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
        ],
      ),

      // ── CurvedNavigationBar: handles pill, notch, animation natively ──
      bottomNavigationBar: CurvedNavigationBar(
        index: _toNavIndex(_currentIndex),
        height: 65,
        backgroundColor: Colors.transparent,
        color: Colors.white,
        buttonBackgroundColor: _fabOpen ? AppColors.tealPrimary : Colors.white,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        items: [
          _buildNavIcon(0, _tabIcons[0]),    // Accueil
          _buildNavIcon(1, _tabIcons[1]),    // Campagnes
          // Center "+" button
          AnimatedRotation(
            duration: const Duration(milliseconds: 300),
            turns: _fabOpen ? 0.125 : 0,
            child: Icon(
              Icons.add_rounded,
              size: 30,
              color: _fabOpen ? Colors.white : AppColors.tealPrimary,
            ),
          ),
          _buildNavIcon(2, _tabIcons[2]),    // Wazifa
          _buildNavIcon(3, _tabIcons[3]),    // Nafahat
        ],
        onTap: (navIndex) {
          HapticFeedback.selectionClick();
          if (navIndex == 2) {
            // Center button = FAB toggle
            _toggleFab();
          } else {
            _closeFab();
            final tabIndex = _toTabIndex(navIndex);
            setState(() => _currentIndex = tabIndex);
            if (tabIndex == 1) {
              final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
              if (userId != null) {
                Provider.of<CampaignProvider>(context, listen: false)
                    .fetchMyCampaigns(userId: userId, onlyCreated: false);
              }
            }
          }
        },
      ),
    );
  }

  Widget _buildNavIcon(int tabIndex, IconData icon) {
    final isSelected = _currentIndex == tabIndex;
    return Icon(
      icon,
      size: 24,
      color: isSelected ? AppColors.tealPrimary : Colors.grey[400],
    );
  }

  Widget _buildSpeedDialItem({
    required bool visible,
    required int delay,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AnimatedSlide(
      duration: Duration(milliseconds: visible ? 300 + delay : 200),
      curve: visible ? Curves.easeOutBack : Curves.easeIn,
      offset: visible ? Offset.zero : const Offset(0, 0.5),
      child: AnimatedOpacity(
        duration: Duration(milliseconds: visible ? 250 + delay : 150),
        opacity: visible ? 1.0 : 0.0,
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }


} // end _HomeScreenState

// ══════════════════════════════════════════════════════════════════════════


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
                    Text(
                      context.l10n.myTasks,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    if (provider.myCampaigns.length > 5)
                      TextButton(
                        onPressed: () =>
                            widget.onTabChange(1, showMyCampaigns: true),
                        child: Text(context.l10n.viewAll),
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
                      title: context.l10n.welcome,
                      subtitle: context.l10n.joinFirstCampaign,
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
                        subtitle: campaign.description ?? context.l10n.zikrCampaign,
                        subscribersCount: campaign.subscribersCount,
                        imageUrl:
                            'https://images.unsplash.com/photo-1584551246679-0daf3d275d0f?q=80&w=800&auto=format&fit=crop',
                        tag: campaign.isWeekly 
                            ? context.l10n.weekly 
                            : context.l10n.oneTime,
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
                    Text(
                      context.l10n.recommendedCampaigns,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    if (provider.campaigns.length > 5)
                      TextButton(
                        onPressed: () => widget.onTabChange(1),
                        child: Text(context.l10n.viewAll),
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
                      return SizedBox(
                        height: 100,
                        child: Center(child: Text(context.l10n.noCampaignsFound)));
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
                            context.l10n.by(campaign.createdByName ?? context.l10n.unknownAuthor),
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
                _buildQuickAction(
                    Icons.link,
                    context.l10n.silsila,
                    AppColors.tealPrimary,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SilsilaScreen())
                    )
                ),
                _buildQuickAction(
                    Icons.place, context.l10n.findWazifa, AppColors.tealAccent,
                    onTap: () => widget.onTabChange(2)),
                // _buildQuickAction(Icons.emoji_events, 'Badges', Colors.amber),
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
        Text(
          context.l10n.appTitle,
          style: const TextStyle(
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
                Text(context.l10n.infoSection,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(context.l10n.clickForDetails,
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
                            child: Text(context.l10n.public,
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
                            child: Text(context.l10n.private,
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
                            child: Text(context.l10n.completed,
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
                            child: Text(context.l10n.ongoing,
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

