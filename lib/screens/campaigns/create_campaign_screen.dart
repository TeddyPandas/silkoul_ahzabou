import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_app_bar.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _accessCodeController = TextEditingController();
  String? _selectedCategory;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isPublic = true;
  final bool _isWeekly =
      false; // Not used in backend yet, but kept for consistency

  final List<Map<String, dynamic>> _tasks = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != (isStartDate ? _startDate : _endDate)) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 7));
          }
        }
      });
    }
  }

  void _addTask() {
    setState(() {
      _tasks.add({
        'name': '',
        'number': 0,
        'daily_goal': 0,
      });
    });
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  // ✅ Helper pour générer les 30 Juz
  void _generateQuranTasks() {
    setState(() {
      _tasks.clear();
      for (int i = 1; i <= 30; i++) {
        _tasks.add({
          'name': 'Juz $i',
          'number': 1, // Par défaut 1 Khatma
          'daily_goal': 0,
        });
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('30 Juz générés automatiquement pour la campagne Coran 📖'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.tealPrimary,
      ),
    );
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// CRÉER UNE CAMPAGNE (AVEC GESTION COMPLÈTE DES ERREURS)
  /// ══════════════════════════════════════════════════════════════════════════
  Future<void> _createCampaign() async {
    // ═══════════════════════════════════════════════════════════════════════
    // VALIDATION DU FORMULAIRE
    // ═══════════════════════════════════════════════════════════════════════
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // RÉCUPÉRATION DES PROVIDERS
    // ═══════════════════════════════════════════════════════════════════════
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final campaignProvider =
        Provider.of<CampaignProvider>(context, listen: false);

    // ✅ Récupérer le userId depuis le AuthProvider
    final userId = authProvider.user?.id;

    // ═══════════════════════════════════════════════════════════════════════
    // VALIDATION DE L'AUTHENTIFICATION
    // ═══════════════════════════════════════════════════════════════════════
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Erreur: Utilisateur non authentifié. Veuillez vous reconnecter.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // CRÉATION DE LA CAMPAGNE
    // ═══════════════════════════════════════════════════════════════════════
    try {
      final campaignId = await campaignProvider.createCampaign(
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        startDate: _startDate,
        endDate: _endDate,
        category: _selectedCategory,
        isPublic: _isPublic,
        accessCode: _isPublic ? null : _accessCodeController.text,
        isWeekly: _isWeekly,
        tasks: _tasks,
        createdBy: userId, // ✅ CORRECTIF ICI - Utiliser le vrai userId
      );

      // ═══════════════════════════════════════════════════════════════════
      // GESTION DU RÉSULTAT
      // ═══════════════════════════════════════════════════════════════════
      if (!mounted) return;

      if (campaignId != null) {
        // ✅ Succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campagne créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Retour à l'écran précédent
      } else {
        // ❌ Échec (errorMessage est dans le provider)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              campaignProvider.errorMessage ?? 'Erreur lors de la création',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ❌ Exception non capturée
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur inattendue: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: const PrimaryAppBar(
        title: 'Nouvelle Campagne',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Section 1: Informations de base
              _buildSectionHeader("Informations Générales", Icons.info_outline),
              const SizedBox(height: 16),
              _buildGlassCard(
                isDark,
                children: [
                   _buildTextField(
                    controller: _nameController,
                    label: "Nom de la campagne",
                    icon: Icons.title,
                    isDark: isDark,
                    validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: "Description (Optionnel)",
                    icon: Icons.description_outlined,
                    isDark: isDark,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                   DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: _buildInputDecoration("Catégorie", Icons.category_outlined, isDark),
                    dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    isExpanded: true,
                    items: <String>['Zikr', 'Quran']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val;
                        // ✅ Auto-génération des tâches pour le Coran
                        if (val == 'Quran') {
                          _generateQuranTasks();
                        } else if (_tasks.isNotEmpty && _tasks.first['name'].toString().startsWith('Juz')) {
                          // Optionnel : ne pas effacer si l'utilisateur change d'avis, ou proposer confirmation.
                          // Pour l'instant, on laisse tel quel pour ne pas détruire du travail manuel.
                        }
                      });
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Section 2: Planning & Accès
               _buildSectionHeader("Planning & Confidentialité", Icons.calendar_today_outlined),
               const SizedBox(height: 16),
               _buildGlassCard(
                isDark,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateTile("Début", _startDate, () => _selectDate(context, true), isDark),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateTile("Fin", _endDate, () => _selectDate(context, false), isDark),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Campagne Publique', style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      _isPublic ? "Visible par tous les utilisateurs" : "Accessible uniquement par code",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: _isPublic,
                    activeColor: AppColors.tealPrimary,
                    onChanged: (val) => setState(() => _isPublic = val),
                  ),
                  if (!_isPublic) ...[
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _accessCodeController,
                      label: "Code d'accès",
                      icon: Icons.lock_outline,
                      isDark: isDark,
                      validator: (v) => !_isPublic && (v?.isEmpty ?? true) ? 'Code requis' : null,
                    ),
                  ]
                ],
               ),

              const SizedBox(height: 24),

              // Section 3: Tâches
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader("Objectifs & Tâches", Icons.check_circle_outline),
                  TextButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add_circle, color: AppColors.tealPrimary),
                    label: Text("Ajouter", style: GoogleFonts.poppins(color: AppColors.tealPrimary, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(backgroundColor: AppColors.tealPrimary.withOpacity(0.1)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (_tasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(30),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.list_alt, size: 48, color: Colors.grey.withOpacity(0.5)),
                      const SizedBox(height: 8),
                      Text("Aucune tâche définie", style: GoogleFonts.poppins(color: Colors.grey)),
                    ],
                  ),
                )
              else if (_selectedCategory == 'Quran')
                 _buildQuranCreationGrid(isDark)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildTaskCard(index, isDark);
                  },
                ),

              const SizedBox(height: 40),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _createCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: AppColors.tealPrimary.withOpacity(0.4),
                  ),
                  child: Text(
                    'LANCER LA CAMPAGNE',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGETS HELPER - UI PREMIUM
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.tealPrimary),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard(bool isDark, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      validator: validator,
      decoration: _buildInputDecoration(label, icon, isDark),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
      prefixIcon: Icon(icon, color: isDark ? Colors.grey[500] : Colors.grey[400]),
      filled: true,
      fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.tealPrimary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildDateTile(String label, DateTime date, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.event, size: 16, color: isDark ? Colors.white70 : Colors.black87),
                const SizedBox(width: 8),
                Text(
                  date.toLocal().toIso8601String().split('T').first,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(int index, bool isDark) {
    final task = _tasks[index];
    return Dismissible(
      key: ValueKey("task_$index"),
      onDismissed: (_) => _removeTask(index),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.tealPrimary.withOpacity(0.3)),
          boxShadow: [
             BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.tealPrimary.withOpacity(0.1), shape: BoxShape.circle),
                  child: Text("${index + 1}", style: const TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: task['name'],
                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(
                      hintText: "Nom de la tâche (ex: 100 Istighfar)",
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (v) => task['name'] = v,
                    validator: (v) => v?.isNotEmpty == true ? null : 'Requis',
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.red), onPressed: () => _removeTask(index)),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: task['number'].toString(),
                    keyboardType: TextInputType.number,
                     style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                    decoration: const InputDecoration(
                      labelText: "Total",
                      border: InputBorder.none,
                      alignLabelWithHint: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                     onChanged: (v) => task['number'] = int.tryParse(v) ?? 0,
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: task['daily_goal'].toString(),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                    decoration: const InputDecoration(
                      labelText: "Objectif journalier",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => task['daily_goal'] = int.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ UI Spéciale pour la création de campagne Coran (Grille Simple)
  Widget _buildQuranCreationGrid(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tealPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.tealPrimary.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_stories, color: AppColors.tealPrimary, size: 40),
          const SizedBox(height: 12),
          Text(
            "Mode Coran Activé",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Les 30 Juz seront générés automatiquement.\nVos participants verront une grille de sélection (1-3 Juz).",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
