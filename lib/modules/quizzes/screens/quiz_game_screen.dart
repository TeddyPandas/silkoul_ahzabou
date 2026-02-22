import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../../config/app_theme.dart';
import '../models/quiz_models.dart';
import '../providers/quiz_provider.dart';
import 'quiz_result_screen.dart';

class QuizGameScreen extends StatefulWidget {
  final Quiz quiz;
  final bool isReviewMode;
  final bool isPracticeMode;

  const QuizGameScreen({
    super.key, 
    required this.quiz,
    this.isReviewMode = false,
    this.isPracticeMode = false,
  });

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  List<Question> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  int _lives = 3;
  bool _isLoading = true;
  bool _answered = false;
  String? _selectedAnswerId;
  bool? _isCorrect;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await context.read<QuizProvider>().loadQuestions(widget.quiz.id);
      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Impossible de charger les questions. Veuillez réessayer.')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _handleAnswer(Answer answer) {
    if (_answered || widget.isReviewMode) return;

    setState(() {
      _answered = true;
      _selectedAnswerId = answer.id;
      _isCorrect = answer.isCorrect;
      
      if (answer.isCorrect) {
        _score++;
        HapticFeedback.mediumImpact();
      } else {
        _lives--;
        HapticFeedback.vibrate();
      }
    });

    // Wait a bit and go to next or finish
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      if (_lives <= 0) {
        _finishQuiz();
      } else if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _answered = false;
          _selectedAnswerId = null;
          _isCorrect = null;
        });
      } else {
        _finishQuiz();
      }
    });
  }

  void _nextReviewQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      Navigator.pop(context); // Finish review
    }
  }

  void _prevReviewQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _finishQuiz() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          quiz: widget.quiz,
          score: _score,
          totalQuestions: _questions.length,
          livesLeft: _lives,
          isPracticeMode: widget.isPracticeMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return const Scaffold(body: Center(child: Text("Aucune question trouvée.")));
    }

    final currentQuestion = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReviewMode ? "Révision: ${widget.quiz.title}" : widget.quiz.title),
        actions: [
          if (!widget.isReviewMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Row(
                  children: List.generate(3, (index) {
                    return Icon(
                      index < _lives ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                      size: 20,
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            color: widget.isReviewMode ? AppColors.gold : AppColors.tealPrimary,
            minHeight: 6,
          ),
          
          if (widget.isReviewMode && widget.isPracticeMode == false)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppColors.gold.withOpacity(0.1),
              child: const Text(
                "Mode Révision - Les réponses correctes sont affichées",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),

          if (widget.isPracticeMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.blue.withOpacity(0.1),
              child: const Text(
                "Mode Entraînement - Aucun XP ne sera attribué",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Question ${_currentIndex + 1} / ${_questions.length}",
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentQuestion.text,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ...currentQuestion.answers.map((answer) => _buildAnswerOption(answer)),
                  
                  if ((_answered || widget.isReviewMode) && currentQuestion.explanation != null && currentQuestion.explanation!.isNotEmpty)
                    _buildExplanation(currentQuestion.explanation!),
                    
                  const SizedBox(height: 80), // Space for bottom buttons in review mode
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: widget.isReviewMode ? _buildReviewControls() : null,
    );
  }

  Widget _buildReviewControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentIndex > 0 ? _prevReviewQuestion : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text("Précédent"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black87,
            ),
          ),
          ElevatedButton.icon(
             // Use pushReplacement or pop to finish review
            onPressed: _nextReviewQuestion,
            icon: Icon(_currentIndex < _questions.length - 1 ? Icons.arrow_forward : Icons.check),
            label: Text(_currentIndex < _questions.length - 1 ? "Suivant" : "Terminer"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOption(Answer answer) {
    if (widget.isReviewMode) {
      return _buildReviewAnswerOption(answer);
    }

    bool isSelected = _selectedAnswerId == answer.id;
    
    Color borderColor = Colors.grey[300]!;
    Color bgColor = Colors.white;
    Widget? icon;

    if (_answered) {
      if (answer.isCorrect) {
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.1);
        icon = const Icon(Icons.check_circle, color: Colors.green);
      } else if (isSelected) {
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.1);
        icon = const Icon(Icons.cancel, color: Colors.red);
      }
    } else if (isSelected) {
      borderColor = AppColors.tealPrimary;
      bgColor = AppColors.tealPrimary.withOpacity(0.05);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _handleAnswer(answer),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              if (isSelected && !_answered)
                BoxShadow(color: AppColors.tealPrimary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  answer.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (icon != null) icon,
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildReviewAnswerOption(Answer answer) {
    Color borderColor = answer.isCorrect ? Colors.green : Colors.grey[300]!;
    Color bgColor = answer.isCorrect ? Colors.green.withOpacity(0.1) : Colors.white;
    Widget? icon = answer.isCorrect ? const Icon(Icons.check_circle, color: Colors.green) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                answer.text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: answer.isCorrect ? FontWeight.bold : FontWeight.normal,
                  color: answer.isCorrect ? Colors.green[800] : Colors.grey[600],
                ),
              ),
            ),
            if (icon != null) icon,
          ],
        ),
      ),
    );
  }

  Widget _buildExplanation(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text("Explication", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
