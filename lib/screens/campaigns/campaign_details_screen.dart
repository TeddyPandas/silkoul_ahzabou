import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign.dart';
import '../../models/task.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import '../../services/task_service.dart';
import '../../widgets/finish_task_dialog.dart';
import 'package:silkoul_ahzabou/widgets/task_card.dart';
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

  // Store full user task subscriptions for finish task feature
  List<Map<String, dynamic>> _myUserTasks = [];
  String? _accessCode;

  @override
  void initState() {
    super.initState();
    _loadCampaignDetails();
  }

  Future<void> _loadCampaignDetails([String? code]) async {
    if (code != null) {
      _accessCode = code;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final campaignProvider =
          Provider.of<CampaignProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      // Fetch Campaign - Pass access code if available
      final campaign = await campaignProvider.getCampaignById(widget.campaignId,
          accessCode: _accessCode);

      if (mounted) {
        if (campaignProvider.errorMessage != null) {
          setState(() {
            _errorMessage = campaignProvider.errorMessage;
            _isLoading = false;
          });
          return;
        }
      }

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
            _myUserTasks = userTasks;
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

  /// Handle finishing a task - opens dialog and processes the result
  Future<void> _handleFinishTask(
      Task task, Map<String, dynamic> userTaskData) async {
    final subscribedQuantity = userTaskData['subscribed_quantity'] as int? ?? 0;
    final userTaskId = userTaskData['id'] as String?;

    if (userTaskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: ID de tâche utilisateur non trouvé'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show the finish task dialog
    final result = await showDialog<int>(
      context: context,
      builder: (context) => FinishTaskDialog(
        taskName: task.name,
        subscribedQuantity: subscribedQuantity,
        currentCompletedQuantity:
            userTaskData['completed_quantity'] as int? ?? 0,
      ),
    );

    // If user cancelled or didn't enter a value, return
    if (result == null) return;

    // Show loading indicator
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final taskService = TaskService();
      final response = await taskService.finishTask(
        userTaskId: userTaskId,
        actualCompletedQuantity: result,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      final returnedToPool = response['returned_to_pool'] as int? ?? 0;

      // Show success message
      if (mounted) {
        final message = returnedToPool > 0
            ? 'Tâche terminée ! $returnedToPool unité(s) retournée(s) au pool.'
            : 'Tâche terminée avec succès !';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh campaign details
        await _loadCampaignDetails();
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erreur: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
      bottomNavigationBar:
          (_campaign != null && (_campaign!.tasks?.isNotEmpty ?? false))
              ? _buildBottomBar(context, isDark)
              : null,
    );
  }

  Widget _buildErrorView() {
    final bool isAccessError =
        _errorMessage?.contains('code d\'accès') ?? false;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isAccessError ? Icons.lock_outline : Icons.error_outline,
              size: 64,
              color: isAccessError ? AppColors.primary : AppColors.textLight),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isAccessError
                  ? 'Cette campagne est privée.'
                  : 'Erreur: $_errorMessage',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: isAccessError ? 18 : 14),
              textAlign: TextAlign.center,
            ),
          ),
          if (isAccessError) ...[
            const SizedBox(height: 8),
            const Text(
              'Un code d\'accès est requis pour voir les détails.',
              style: TextStyle(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAccessCodeDialog,
              icon: const Icon(Icons.key),
              label: const Text('Saisir le code d\'accès'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadCampaignDetails(),
              child: const Text('Réessayer'),
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Retour',
                style: TextStyle(color: AppColors.textLight)),
          ),
        ],
      ),
    );
  }

  void _showAccessCodeDialog() {
    final TextEditingController _codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code d\'accès'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez saisir le code d\'accès de la campagne :'),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Code secret',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText:
                  false, // Codes are usually visible or obscure? User choice. Let's keep visible for ease.
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = _codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _loadCampaignDetails(code);
              }
            },
            child: const Text('Valider'),
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
            child: Scrollbar(
              thumbVisibility: true,
              thickness: 6,
              radius: const Radius.circular(10),
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

        // Check if user has subscribed to this task
        final isUserTask = _mySubscribedTaskIds.contains(task.id);

        // Get user task data if subscribed
        Map<String, dynamic>? userTaskData;
        if (isUserTask) {
          userTaskData = _myUserTasks.firstWhere(
            (ut) => ut['task_id'] == task.id,
            orElse: () => <String, dynamic>{},
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TaskCard(
            task: task,
            isDark: isDark,
            userTaskData: userTaskData,
            onFinish: (userTaskData != null && _isSubscribed)
                ? () => _handleFinishTask(task, userTaskData!)
                : null,
            onSubscribe: !_isSubscribed
                ? () {
                    showDialog(
                      context: context,
                      builder: (context) => SubscribeDialog(
                        campaign: _campaign!,
                        initialAccessCode: _accessCode,
                        onSubscriptionSuccess: () {
                          _loadCampaignDetails();
                        },
                      ),
                    );
                  }
                : null,
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c2536) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            if (!_isSubscribed) {
              showDialog(
                context: context,
                builder: (context) => SubscribeDialog(
                  campaign: _campaign!,
                  initialAccessCode: _accessCode,
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
                  initialAccessCode: _accessCode,
                  onSubscriptionSuccess: () {
                    _loadCampaignDetails();
                  },
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _isSubscribed
                ? "Modifier ma souscription"
                : "Rejoindre la campagne",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
