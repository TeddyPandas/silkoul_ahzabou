import 'package:flutter/material.dart';
import 'package:silkoul_ahzabou/models/task.dart';
import 'package:silkoul_ahzabou/config/app_theme.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final Map<String, dynamic>? userTaskData;
  final VoidCallback? onSubscribe;
  final VoidCallback? onFinish;
  final bool isDark;

  const TaskCard({
    super.key,
    required this.task,
    required this.isDark,
    this.userTaskData,
    this.onSubscribe,
    this.onFinish,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isHovered = false;

  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;

  // Entrance Animation
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _expandAnimation =
        CurvedAnimation(parent: _expandController, curve: Curves.fastOutSlowIn);
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
        CurvedAnimation(parent: _expandController, curve: Curves.easeInOut));

    // Init entrance animation
    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _entryController, curve: Curves.easeOutCubic));

    // Start entrance animation with a small delay based on index if possible,
    // but here we just start it. The list view builds items sequentially usually.
    _entryController.forward();
  }

  @override
  void dispose() {
    _expandController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  String _formatNumber(int number) {
    return NumberFormat.decimalPattern('fr').format(number);
  }

  @override
  Widget build(BuildContext context) {
    final bool isUserTask = widget.userTaskData != null;
    final bool isCompleted =
        isUserTask && (widget.userTaskData!['is_completed'] == true);
    final int userGoal = isUserTask
        ? (isCompleted
            ? (widget.userTaskData!['completed_quantity'] ?? 0)
            : (widget.userTaskData!['subscribed_quantity'] ?? 0))
        : 0;

    // Calculate progress
    final int total = widget.task.totalNumber;
    final int done = widget.task.completedNumber;
    final double defaultProgress = total > 0 ? done / total : 0.0;
    final double safeProgress = defaultProgress.clamp(0.0, 1.0);
    final int percent = (safeProgress * 100).toInt();

    final Color cardColor =
        widget.isDark ? const Color(0xFF1E2636) : Colors.white;
    final Color textColor =
        widget.isDark ? Colors.white : AppColors.textPrimary;
    final Color subTextColor =
        widget.isDark ? Colors.grey[400]! : AppColors.textSecondary;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.05),
                    blurRadius: _isHovered ? 12 : 4,
                    offset: Offset(0, _isHovered ? 4 : 2),
                  )
                ],
                border: Border.all(
                    color: isCompleted
                        ? AppColors.success.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1.5)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggleExpand,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // HEADER
                      Row(
                        children: [
                          // Circular Progress (Mini) or Icon
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: safeProgress,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    isCompleted
                                        ? AppColors.success
                                        : AppColors.primary),
                                strokeWidth: 3,
                              ),
                              if (isCompleted)
                                const Icon(Icons.check,
                                    size: 14, color: AppColors.success)
                              else
                                Text(
                                  "$percent%",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Title & Subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.task.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${_formatNumber(done)} / ${_formatNumber(total)} réalisés",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Expand Icon
                          RotationTransition(
                            turns: _rotateAnimation,
                            child: Icon(Icons.keyboard_arrow_down,
                                color: subTextColor),
                          ),
                        ],
                      ),

                      // EXPANDED CONTENT
                      SizeTransition(
                        sizeFactor: _expandAnimation,
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.withOpacity(0.1)),
                            const SizedBox(height: 16),

                            // Detailed Stats Grid
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem("Objectif", _formatNumber(total),
                                    subTextColor, textColor),
                                _buildStatItem(
                                    "Restant",
                                    _formatNumber(widget.task.remainingNumber),
                                    subTextColor,
                                    AppColors.gold),
                                if (isUserTask)
                                  _buildStatItem(
                                      "Votre part",
                                      _formatNumber(userGoal),
                                      subTextColor,
                                      AppColors.primary),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Action Button Area
                            if (isUserTask &&
                                !isCompleted &&
                                widget.onFinish != null)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: widget.onFinish,
                                  icon: const Icon(Icons.check_circle_outline,
                                      size: 18),
                                  label: const Text("Terminer la tâche"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              )
                            else if (!isUserTask && widget.onSubscribe != null)
                              // Hint to subscribe (handled by parent FAB usually, but we can add inline sub later if needed)
                              Container()
                            else if (isCompleted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified,
                                        size: 16, color: AppColors.success),
                                    SizedBox(width: 8),
                                    Text("Vous avez terminé votre part",
                                        style: TextStyle(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, Color labelColor, Color valueColor) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            )),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
            )),
      ],
    );
  }
}
