import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../config/app_theme.dart';
import '../../../services/task_service.dart';

class TasbihScreen extends StatefulWidget {
  final String campaignId;
  final String userTaskId;
  final String taskName;
  final int targetCount;
  final int initialCount;

  const TasbihScreen({
    super.key,
    required this.campaignId,
    required this.userTaskId,
    required this.taskName,
    required this.targetCount,
    required this.initialCount,
  });

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> with WidgetsBindingObserver {
  late int _currentCount;
  Timer? _debounceTimer;
  bool _isSaving = false;
  final _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _currentCount = widget.initialCount;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _saveProgress(); // Ensure save on exit
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      debugPrint("⏸️ [Tasbih] App paused/detached, saving progress...");
      _saveProgress();
    }
  }

  void _increment() {
    if (_currentCount >= widget.targetCount) {
      // Prevent going over target, just show dialog
      _showCompletionDialog();
      return;
    }

    setState(() {
      _currentCount++;
    });

    if (_currentCount >= widget.targetCount) {
      HapticFeedback.heavyImpact();
      _showCompletionDialog();
    } else {
      HapticFeedback.lightImpact();
    }

    _debounceSave();
  }

  void _debounceSave() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _saveProgress);
  }

  Future<void> _saveProgress() async {
    // Save regardless of _isSaving to avoid race conditions on dispose
    // But we should avoid parallel calls if possible.
    try {
       debugPrint("💾 [Tasbih] Saving progress: $_currentCount");
       await _taskService.updateUserTaskProgress(widget.userTaskId, _currentCount);
    } catch (e) {
      debugPrint("❌ [Tasbih] Error saving progress: $e");
    }
  }

  Future<void> _finishTask() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await _taskService.finishTask(
        userTaskId: widget.userTaskId,
        actualCompletedQuantity: _currentCount,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        Navigator.pop(context); // Close dialog if open
        Navigator.pop(context, true); // Return 'true' to indicate completion
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Une erreur est survenue. Veuillez réessayer.')),
        );
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Alhamdulillah!', style: TextStyle(color: AppColors.gold)),
        content: Text(
          'Vous avez atteint votre objectif de ${widget.targetCount} ${widget.taskName}.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _saveProgress().then((_) {
                 if (mounted) Navigator.pop(context, _currentCount); // Return w/ count
              });
            },
            child: const Text('Plus tard', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
            onPressed: () {
               _finishTask();
            },
            child: const Text('Terminer la tâche', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Allow progress > 1.0 for visual if Nafl
    double progress = (_currentCount / widget.targetCount).clamp(0.0, 1.0);
    bool isCompleted = _currentCount >= widget.targetCount;

    return PopScope(
      canPop: false, // Prevent default pop
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        // Save before popping
        await _saveProgress();
        
        if (context.mounted) {
           Navigator.pop(context, _currentCount);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white54),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Force save on back button
              await _saveProgress();
              if (mounted) Navigator.pop(context, _currentCount);
            },
          ),
          actions: [
              IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                       // Creating a reset feature for testing might be useful
                  },
              )
          ],
        ),
        body: InkWell(
          onTap: _increment,
          splashColor: AppColors.tealPrimary.withOpacity(0.3),
          highlightColor: AppColors.tealPrimary.withOpacity(0.1),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.taskName,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 48),
                CircularPercentIndicator(
                  radius: 120.0,
                  lineWidth: 12.0,
                  percent: progress,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$_currentCount",
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "/ ${widget.targetCount}",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                  progressColor: isCompleted ? Colors.green : AppColors.gold,
                  backgroundColor: Colors.grey[800]!,
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                  animateFromLastPercent: true,
                ),
                const SizedBox(height: 48),
                
                if (isCompleted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: _finishTask,
                      icon: const Icon(Icons.check, color: Colors.black),
                      label: const Text("TERMINER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                
                Text(
                  isCompleted ? "Touchez pour ajouter (Nafl)" : "Touchez n'importe où pour compter",
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
