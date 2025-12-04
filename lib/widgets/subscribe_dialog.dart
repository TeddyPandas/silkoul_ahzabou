import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/campaign.dart';
import '../models/task.dart';
import '../providers/campaign_provider.dart';
import '../services/supabase_service.dart';
import '../config/app_theme.dart';

class SubscribeDialog extends StatefulWidget {
  final Campaign campaign;

  const SubscribeDialog({Key? key, required this.campaign}) : super(key: key);

  @override
  _SubscribeDialogState createState() => _SubscribeDialogState();
}

class _SubscribeDialogState extends State<SubscribeDialog> {
  final SupabaseClient _supabase = SupabaseService.client;
  final Map<String, int> _selectedQuantities = {};
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _accessCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialiser les quantités à 0 ou au daily goal par défaut
    if (widget.campaign.tasks != null) {
      for (var task in widget.campaign.tasks!) {
        _selectedQuantities[task.id] = 0;
      }
    }
  }

  @override
  void dispose() {
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier qu'au moins une tâche a une quantité > 0
    final hasSelection = _selectedQuantities.values.any((q) => q > 0);
    if (!hasSelection) {
      setState(() {
        _errorMessage = "Veuillez sélectionner au moins une tâche.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Préparer les données pour l'API
      final List<Map<String, dynamic>> selectedTasks = [];
      _selectedQuantities.forEach((taskId, quantity) {
        if (quantity > 0) {
          selectedTasks.add({
            'task_id': taskId,
            'quantity': quantity,
          });
        }
      });

      // Utiliser le Provider pour la souscription
      final success = await Provider.of<CampaignProvider>(context, listen: false)
          .subscribeToCampaign(
        userId: _supabase.auth.currentUser!.id,
        campaignId: widget.campaign.id,
        accessCode: widget.campaign.isPublic ? null : _accessCodeController.text,
        selectedTasks: selectedTasks,
      );

      if (success && mounted) {
        Navigator.of(context).pop(true); // Retourne true en cas de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abonnement réussi ! Barakallahu fik.')),
        );
      } else if (mounted) {
        // L'erreur est déjà gérée dans le provider et stockée dans errorMessage
        // On peut l'afficher ici si besoin, ou laisser l'UI se mettre à jour via le Consumer
        final errorMessage =
            Provider.of<CampaignProvider>(context, listen: false).errorMessage;
        setState(() {
          _errorMessage = errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.campaign.tasks ?? [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "S'abonner à ${widget.campaign.name}",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (!widget.campaign.isPublic) ...[
              TextField(
                controller: _accessCodeController,
                decoration: const InputDecoration(
                  labelText: 'Code d\'accès',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              "Choisissez votre contribution pour chaque tâche :",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (ctx, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildTaskItem(task);
                  },
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text("Annuler"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _subscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Confirmer"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Restant: ${task.remainingNumber}",
                  style: TextStyle(
                    color: AppTheme.secondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: '0',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Votre objectif',
              suffixText: task.dailyGoal != null ? '/ jour (Rec: ${task.dailyGoal})' : null,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Requis';
              final n = int.tryParse(value);
              if (n == null) return 'Nombre invalide';
              if (n < 0) return 'Ne peut pas être négatif';
              if (n > task.remainingNumber) return 'Max: ${task.remainingNumber}';
              return null;
            },
            onChanged: (value) {
              setState(() {
                _selectedQuantities[task.id] = int.tryParse(value) ?? 0;
              });
            },
          ),
        ],
      ),
    );
  }
}
