import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/media_provider.dart';
import '../../../../models/media_models.dart';

class AdminVideoEditDialog extends StatefulWidget {
  final MediaVideo video;

  const AdminVideoEditDialog({super.key, required this.video});

  @override
  State<AdminVideoEditDialog> createState() => _AdminVideoEditDialogState();
}

class _AdminVideoEditDialogState extends State<AdminVideoEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _subtitleUrlController;

  String? _selectedAuthorId;
  String? _selectedCategoryId;
  String _status = 'PUBLISHED';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.video.title);
    _descriptionController = TextEditingController(text: widget.video.description);
    _subtitleUrlController = TextEditingController(text: widget.video.customSubtitleUrl);
    _selectedAuthorId = widget.video.authorId;
    _selectedCategoryId = widget.video.categoryId;
    _status = widget.video.status; // Assumes MediaVideo has status field now
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtitleUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<MediaProvider>(context, listen: false);
      await provider.updateVideo(
        widget.video.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        authorId: _selectedAuthorId,
        categoryId: _selectedCategoryId,
        status: _status,
        customSubtitleUrl: _subtitleUrlController.text.trim().isEmpty ? null : _subtitleUrlController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MediaProvider>(context);
    final authors = provider.authors;
    final categories = provider.categories;
    final darkTheme = Theme.of(context).brightness == Brightness.dark;
    final bgColor = darkTheme ? const Color(0xFF1E1E1E) : Colors.white;

    return Dialog(
      backgroundColor: bgColor,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Modifier la vidéo",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              // Status Dropdown
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: "Statut"),
                items: const [
                  DropdownMenuItem(value: 'PUBLISHED', child: Text("Publié", style: TextStyle(color: Colors.green))),
                  DropdownMenuItem(value: 'HIDDEN', child: Text("Masqué", style: TextStyle(color: Colors.grey))),
                ],
                onChanged: (val) => setState(() => _status = val!),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Titre"),
                validator: (v) => v == null || v.isEmpty ? "Requis" : null,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // Relations Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: authors.any((a) => a.id == _selectedAuthorId) ? _selectedAuthorId : null,
                      decoration: const InputDecoration(labelText: "Auteur"),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("Aucun")),
                        ...authors.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (val) => setState(() => _selectedAuthorId = val),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null,
                      decoration: const InputDecoration(labelText: "Catégorie"),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("Aucune")),
                        ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // Translation / Subtitles
              TextFormField(
                controller: _subtitleUrlController,
                decoration: const InputDecoration(
                  labelText: "Lien Sous-titres / Traduction",
                  hintText: "URL .vtt, .srt ou texte de transcription",
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Annuler"),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Enregistrer"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
