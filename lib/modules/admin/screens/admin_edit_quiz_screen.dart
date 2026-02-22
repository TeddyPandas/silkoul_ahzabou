import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../quizzes/models/quiz_models.dart';
import '../../quizzes/providers/quiz_provider.dart';
import '../screens/admin_scaffold.dart';
import '../widgets/admin_edit_question_dialog.dart';

class AdminEditQuizScreen extends StatefulWidget {
  final Quiz? quiz;

  const AdminEditQuizScreen({super.key, this.quiz});

  @override
  State<AdminEditQuizScreen> createState() => _AdminEditQuizScreenState();
}

class _AdminEditQuizScreenState extends State<AdminEditQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  String _category = 'Fiqh';
  String _difficulty = 'Easy';
  
  bool _isSaving = false;
  List<Question> _questions = [];
  bool _isLoadingQuestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      _titleController.text = widget.quiz!.title;
      _descriptionController.text = widget.quiz!.description ?? '';
      _imageUrlController.text = widget.quiz!.imageUrl ?? '';
      _category = widget.quiz!.category;
      _difficulty = widget.quiz!.difficulty;
      _loadQuestions();
    }
  }

  Future<void> _loadQuestions() async {
    if (widget.quiz == null) return;
    
    setState(() => _isLoadingQuestions = true);
    try {
      final questions = await context.read<QuizProvider>().loadQuestions(widget.quiz!.id);
      setState(() => _questions = questions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Oups, erreur questions: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingQuestions = false);
    }
  }

  Future<void> _saveQuiz() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    final data = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'category': _category,
      'difficulty': _difficulty,
      'image_url': _imageUrlController.text,
    };

    try {
      final provider = context.read<QuizProvider>();
      if (widget.quiz == null) {
        await provider.createQuiz(data);
        if (mounted) Navigator.pop(context);
      } else {
        await provider.updateQuiz(widget.quiz!.id, data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Quizz mis à jour !")),
          );
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: '/admin/quizzes',
      title: widget.quiz == null ? 'Nouveau Quizz' : 'Modifier le Quizz',
      actions: [
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          TextButton.icon(
            onPressed: _saveQuiz,
            icon: const Icon(Icons.save, color: Colors.tealAccent),
            label: const Text("ENREGISTRER", style: TextStyle(color: Colors.tealAccent)),
          ),
      ],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetadataForm(),
            const SizedBox(height: 32),
            if (widget.quiz != null) _buildQuestionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("INFORMATIONS GÉNÉRALES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Titre du Quizz"),
              validator: (v) => v!.isEmpty ? "Obligatoire" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("Description"),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Catégorie"),
                    items: ['Fiqh', 'Sirah', 'Tariqa', 'Quran', 'General']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _difficulty,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Difficulté"),
                    items: ['Easy', 'Medium', 'Hard']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _difficulty = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _imageUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("URL de l'image (ou assets/...)"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("QUESTIONS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ElevatedButton.icon(
              onPressed: () => _showAddQuestionDialog(),
              icon: const Icon(Icons.add),
              label: const Text("AJOUTER UNE QUESTION"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingQuestions)
          const Center(child: CircularProgressIndicator())
        else if (_questions.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Text("Aucune question pour l'instant", style: TextStyle(color: Colors.grey)),
          ))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final q = _questions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(q.text, style: const TextStyle(color: Colors.white)),
                  subtitle: Text("${q.answers.length} options", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                    onPressed: () => _deleteQuestion(q.id),
                  ),
                ),
              );
            },
          ),
      ],
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

  void _showAddQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => AdminEditQuestionDialog(
        quizId: widget.quiz!.id,
        onSaved: _loadQuestions,
      ),
    );
  }

  Future<void> _deleteQuestion(String id) async {
    try {
      await context.read<QuizProvider>().deleteQuestion(id);
      _loadQuestions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Oups: $e")),
        );
      }
    }
  }
}
