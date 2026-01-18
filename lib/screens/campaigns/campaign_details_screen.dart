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
  
  // State for Inline Quran Subscription
  final Set<String> _tempSelectedJuzIds = {};
  bool _isJoining = false;

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
                      if (_campaign!.category != 'Quran')
                         _buildGlobalProgressBar(isDark),

                      // 5. Filters (Standard only)
                      if (_campaign!.category != 'Quran') ...[
                        const SizedBox(height: 24),
                        _buildFilterChips(isDark),
                      ],

                      // 6. Task List or Quran View
                      const SizedBox(height: 16),
                      if (_campaign!.category == 'Quran')
                         _buildQuranView(isDark)
                      else
                         _buildTaskListView(isDark),

                      // 7. Finished Status (if applicable)
                      if (_campaign!.isFinished)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 24),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.5)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                "Campagne Terminée",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              Text(
                                "Les inscriptions sont closes.",
                                style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET: VUE SPÉCIALE CORAN
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQuranView(bool isDark) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isCreator = authProvider.user != null && _campaign?.createdBy == authProvider.user!.id; // TODO: Add isAdmin check if needed
    final tasks = _campaign?.tasks ?? [];

    // 1. CALCULATE STATS
    int totalRead = tasks.fold(0, (sum, t) => sum + t.completedCount);
    int totalTaken = tasks.where((t) => t.remainingNumber == 0).length;
    int totalCount = tasks.length;
    int inProgressCount = totalTaken >= totalRead ? totalTaken - totalRead : 0;
    int freeCount = totalCount - totalTaken;
    
    double readPercentage = totalCount > 0 ? (totalRead / totalCount) : 0.0;
    double takenPercentage = totalCount > 0 ? (inProgressCount / totalCount) : 0.0;
    double freePercentage = totalCount > 0 ? (freeCount / totalCount) : 0.0;
    
    String readPercentageStr = (readPercentage * 100).toStringAsFixed(0);
    
    // Sort tasks
    final sortedTasks = List<Task>.from(tasks);
    sortedTasks.sort((a, b) {
      int numA = int.tryParse(a.name.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      int numB = int.tryParse(b.name.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return numA.compareTo(numB);
    });

    // 2. DASHBOARD WIDGET (Visible to ALL)
    Widget dashboardWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // STATS CARD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              const Text("Progression Globale", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
             // PROGRESS BAR
        Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 24,
                child: Row(
                  children: [
                    // READ (Green)
                    if (readPercentage > 0)
                      Expanded(
                        flex: (readPercentage * 100).toInt(),
                        child: Container(color: Colors.green),
                      ),
                    // TAKEN (Orange)
                    if (takenPercentage > 0)
                      Expanded(
                        flex: (takenPercentage * 100).toInt(),
                        child: Container(color: Colors.orange),
                      ),
                    // FREE (Grey)
                    if (freePercentage > 0)
                      Expanded(
                        flex: (freePercentage * 100).toInt(),
                        child: Container(color: Colors.grey.shade300),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("$totalRead Lus ($readPercentageStr%)", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text("$totalTaken Pris", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                Text("$freeCount Libres", style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ADMIN ACTIONS (Creator Only)
        if (isCreator) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _campaign!.isFinished ? null : () => _confirmTerminateCampaign(),
                  icon: const Icon(Icons.stop_circle_outlined, color: Colors.orange),
                  label: Text(_campaign!.isFinished ? "Déjà terminée" : "Terminer", style: const TextStyle(color: Colors.orange)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmDeleteCampaign(),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text("Supprimer", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // GLOBAL VISUALIZATION GRID (Small dots)
        ExpansionTile(
          title: const Text("Voir la carte globale", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          initiallyExpanded: false,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10, // Very compact
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: sortedTasks.length,
                itemBuilder: (context, index) {
                  final task = sortedTasks[index];
                  final isRead = task.completedCount > 0;
                  final isTaken = task.remainingNumber == 0;
                  
                  Color color = isRead ? Colors.green : (isTaken ? Colors.orange : Colors.grey.shade300);
                  
                  return Container(
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        "${index + 1}", 
                        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                  );
                },
              ),
            ),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDotLegend(Colors.green, "Lu"),
                const SizedBox(width: 12),
                _buildDotLegend(Colors.orange, "Pris"),
                const SizedBox(width: 12),
                _buildDotLegend(Colors.grey.shade300, "Libre"),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
        const Divider(height: 32),
      ],
    );


    // 3. UNIFIED USER ACTION WIDGETS
    bool isCampaignFull = sortedTasks.every((t) => t.remainingNumber <= 0);
    
    Widget myJuzWidget = const SizedBox.shrink();
    if (_isSubscribed) {
       final myTasks = tasks.where((t) => _mySubscribedTaskIds.contains(t.id)).toList();
       myTasks.sort((a, b) {
        int numA = int.tryParse(a.name.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        int numB = int.tryParse(b.name.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return numA.compareTo(numB);
      });
      
      myJuzWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Mes Juz (Appuyez pour marquer comme lu)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: myTasks.map((task) {
              final userTaskRel = _myUserTasks.firstWhere((ut) => ut['task_id'] == task.id);
              final userTaskId = userTaskRel['id'] as String;
              final isCompleted = (userTaskRel['completed_quantity'] as int? ?? 0) >= (userTaskRel['subscribed_quantity'] as int? ?? 1);
              String juzNumber = task.name.replaceAll(RegExp(r'[^0-9]'), '');

              return GestureDetector(
                onTap: () async => await _handleQuranTaskToggle(task, userTaskId, !isCompleted),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade100),
                    border: Border.all(color: isCompleted ? Colors.green : (isDark ? Colors.grey : Colors.grey.shade300), width: 2),
                    boxShadow: isCompleted ? [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))] : [],
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        juzNumber,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.white : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      if (isCompleted)
                         const Positioned(
                          bottom: 2,
                          right: 2,
                          child: Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
        ],
      );
    }

    Widget selectionWidget;
    if (isCampaignFull) {
        selectionWidget = Center(
          child: Column(
            children: [
              Icon(Icons.lock_clock, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text("Campagne Complète", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Tous les Juz ont été pris. Barak Allahufikum.", style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        );
    } else {
        // Selection Grid
        selectionWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              _campaign!.isFinished 
                  ? "Détails de la campagne (Terminée)" 
                  : (_isSubscribed ? "Prendre d'autres Juz (Moussa'ada/Aide)" : "Sélectionnez vos Juz (Max 3)"),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary),
            ),

            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                crossAxisSpacing: 8, 
                mainAxisSpacing: 8,
              ),
              itemCount: sortedTasks.length,
              itemBuilder: (context, index) {
                final task = sortedTasks[index];
                bool isSelected = _tempSelectedJuzIds.contains(task.id);
                bool isAvailable = task.remainingNumber > 0;
                // Allow taking up to 3 at a time in specific session, regardless of total? 
                // Let's keep rule max 3 per selection action to prevent spam.
                bool isLocked = !isSelected && _tempSelectedJuzIds.length >= 3;

                // Color Logic
                Color bgColor = isDark ? Colors.white10 : Colors.grey.shade100;
                Color textColor = isDark ? Colors.grey.shade300 : Colors.black87;
                Color borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

                if (!isAvailable) {
                   bgColor = isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.grey.shade300;
                   textColor = isDark ? Colors.red.shade200 : Colors.grey.shade500;
                   borderColor = Colors.transparent;
                } else if (isSelected) {
                   bgColor = Colors.redAccent;
                   textColor = Colors.white;
                   borderColor = Colors.red;
                } else if (isLocked) {
                   bgColor = isDark ? Colors.black26 : Colors.grey.shade50;
                   textColor = isDark ? Colors.white24 : Colors.grey.shade300;
                }

                return InkWell(
                  onTap: (_campaign!.isFinished || !isAvailable || (isLocked && !isSelected))
                      ? null
                      : () {
                          setState(() {
                            if (isSelected) {
                              _tempSelectedJuzIds.remove(task.id);
                            } else {
                              _tempSelectedJuzIds.add(task.id);
                            }
                          });
                        },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: isSelected ? 0 : 1),
                      boxShadow: isSelected ? [
                        BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 2))
                      ] : null,
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text("${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 12)),
                        if (isSelected) const Positioned(bottom: 2, right: 2, child: Icon(Icons.check, size: 10, color: Colors.white)),
                        if (!isAvailable) Positioned(child: Icon(Icons.block, size: 20, color: Colors.grey.withOpacity(0.5))),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            if (!_campaign!.isFinished)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_tempSelectedJuzIds.isEmpty || _isJoining) ? null : _handleInlineSubscription,
                  icon: _isJoining ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.login),
                  label: Text(_isJoining ? "Traitement..." : (_isSubscribed ? "Ajouter ces Juz (${_tempSelectedJuzIds.length})" : "Rejoindre la campagne (${_tempSelectedJuzIds.length})")),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary, padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
          ],
        );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dashboardWidget,
        myJuzWidget,
        selectionWidget,
      ],
    );




  }

  // Helper Legend
  Widget _buildDotLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // --- LOGIQUE D'INSCRIPTION INLINE ---
  Future<void> _handleInlineSubscription() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vous devez être connecté.")));
      return;
    }

    setState(() => _isJoining = true);

    try {
      final campaignProvider = Provider.of<CampaignProvider>(context, listen: false);
      
      // Préparer la liste des tâches (quantity: 1 pour chaque Juz sélectionné)
      final List<Map<String, dynamic>> selectedTasks = _tempSelectedJuzIds
          .map((id) => {'task_id': id, 'quantity': 1})
          .toList();

      bool success;
      if (_isSubscribed) {
        success = await campaignProvider.addTasksToSubscription(
          campaignId: _campaign!.id,
          selectedTasks: selectedTasks,
        );
      } else {
        success = await campaignProvider.subscribeToCampaign(
          userId: user.id,
          campaignId: _campaign!.id,
          accessCode: _campaign!.accessCode,
          selectedTasks: selectedTasks,
        );
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSubscribed ? "Juz ajoutés avec succès !" : "Inscription réussie ! Jazak Allah Khair 🤲"),
            backgroundColor: Colors.green,
          ),
        );
        // Recharger pour passer en mode "Inscrit"
        await _loadCampaignDetails();
        setState(() {
          _tempSelectedJuzIds.clear(); // Clean up
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(campaignProvider.errorMessage ?? "Erreur d'inscription")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  // Helper pour toggle simple de tâche Coran
  Future<void> _handleQuranTaskToggle(Task task, String userTaskId, bool markAsDone) async {
    // ⚡️ DIRECT ACTION: Pas de dialog de confirmation

    // Show loading (Subtle or blocking? user hates dialogs, but we need to block double-taps)
    // Using a minimal blocking loader for safety
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black12, // Very subtle overlay
      builder: (context) => const Center(
        child: SizedBox(
          width: 30, height: 30,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );

    try {
      final taskService = TaskService();
      // Si on marque comme fait => on envoie subscribed_quantity (qui est le max)
      // Si on annule => on envoie 0
      // On doit récupérer la quantité souscrite exacte
      final userTaskRel = _myUserTasks.firstWhere((ut) => ut['task_id'] == task.id);
      final subscribedQty = userTaskRel['subscribed_quantity'] as int? ?? 1;

      final qtyToSend = markAsDone ? subscribedQty : 0;

      // Utiliser updateTaskProgress pour permettre le toggle (0 ou 100%)
      await taskService.updateTaskProgress(
        userTaskId: userTaskId,
        completedQuantity: qtyToSend,
      );

      // OPTIMISTIC UPDATE (Instant Feedback)
      if (mounted) {
        setState(() {
          // 1. Update Global Count
          final taskIndex = _campaign!.tasks!.indexWhere((t) => t.id == task.id);
          if (taskIndex != -1) {
             int change = markAsDone ? 1 : -1;
             int newCount = task.completedCount + change;
             if (newCount < 0) newCount = 0; // Safety
             
             // Update the task in the list
             _campaign!.tasks![taskIndex] = task.copyWith(completedCount: newCount);
          }
          
          // 2. Update Local User Status
          final myIndex = _myUserTasks.indexWhere((ut) => ut['task_id'] == task.id);
          if (myIndex != -1) {
             _myUserTasks[myIndex]['completed_quantity'] = markAsDone ? subscribedQty : 0;
             // Important: update local is_completed check too if needed by UI
             // UI logic uses (completed >= subscribed), so updating quantity is enough
          }
        });

        Navigator.pop(context); // Close loading

        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(markAsDone ? "Juz ${task.name} terminé ! 🌟" : "Lecture de ${task.name} annulée."),
             backgroundColor: markAsDone ? Colors.green : Colors.orange,
             duration: const Duration(seconds: 1),
             behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
             margin: const EdgeInsets.all(12),
          ),
        );
        
        // Silent refresh to sync everything perfectly
        _loadCampaignDetails(); 
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
    }
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
    // Check if current user is creator
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    final isCreator = userId == _campaign!.createdBy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _campaign!.name,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
            if (_campaign!.isFinished)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  "Terminée",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        // Finish Button for Creator (if not finished)
        if (isCreator && !_campaign!.isFinished)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: OutlinedButton.icon(
              onPressed: () => _confirmTerminateCampaign(),
              icon: const Icon(Icons.stop_circle_outlined, size: 16, color: Colors.orange),
              label: const Text("Terminer la campagne", style: TextStyle(color: Colors.orange, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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
    // ⚡️ CORAN MODE EXCEPTION: 
    // Subscription is handled INLINE in the body.
    // We hide this bottom bar to prevent showing the redundant "Join" dialog.
    if (_campaign?.category == 'Quran') {
      return const SizedBox.shrink();
    }
    
    // Si terminée, on n'affiche plus rien dans la bottom bar (c'est géré dans le body)
    if (_campaign?.isFinished == true) {
      return const SizedBox.shrink();
    }

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

  // Helper pour les stats
  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Future<void> _confirmTerminateCampaign() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Terminer la campagne ?"),
        content: const Text("Cela marquera la campagne comme terminée maintenant. Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Terminer", style: TextStyle(color: Colors.orange))),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<CampaignProvider>(context, listen: false);
      final userId = Provider.of<AuthProvider>(context, listen: false).user!.id; // Safe if creator
      
      final success = await provider.updateCampaign(
        campaignId: widget.campaignId,
        userId: userId,
        updates: {
          'is_finished': true,
          'end_date': DateTime.now().toIso8601String(),
        },
      );



      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Campagne terminée.")));
        await _loadCampaignDetails(); // Reload to show updated status
      }

    }
  }

  Future<void> _confirmDeleteCampaign() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer la campagne ?"),
        content: const Text("Toutes les données associées seront perdues. Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final provider = Provider.of<CampaignProvider>(context, listen: false);
      final userId = Provider.of<AuthProvider>(context, listen: false).user!.id;

      final success = await provider.deleteCampaign(campaignId: widget.campaignId, userId: userId);

      if (success && mounted) {
        Navigator.pop(context); // Return to list
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Campagne supprimée.")));
      }
    }
  }
}
