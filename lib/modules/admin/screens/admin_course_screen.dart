import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../../utils/error_handler.dart';
import '../../calendar/models/course.dart';
import '../../calendar/providers/calendar_provider.dart';

class AdminCourseScreen extends StatefulWidget {
  const AdminCourseScreen({super.key});

  @override
  State<AdminCourseScreen> createState() => _AdminCourseScreenState();
}

class _AdminCourseScreenState extends State<AdminCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _teacherController = TextEditingController();
  final _linkController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _durationMinutes = 60;
  String _recurrence = 'once';
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarProvider>().fetchCourses();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _teacherController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);

    try {
      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'teacher_name': _teacherController.text.trim(),
        'start_time': startTime.toIso8601String(),
        'duration_minutes': _durationMinutes,
        'telegram_link': _linkController.text.trim(),
        'recurrence': _recurrence,
        'recurrence_day': _recurrence == 'weekly' ? startTime.weekday : null,
      };

      final success = await context.read<CalendarProvider>().createCourse(data);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Cours créé + notification Telegram envoyée', style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.success,
          ),
        );
        _titleController.clear();
        _descController.clear();
        _teacherController.clear();
        _linkController.clear();
        setState(() {
          _recurrence = 'once';
          _durationMinutes = 60;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.sanitize(e), style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ═══════════════════════════════════════════════════
  // EDIT / RESCHEDULE DIALOG
  // ═══════════════════════════════════════════════════

  Future<void> _showEditDialog(Course course) async {
    final editTitleCtrl = TextEditingController(text: course.title);
    final editDescCtrl = TextEditingController(text: course.description ?? '');
    final editTeacherCtrl = TextEditingController(text: course.teacherName ?? '');
    final editLinkCtrl = TextEditingController(text: course.telegramLink ?? '');
    DateTime editDate = course.startTime;
    TimeOfDay editTime = TimeOfDay(hour: course.startTime.hour, minute: course.startTime.minute);
    int editDuration = course.durationMinutes;
    String editRecurrence = course.recurrence;
    final editFormKey = GlobalKey<FormState>();
    final oldStartTime = course.startTime.toIso8601String();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit_calendar, color: AppColors.tealPrimary),
              SizedBox(width: 8),
              Text('Modifier / Reprogrammer'),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: Form(
              key: editFormKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: editTitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Titre du cours',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: editTeacherCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Professeur',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: editLinkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Lien Telegram',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date & Time row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: editDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                              );
                              if (picked != null) {
                                setDialogState(() => editDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Nouvelle date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              child: Text(DateFormat('dd/MM/yyyy').format(editDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: editTime,
                              );
                              if (picked != null) {
                                setDialogState(() => editTime = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Nouvelle heure',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text('${editTime.hour.toString().padLeft(2, '0')}:${editTime.minute.toString().padLeft(2, '0')}'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: editRecurrence,
                            decoration: const InputDecoration(
                              labelText: 'Récurrence',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.repeat),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'once', child: Text('Unique')),
                              DropdownMenuItem(value: 'weekly', child: Text('Chaque semaine')),
                              DropdownMenuItem(value: 'daily', child: Text('Chaque jour')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => editRecurrence = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: editDuration.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Durée (min)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timer),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final parsed = int.tryParse(v);
                              if (parsed != null) editDuration = parsed;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: editDescCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!editFormKey.currentState!.validate()) return;
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;

    // Build the update data
    final newStartTime = DateTime(
      editDate.year,
      editDate.month,
      editDate.day,
      editTime.hour,
      editTime.minute,
    );

    final updates = <String, dynamic>{
      'title': editTitleCtrl.text.trim(),
      'description': editDescCtrl.text.trim(),
      'teacher_name': editTeacherCtrl.text.trim(),
      'start_time': newStartTime.toIso8601String(),
      'duration_minutes': editDuration,
      'telegram_link': editLinkCtrl.text.trim(),
      'recurrence': editRecurrence,
      'recurrence_day': editRecurrence == 'weekly' ? newStartTime.weekday : null,
    };

    final success = await context.read<CalendarProvider>().updateCourse(
      course.id,
      updates,
      oldStartTime: oldStartTime,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔄 Cours reprogrammé + notification Telegram envoyée', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.tealPrimary,
        ),
      );
    }

    editTitleCtrl.dispose();
    editDescCtrl.dispose();
    editTeacherCtrl.dispose();
    editLinkCtrl.dispose();
  }

  // ═══════════════════════════════════════════════════
  // CANCEL COURSE (with Telegram notification)
  // ═══════════════════════════════════════════════════

  Future<void> _cancelCourse(Course course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: AppColors.error),
            SizedBox(width: 8),
            Text('Annuler ce cours'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous annuler le cours "${course.title}" ?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Une notification d\'annulation sera envoyée sur le canal Telegram.',
                      style: TextStyle(fontSize: 13, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non, garder'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.cancel),
            label: const Text('Oui, annuler le cours'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<CalendarProvider>().cancelCourse(course.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Cours annulé + notification Telegram envoyée', style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // DELETE COURSE (silent, no Telegram)
  // ═══════════════════════════════════════════════════

  Future<void> _deleteCourse(Course course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce cours'),
        content: Text('Voulez-vous supprimer "${course.title}" sans notifier le canal ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<CalendarProvider>().deleteCourse(course.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cours supprimé', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // BUILD UI
  // ═══════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: const Text('Gestion des Cours'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          bottom: const TabBar(
            labelColor: AppColors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.gold,
            tabs: [
              Tab(text: 'Nouveau', icon: Icon(Icons.add_circle_outline)),
              Tab(text: 'Liste', icon: Icon(Icons.list_alt)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCreateForm(),
            _buildCourseList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.grey[400]),
          hintStyle: TextStyle(color: Colors.grey[600]),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[600]!),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.tealPrimary),
          ),
          prefixIconColor: Colors.grey[400],
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: const TextStyle(color: Colors.white),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre du cours',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teacherController,
              decoration: const InputDecoration(
                labelText: 'Nom du professeur (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Lien Telegram (Canal)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de début',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Heure',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(_selectedTime.format(context)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _recurrence,
                    decoration: const InputDecoration(
                      labelText: 'Récurrence',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'once', child: Text('Unique')),
                      DropdownMenuItem(value: 'weekly', child: Text('Chaque semaine')),
                      DropdownMenuItem(value: 'daily', child: Text('Chaque jour')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _recurrence = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _durationMinutes.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Durée (min)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null) _durationMinutes = parsed;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optionnelle)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: const Text('Créer le cours + Notifier Telegram', style: TextStyle(fontSize: 15)),
            ),
          ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildCourseList() {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.tealPrimary));
        }

        final originalCourses = provider.courses;

        if (originalCourses.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucun cours n\'a été créé.', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: originalCourses.length,
              itemBuilder: (context, index) {
                final course = originalCourses[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              color: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.tealPrimary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                              if (course.teacherName != null && course.teacherName!.isNotEmpty)
                                Text(
                                  '👨‍🏫 ${course.teacherName}',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                        // Recurrence badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: course.isRecurring ? Colors.blue.shade900.withValues(alpha: 0.3) : Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            course.recurrenceLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: course.isRecurring ? Colors.blue.shade200 : Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Date & Duration
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('EEEE dd/MM/yyyy').format(course.startTime),
                          style: TextStyle(fontSize: 13, color: Colors.grey[300]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('HH:mm').format(course.startTime),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${course.durationMinutes}min)',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    if (course.telegramLink != null && course.telegramLink!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.link, size: 16, color: Colors.blue[300]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              course.telegramLink!,
                              style: TextStyle(fontSize: 12, color: Colors.blue[300]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    Divider(height: 20, color: Colors.grey[700]),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Edit / Reschedule
                        TextButton.icon(
                          onPressed: () => _showEditDialog(course),
                          icon: const Icon(Icons.edit_calendar, size: 18),
                          label: const Text('Modifier'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.tealPrimary),
                        ),
                        const SizedBox(width: 8),
                        // Cancel (with Telegram notification)
                        TextButton.icon(
                          onPressed: () => _cancelCourse(course),
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Annuler'),
                          style: TextButton.styleFrom(foregroundColor: Colors.orange),
                        ),
                        const SizedBox(width: 8),
                        // Silent delete
                        IconButton(
                          onPressed: () => _deleteCourse(course),
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.red.shade300,
                          tooltip: 'Supprimer (sans notification)',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
              },
            ),
          ),
        );
      },
    );
  }
}
