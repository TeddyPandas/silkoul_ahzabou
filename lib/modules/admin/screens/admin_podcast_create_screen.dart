import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../utils/app_theme.dart';
import '../../teachings/models/teaching.dart';
import '../../teachings/models/podcast_show.dart';
import '../../teachings/models/author.dart';
import '../../teachings/models/category.dart';
import '../../teachings/models/transcript_segment.dart';
import '../../teachings/services/teaching_service.dart';
import '../../../services/storage_service.dart';
import '../widgets/transcript_editor_widget.dart';
import 'admin_scaffold.dart';
import '../widgets/admin_form_fields.dart';

class AdminPodcastCreateScreen extends StatefulWidget {
  const AdminPodcastCreateScreen({super.key});

  @override
  State<AdminPodcastCreateScreen> createState() => _AdminPodcastCreateScreenState();
}

class _AdminPodcastCreateScreenState extends State<AdminPodcastCreateScreen> with SingleTickerProviderStateMixin {
  // Dependencies
  List<Author> _authors = [];
  List<PodcastShow> _shows = [];
  List<Category> _categories = [];

  // Form State
  final _titleFrController = TextEditingController();
  final _titleArController = TextEditingController();
  final _descFrController = TextEditingController();
  String? _selectedAuthorId;
  String? _selectedShowId;
  String? _selectedCategoryId;
  
  // Audio State
  PlatformFile? _selectedAudioFile;
  String? _uploadedAudioUrl;
  bool _isUploading = false;
  int _audioDuration = 0; 

  // Transcript State
  List<TranscriptSegment> _transcriptSegments = [];
  late TabController _tabController;

  // Edit Mode
  Teaching? _episodeToEdit;
  bool get _isEditMode => _episodeToEdit != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Defer loading args until dependencies logic starts or in didChangeDependencies
    // But we need to load dependencies first anyway.
    _loadDependenciesAndArgs();
  }

  Future<void> _loadDependenciesAndArgs() async {
    final authors = await TeachingService.instance.getAuthors();
    final shows = await TeachingService.instance.getPodcastShows();
    final categories = await TeachingService.instance.getCategories();
    
    if (!mounted) return;

    setState(() {
      _authors = authors;
      _shows = shows;
      _categories = categories;
    });

    // Check arguments for Edit Mode
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Teaching) {
      _episodeToEdit = args;
      _initializeEditMode();
    }
  }

  Future<void> _initializeEditMode() async {
    if (_episodeToEdit == null) return;
    final ep = _episodeToEdit!;

    _titleFrController.text = ep.titleFr;
    _titleArController.text = ep.titleAr;
    _descFrController.text = ep.descriptionFr ?? '';
    _selectedAuthorId = ep.authorId;
    _selectedShowId = ep.podcastShowId;
    _selectedCategoryId = ep.categoryId;
    _uploadedAudioUrl = ep.mediaUrl;
    _audioDuration = ep.durationSeconds;

    // Load transcript
    final transcript = await TeachingService.instance.getTranscript(ep.id);
    setState(() {
      _transcriptSegments = transcript;
    });
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null) {
      setState(() {
        _selectedAudioFile = result.files.single;
        _uploadedAudioUrl = null; // Reset upload status (forces re-upload)
      });
    }
  }

  Future<void> _uploadAudio() async {
    if (_selectedAudioFile == null) return;
    if (_selectedShowId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez sélectionner une émission d'abord.")));
      return;
    }

    setState(() => _isUploading = true);
    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}.mp3";
      final path = "podcasts/$_selectedShowId/$fileName";
      
      String url;
      if (_selectedAudioFile!.bytes != null) {
         // Web / Bytes
         url = await StorageService.instance.uploadAudio(bytes: _selectedAudioFile!.bytes, path: path);
      } else if (_selectedAudioFile!.path != null) {
         // Mobile / Path
         url = await StorageService.instance.uploadAudio(file: File(_selectedAudioFile!.path!), path: path);
      } else {
         throw Exception("Invalid file: neither path nor bytes available");
      }
      
      setState(() {
        _uploadedAudioUrl = url;
        _isUploading = false;
        _audioDuration = 60; // Mock
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload réussi !")));
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur upload: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveEpisode() async {
    if (_titleFrController.text.isEmpty || _uploadedAudioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Titre et Audio sont requis.")));
      return;
    }

    try {
      final teachingData = Teaching(
        id: _episodeToEdit?.id ?? '', // Use existing ID if edit
        type: TeachingType.AUDIO,
        titleFr: _titleFrController.text,
        titleAr: _titleArController.text,
        descriptionFr: _descFrController.text,
        authorId: _selectedAuthorId,
        categoryId: _selectedCategoryId ?? _categories.firstOrNull?.id ?? '',
        podcastShowId: _selectedShowId,
        mediaUrl: _uploadedAudioUrl!,
        durationSeconds: _audioDuration,
        publishedAt: _episodeToEdit?.publishedAt ?? DateTime.now(), thumbnailUrl: '',
      );
      
      String teachingId;
      if (_isEditMode) {
        await TeachingService.instance.updatePodcastEpisode(teachingData);
        teachingId = teachingData.id;
      } else {
        teachingId = await TeachingService.instance.createPodcastEpisode(teachingData);
      }

      // Save Transcript (Always save/update if present)
      // Even if empty, we might want to clear it? 
      // For now, save whatever is in the list.
      await TeachingService.instance.saveTranscript(teachingId, _transcriptSegments);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sauvegardé avec succès !")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur sauvegarde: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: '/admin/shows',
      title: _isEditMode ? 'Modifier Épisode' : 'Nouvel Épisode Podcast',
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.tealPrimary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.tealPrimary,
            tabs: const [
              Tab(text: "1. Détails & Audio"),
              Tab(text: "2. Transcription"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildTranscriptTab(),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E1E1E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _saveEpisode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(_isEditMode ? "METTRE À JOUR" : "PUBLIER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: AdminDropdown(label: "Émission (Série)", value: _selectedShowId, items: _shows.map((s) => DropdownMenuItem(value: s.id, child: Text(s.titleFr))).toList(), onChanged: (v) => setState(() => _selectedShowId = v))),
              const SizedBox(width: 16),
              Expanded(child: AdminDropdown(label: "Auteur", value: _selectedAuthorId, items: _authors.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(), onChanged: (v) => setState(() => _selectedAuthorId = v))),
            ],
          ),
          const SizedBox(height: 16),
           AdminDropdown(label: "Catégorie", value: _selectedCategoryId, items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nameFr))).toList(), onChanged: (v) => setState(() => _selectedCategoryId = v)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: AdminTextField(controller: _titleFrController, label: "Titre (Français)")),
              const SizedBox(width: 16),
              Expanded(child: AdminTextField(controller: _titleArController, label: "Titre (Arabe)")),
            ],
          ),
          const SizedBox(height: 16),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AdminTextField(
                  controller: _descFrController, 
                  label: "Description", 
                  maxLines: 3
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: AdminTextField(
                  controller: TextEditingController(text: _audioDuration.toString()),
                  label: "Durée (sec)",
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    setState(() {
                      _audioDuration = int.tryParse(val) ?? 0;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          Text("Fichier Audio", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[800]!), borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickAudio,
                  icon: const Icon(Icons.folder_open),
                  label: const Text("Choisir/Remplacer"),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(_selectedAudioFile?.name ?? (_uploadedAudioUrl != null ? "Fichier existant (URL)" : "Aucun fichier"), style: const TextStyle(color: Colors.white))),
                
                if (_selectedAudioFile != null && (_uploadedAudioUrl == null || _uploadedAudioUrl != _episodeToEdit?.mediaUrl))
                   ElevatedButton(
                    onPressed: _isUploading ? null : _uploadAudio,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: _isUploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Uploader", style: TextStyle(color: Colors.white)),
                  ),
                if (_uploadedAudioUrl != null)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.check_circle, color: Colors.green),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            "Éditeur de Transcription",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TranscriptEditorWidget(
              initialSegments: _transcriptSegments,
              totalDuration: _audioDuration,
              onChanged: (segments) {
                _transcriptSegments = segments;
              },
            ),
          ),
        ],
      ),
    );
  }
}


