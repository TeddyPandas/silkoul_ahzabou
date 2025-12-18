import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/campaign.dart';
import '../../models/task.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import 'subscribe_dialog.dart';

class CampaignDetailsScreen extends StatefulWidget {
  final String campaignId;

  const CampaignDetailsScreen({super.key, required this.campaignId});

  @override
  State<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends State<CampaignDetailsScreen> {
  Campaign? _campaign;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubscribed = false;

  // Filter state
  String _selectedFilter =
      'Tout'; // Options: 'Tout', 'En cours', 'Terminées', 'Mes tâches'
  List<String> _mySubscribedTaskIds = [];

  @override
  void initState() {
    super.initState();
    _loadCampaignDetails();
  }

  Future<void> _loadCampaignDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final campaignProvider =
          Provider.of<CampaignProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      // Fetch Campaign
      final campaign =
          await campaignProvider.getCampaignById(widget.campaignId);

      if (campaign != null) {
        _campaign = campaign;

        // Fetch User specific data if logged in
        if (userId != null) {
          _isSubscribed = await campaignProvider.isUserSubscribed(
            userId: userId,
            campaignId: widget.campaignId,
          );

          if (_isSubscribed) {
            final userTasks = await campaignProvider
                .getUserTaskSubscriptions(widget.campaignId);
            _mySubscribedTaskIds =
                userTasks.map((e) => e['task_id'] as String).toList();
          }
        }
      } else {
        _errorMessage = 'Campagne introuvable.';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    setState(() {
      _isLoading = false;
    });
  }

  // Logic: Calculate Global Progress
  double _calculateGlobalProgress() {
    if (_campaign?.tasks == null || _campaign!.tasks!.isEmpty) return 0.0;

    int totalTarget = 0;
    int totalRemaining = 0;

    for (var task in _campaign!.tasks!) {
      totalTarget += task.totalNumber;
      totalRemaining += task.remainingNumber;
    }

    if (totalTarget == 0) return 0.0;

    final completed = totalTarget - totalRemaining;
    return (completed / totalTarget).clamp(0.0, 1.0);
  }

  // Logic: Filter Tasks
  List<Task> _getFilteredTasks() {
    if (_campaign?.tasks == null) return [];

    final tasks = _campaign!.tasks!;

    switch (_selectedFilter) {
      case 'En cours':
        return tasks.where((t) => t.remainingNumber > 0).toList();
      case 'Terminées':
        return tasks.where((t) => t.remainingNumber <= 0).toList();
      case 'Mes tâches':
        return tasks.where((t) => _mySubscribedTaskIds.contains(t.id)).toList();
      case 'Tout':
      default:
        return tasks;
    }
  }

  String _formatNumber(int number) {
    return NumberFormat('#,###', 'fr_FR').format(number);
  }

  @override
  Widget build(BuildContext context) {
    // Basic Dark mode check (though AppColors defines specific palette, we can adapt backgrounds)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.background,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? _buildErrorView()
              : _campaign == null
                  ? const Center(child: Text('Campagne introuvable.'))
                  : _buildContent(isDark),
      floatingActionButton:
          _campaign != null ? _buildFloatingActionButton() : null,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.textLight),
          const SizedBox(height: 16),
          Text(
            'Erreur: $_errorMessage',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCampaignDetails,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          // Custom App Bar
          _buildTopBar(isDark),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCampaignDetails,
              color: AppColors.primary,
              backgroundColor:
                  isDark ? const Color(0xFF1c2536) : AppColors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    16, 8, 16, 100), // Bottom padding for FAB
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header (Name + Creator)
                    _buildHeaderInfo(isDark),

                    // 2. Members & Category
                    const SizedBox(height: 16),
                    _buildMembersAndCategory(isDark),

                    // 3. Description
                    const SizedBox(height: 16),
                    _buildDescription(isDark),

                    // 4. Global Progress
                    const SizedBox(height: 20),
                    _buildGlobalProgressBar(isDark),

                    // 5. Filters
                    const SizedBox(height: 24),
                    _buildFilterChips(isDark),

                    // 6. Task List
                    const SizedBox(height: 16),
                    _buildTaskListView(isDark),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildTopBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back,
                color: isDark ? Colors.white : AppColors.textPrimary),
          ),
          Text(
            'Détails de la campagne',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {}, // Options menu
            icon: Icon(Icons.more_vert,
                color: isDark ? Colors.white : AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _campaign!.name,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : AppColors.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              "Créé par ",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
              ),
            ),
            Text(
              _campaign!.createdByName ?? "Inconnu",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMembersAndCategory(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Members Avatars
        Row(
          children: [
            SizedBox(
              height: 36,
              width: 90, // Approx width for standard overlap
              child: Stack(
                children: [
                  _buildAvatarPlaceholder(0, AppColors.primaryLight),
                  _buildAvatarPlaceholder(24, AppColors.secondaryLight),
                  _buildAvatarPlaceholder(48, AppColors.goldLight),
                  Positioned(
                    left: 72,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            isDark ? const Color(0xFF232f48) : Colors.grey[200],
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                                isDark ? const Color(0xFF121212) : Colors.white,
                            width: 2),
                      ),
                      child: Center(
                        child: Text(
                          "+${_campaign!.isPublic ? '99' : '5'}", // Dummy data
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.grey[300]
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "5 Membres", // Static for now as requested/mocked
              style: TextStyle(
                color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Category Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _campaign!.category ?? 'Général',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarPlaceholder(double leftOffset, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      left: leftOffset,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: isDark ? const Color(0xFF121212) : Colors.white, width: 2),
        ),
        child: const Icon(Icons.person, size: 20, color: Colors.white54),
      ),
    );
  }

  Widget _buildDescription(bool isDark) {
    if (_campaign!.description == null || _campaign!.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      _campaign!.description!,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.grey[400] : AppColors.textSecondary,
        height: 1.5,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildGlobalProgressBar(bool isDark) {
    final progress = _calculateGlobalProgress();
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c2536) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
        border: Border.all(
            color: isDark ? Colors.white10 : AppColors.divider, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Réalisation totale",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                "$percentage%",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
                  isDark ? const Color(0xFF324467) : AppColors.offWhite,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = ['Tout', 'En cours', 'Terminées', 'Mes tâches'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? const Color(0xFF232f48) : AppColors.offWhite),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : AppColors.textSecondary),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskListView(bool isDark) {
    final tasks = _getFilteredTasks();

    if (tasks.isEmpty) {
      final isFiltered = _selectedFilter != 'Tout';
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1c2536) : AppColors.offWhite,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFiltered
                      ? Icons.filter_list_off
                      : Icons.assignment_outlined,
                  size: 48,
                  color: isDark
                      ? Colors.grey[600]
                      : AppColors.textSecondary.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isFiltered
                    ? "Aucune tâche ne correspond à ce filtre"
                    : "Cette campagne ne contient aucune tâche",
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (isFiltered) ...[
                const SizedBox(height: 8),
                Text(
                  "Essayez de changer de filtre pour voir plus de résultats.",
                  style: TextStyle(
                    color: isDark
                        ? Colors.grey[600]
                        : AppColors.textSecondary.withOpacity(0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ]
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(task, isDark);
      },
    );
  }

  Widget _buildTaskCard(Task task, bool isDark) {
    final total = task.totalNumber;
    final remaining = task.remainingNumber;
    final completed = total - remaining;
    final progress = total > 0 ? (completed / total) : 0.0;
    final isComplete = remaining <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c2536) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white10 : AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Box
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isComplete ? Icons.check_circle : Icons.star,
                  color: isComplete ? AppColors.success : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Title & Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            task.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: isComplete
                                  ? TextDecoration.lineThrough
                                  : null,
                              color:
                                  isDark ? Colors.white : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_mySubscribedTaskIds.contains(task.id))
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.person,
                                size: 14, color: AppColors.primary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isComplete
                          ? "Terminée"
                          : (task.remainingNumber > 0
                              ? "En cours"
                              : "Inactive"),
                      style: TextStyle(
                        fontSize: 12,
                        color: isComplete
                            ? AppColors.success
                            : (isDark
                                ? Colors.grey[400]
                                : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              // Menu Icon (Placeholder)
              const Icon(Icons.more_horiz, color: Colors.grey, size: 20),
            ],
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${_formatNumber(task.completedNumber)} faits",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                "Cible: ${_formatNumber(total)}",
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor:
                  isDark ? const Color(0xFF324467) : AppColors.offWhite,
              valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? AppColors.success : AppColors.primary),
            ),
          ),

          if (!isComplete && _isSubscribed) ...[
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              children: [
                _buildActionButton(Icons.remove, isDark, onTap: () {}),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement Log Count Logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      elevation: 0,
                      foregroundColor: AppColors.primary,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Journal",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                _buildActionButton(Icons.add, isDark, onTap: () {}),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, bool isDark,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2a3649) : AppColors.offWhite,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: isDark ? Colors.white : AppColors.textSecondary, size: 20),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        if (!_isSubscribed) {
          showDialog(
            context: context,
            builder: (context) => SubscribeDialog(
              campaign: _campaign!,
              onSubscriptionSuccess: () {
                _loadCampaignDetails();
              },
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) => SubscribeDialog(
              campaign: _campaign!,
              onSubscriptionSuccess: () {
                _loadCampaignDetails();
              },
            ),
          );
        }
      },
      backgroundColor: AppColors.primary,
      child: Icon(_isSubscribed ? Icons.edit : Icons.add, color: Colors.white),
    );
  }
}
