import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../quizzes/providers/quiz_provider.dart';

class AdminEditQuestionDialog extends StatefulWidget {
  final String quizId;
  final VoidCallback onSaved;

  const AdminEditQuestionDialog({
    super.key,
    required this.quizId,
    required this.onSaved,
  });

  @override
  State<AdminEditQuestionDialog> createState() => _AdminEditQuestionDialogState();
}

class _AdminEditQuestionDialogState extends State<AdminEditQuestionDialog> {
  final _questionController = TextEditingController();
  final _explanationController = TextEditingController();
  final List<TextEditingController> _answerControllers = List.generate(4, (_) => TextEditingController());
  int _correctAnswerIndex = 0;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text("Ajouter une Question", style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _questionController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("La question..."),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _explanationController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Explication (optionnel)"),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("RÉPONSES (Cochez la bonne)", 
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              ...List.generate(4, (index) => _buildAnswerField(index)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("ANNULER"),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text("ENREGISTRER"),
        ),
      ],
    );
  }

  Widget _buildAnswerField(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Radio<int>(
            value: index,
            groupValue: _correctAnswerIndex,
            onChanged: (v) => setState(() => _correctAnswerIndex = v!),
            activeColor: Colors.tealAccent,
          ),
          Expanded(
            child: TextField(
              controller: _answerControllers[index],
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Option ${index + 1}"),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.black12,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
    );
  }

  Future<void> _save() async {
    if (_questionController.text.isEmpty) return;
    
    setState(() => _isSaving = true);
    
    final answers = _answerControllers.asMap().entries.map((e) => {
      'text': e.value.text.isEmpty ? "Option ${e.key + 1}" : e.value.text,
      'is_correct': e.key == _correctAnswerIndex,
    }).toList();

    try {
      await context.read<QuizProvider>().addQuestion(
        widget.quizId,
        _questionController.text,
        _explanationController.text.isEmpty ? null : _explanationController.text,
        answers,
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
