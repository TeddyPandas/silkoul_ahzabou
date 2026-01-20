import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../teachings/models/article.dart';
import '../../teachings/providers/teachings_provider.dart';
import 'admin_scaffold.dart';

class AdminTeachingEditorScreen extends StatefulWidget {
  final Article? article;

  const AdminTeachingEditorScreen({super.key, this.article});

  @override
  State<AdminTeachingEditorScreen> createState() => _AdminTeachingEditorScreenState();
}

class _AdminTeachingEditorScreenState extends State<AdminTeachingEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _titleFrController;
  late TextEditingController _titleArController;
  late TextEditingController _contentFrController;
  late TextEditingController _contentArController;
  late TextEditingController _readTimeController;

  String? _selectedAuthorId;
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final article = widget.article;
    _titleFrController = TextEditingController(text: article?.titleFr ?? '');
    _titleArController = TextEditingController(text: article?.titleAr ?? '');
    _contentFrController = TextEditingController(text: article?.contentFr ?? '');
    _contentArController = TextEditingController(text: article?.contentAr ?? '');
    _readTimeController = TextEditingController(text: article != null ? article.readTimeMinutes.toString() : '5');
    
    _selectedAuthorId = article?.authorId;
    _selectedCategoryId = article?.categoryId;
  }

  @override
  void dispose() {
    _titleFrController.dispose();
    _titleArController.dispose();
    _contentFrController.dispose();
    _contentArController.dispose();
    _readTimeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<TeachingsProvider>(context, listen: false);
      final isEditing = widget.article != null;
      
      final article = Article(
        id: isEditing ? widget.article!.id : const Uuid().v4(), // Client-side ID for new
        titleFr: _titleFrController.text.trim(),
        titleAr: _titleArController.text.trim(),
        contentFr: _contentFrController.text.trim(),
        contentAr: _contentArController.text.trim(),
        authorId: _selectedAuthorId,
        categoryId: _selectedCategoryId,
        readTimeMinutes: int.tryParse(_readTimeController.text) ?? 5,
        publishedAt: isEditing ? widget.article!.publishedAt : DateTime.now(),
        isFeatured: isEditing ? widget.article!.isFeatured : false
      );

      if (isEditing) {
        await provider.updateArticle(article);
      } else {
        await provider.createArticle(article);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Article enregistré.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeachingsProvider>(context);
    final authors = provider.teachings.map((e) => e.author).where((a) => a != null).toSet().toList(); // Extract from teachings for now, or use dedicated list if available
    // Better: Provider should expose authors explicitly. Assuming TeachingsProvider loads categories.
    // Let's use categories from provider. For authors, we might need to fetch them if not exposed.
    // Currently TeachingsProvider doesn't expose a list of ALL authors directly separate from teachings/articles.
    // Ideally we'd use MediaProvider's authors or TeachingService's getAuthors.
    // For now, let's just use categories which ARE exposed.
    
    final categories = provider.categories;

    return AdminScaffold(
      currentRoute: '/admin/teachings',
      title: widget.article == null ? 'Nouvel Article' : 'Modifier Article',
      actions: [
        if (_isLoading)
           const Center(child: Padding(padding: EdgeInsets.only(right: 16), child: CircularProgressIndicator(color: Colors.white)))
        else
          IconButton(icon: const Icon(Icons.save), onPressed: _save, color: Colors.white)
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Metadata Section
              Card(
                color: const Color(0xFF1E1E1E),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null,
                              decoration: const InputDecoration(labelText: "Catégorie", prefixIcon: Icon(Icons.category)),
                              items: [
                                const DropdownMenuItem(value: null, child: Text("Aucune")),
                                ...categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameFr))),
                              ],
                              onChanged: (val) => setState(() => _selectedCategoryId = val),
                            ),
                          ),
                          const SizedBox(width: 16),
                           Expanded(
                            child: TextFormField(
                              controller: _readTimeController,
                              decoration: const InputDecoration(labelText: "Temps de lecture (min)", prefixIcon: Icon(Icons.timer)),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                       // TODO: Add Author Dropdown when provider exposes it properly or fetch it here
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Content Section
              TextFormField(
                controller: _titleFrController,
                decoration: const InputDecoration(labelText: "Titre (Français)", border: OutlineInputBorder()),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                validator: (v) => v!.isEmpty ? "Requis" : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _contentFrController,
                decoration: const InputDecoration(
                  labelText: "Contenu (Français)", 
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true
                ),
                maxLines: 15,
                keyboardType: TextInputType.multiline,
              ),
              
              const SizedBox(height: 32),
              const Divider(color: Colors.grey),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleArController,
                decoration: const InputDecoration(labelText: "Titre (Arabe)", border: OutlineInputBorder()),
                 textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _contentArController,
                decoration: const InputDecoration(
                  labelText: "Contenu (Arabe)", 
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true
                ),
                maxLines: 15,
                textDirection: TextDirection.rtl,
                keyboardType: TextInputType.multiline,
              ),

              const SizedBox(height: 100), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
