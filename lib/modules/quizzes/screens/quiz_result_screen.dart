import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../models/quiz_models.dart';
import '../providers/quiz_provider.dart';
import '../../../utils/l10n_extensions.dart';

class QuizResultScreen extends StatefulWidget {
  final Quiz quiz;
  final int score;
  final int totalQuestions;
  final int livesLeft;
  final bool isPracticeMode;

  const QuizResultScreen({
    super.key,
    required this.quiz,
    required this.score,
    required this.totalQuestions,
    required this.livesLeft,
    this.isPracticeMode = false,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  bool _isSaving = true;
  int _xpEarned = 0;

  @override
  void initState() {
    super.initState();
    _calculateAndSaveXP();
  }

  Future<void> _calculateAndSaveXP() async {
    if (widget.isPracticeMode) {
      if (mounted) setState(() => _isSaving = false);
      return;
    }

    // 10 XP per correct answer + 20 XP bonus if 0 lives lost
    _xpEarned = (widget.score * 10) + (widget.livesLeft == 3 ? 20 : 0);
    
    try {
      await context.read<QuizProvider>().submitResult(
        quizId: widget.quiz.id,
        score: widget.score,
        totalQuestions: widget.totalQuestions,
        xpEarned: _xpEarned,
      );
    } catch (e) {
      debugPrint("Error saving result: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isVictory = widget.livesLeft > 0 && widget.score > (widget.totalQuestions / 2);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                isVictory ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
                size: 100,
                color: isVictory ? AppColors.gold : Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(
                isVictory ? context.l10n.congratulations : context.l10n.gameOver,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.youObtained,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                "${widget.score} / ${widget.totalQuestions}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.tealPrimary),
              ),
              const SizedBox(height: 32),
              
              if (_isSaving)
                const Center(child: CircularProgressIndicator())
              else
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(widget.isPracticeMode ? context.l10n.practiceMode : context.l10n.reward, 
                        style: TextStyle(fontWeight: FontWeight.bold, color: widget.isPracticeMode ? Colors.blue : Colors.orange)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.isPracticeMode ? Icons.refresh : Icons.stars, 
                            color: widget.isPracticeMode ? Colors.blue : AppColors.gold, size: 30),
                          const SizedBox(width: 12),
                          Text(
                            widget.isPracticeMode ? context.l10n.quizReviewed : "+$_xpEarned XP",
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
              const Spacer(),
              
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(context.l10n.backToHome, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
