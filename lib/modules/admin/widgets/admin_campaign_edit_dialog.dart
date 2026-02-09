import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import '../../../../services/campaign_service.dart';
import '../../../../models/campaign.dart';

class AdminCampaignEditDialog extends StatefulWidget {
  final Campaign campaign;

  const AdminCampaignEditDialog({super.key, required this.campaign});

  @override
  State<AdminCampaignEditDialog> createState() => _AdminCampaignEditDialogState();
}

class _AdminCampaignEditDialogState extends State<AdminCampaignEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _accessCodeController;
  late String? _selectedCategory;
  late bool _isPublic;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.campaign.name);
    _descriptionController = TextEditingController(text: widget.campaign.description);
    _accessCodeController = TextEditingController(text: widget.campaign.accessCode);
    _selectedCategory = widget.campaign.category;
    _isPublic = widget.campaign.isPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updates = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        'category': _selectedCategory,
        'is_public': _isPublic,
        'access_code': _isPublic ? null : _accessCodeController.text.trim(),
      };

      await CampaignService().updateCampaign(widget.campaign.id, updates);
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text("Modifier la campagne", style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Nom"),
                  validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: _inputDecoration("Description"),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  dropdownColor: const Color(0xFF2C2C2C),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Catégorie"),
                  items: ['Zikr', 'Quran', 'Dua', 'Charity', 'Community']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => _selectedCategory = val,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text("Publique", style: TextStyle(color: Colors.white)),
                  value: _isPublic,
                  onChanged: (val) => setState(() => _isPublic = val),
                  activeColor: AppColors.tealPrimary,
                  contentPadding: EdgeInsets.zero,
                ),
                if (!_isPublic) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _accessCodeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration("Code d'accès"),
                    validator: (v) => !_isPublic && (v?.isEmpty ?? true) ? 'Requis' : null,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealPrimary),
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Enregistrer"),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }
}
