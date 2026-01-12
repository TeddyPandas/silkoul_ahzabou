import 'package:flutter/material.dart';
import '../../../../utils/app_theme.dart';
import '../../teachings/models/teaching.dart';
import '../../teachings/models/author.dart';
import '../../teachings/models/category.dart';
import '../../teachings/services/teaching_service.dart';
import 'admin_scaffold.dart';

class AdminVideoCreateScreen extends StatefulWidget {
  const AdminVideoCreateScreen({super.key});

  @override
  State<AdminVideoCreateScreen> createState() => _AdminVideoCreateScreenState();
}

class _AdminVideoCreateScreenState extends State<AdminVideoCreateScreen> {
  // Dependencies
  List<Author> _authors = [];
  List<Category> _categories = [];

  // Form
  final _titleFrController = TextEditingController();
  final _titleArController = TextEditingController();
  final _descFrController = TextEditingController();
  final _urlController = TextEditingController();
  
  String? _selectedAuthorId;
  String? _selectedCategoryId;

  // Edit Mode
  Teaching? _videoToEdit;
  bool get _isEditMode => _videoToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  Future<void> _loadDependencies() async {
    final authors = await TeachingService.instance.getAuthors();
    final categories = await TeachingService.instance.getCategories();
    
    if (mounted) {
      setState(() {
        _authors = authors;
        _categories = categories;
      });
      _checkForEditMode();
    }
  }

  void _checkForEditMode() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Teaching) {
      _videoToEdit = args;
      _titleFrController.text = args.titleFr;
      _titleArController.text = args.titleAr;
      _descFrController.text = args.descriptionFr;
      _urlController.text = args.mediaUrl;
      _selectedAuthorId = args.authorId;
      _selectedCategoryId = args.categoryId;
    }
  }

  Future<void> _saveVideo() async {
    if (_titleFrController.text.isEmpty || _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Titre et URL sont requis.")));
      return;
    }

    final newVideo = Teaching(
      id: _videoToEdit?.id ?? '',
      type: TeachingType.VIDEO,
      titleFr: _titleFrController.text,
      titleAr: _titleArController.text,
      descriptionFr: _descFrController.text,
      authorId: _selectedAuthorId,
      categoryId: _selectedCategoryId ?? _categories.firstOrNull?.id ?? '', // Safe default
      mediaUrl: _urlController.text.trim(),
      durationSeconds: 0, // Not checking duration for now
      publishedAt: _videoToEdit?.publishedAt ?? DateTime.now(), videoId: '', thumbnailUrl: '',
    );

    try {
      if (_isEditMode) {
        await TeachingService.instance.updateVideoTeaching(newVideo);
      } else {
        await TeachingService.instance.createVideoTeaching(newVideo);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sauvegarde réussie !")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: '/admin/videos',
      title: _isEditMode ? 'Modifier Vidéo' : 'Ajouter une Vidéo',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _Dropdown(label: "Auteur", value: _selectedAuthorId, items: _authors.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(), onChanged: (v) => setState(() => _selectedAuthorId = v))),
                const SizedBox(width: 16),
                Expanded(child: _Dropdown(label: "Catégorie", value: _selectedCategoryId, items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameFr))).toList(), onChanged: (v) => setState(() => _selectedCategoryId = v))),
              ],
            ),
            const SizedBox(height: 16),
            _TextField(controller: _titleFrController, label: "Titre (Français)"),
            const SizedBox(height: 16),
            _TextField(controller: _titleArController, label: "Titre (Arabe)"),
            const SizedBox(height: 16),
            _TextField(controller: _descFrController, label: "Description", maxLines: 3),
            const SizedBox(height: 16),
            _TextField(controller: _urlController, label: "URL YouTube (ex: https://youtu.be/...)"),
            
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saveVideo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(_isEditMode ? "METTRE À JOUR" : "AJOUTER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helpers (reused)
class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  const _TextField({required this.controller, required this.label, this.maxLines = 1});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?) onChanged;
  const _Dropdown({required this.label, required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      dropdownColor: const Color(0xFF2C2C2C),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}
