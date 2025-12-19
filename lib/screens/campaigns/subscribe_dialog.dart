// lib/screens/campaigns/subscribe_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign.dart';
import '../../providers/auth_provider.dart';
import '../../providers/campaign_provider.dart';

class SubscribeDialog extends StatefulWidget {
  final Campaign campaign;
  final VoidCallback onSubscriptionSuccess;
  final String? initialAccessCode;

  const SubscribeDialog({
    Key? key,
    required this.campaign,
    required this.onSubscriptionSuccess,
    this.initialAccessCode,
  }) : super(key: key);

  @override
  State<SubscribeDialog> createState() => _SubscribeDialogState();
}

class _SubscribeDialogState extends State<SubscribeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _accessCodeController;

  // ✅ Structure correcte : Map<taskId, quantity>
  final Map<String, int> _selectedTaskQuantities = {};

  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _accessCodeController =
        TextEditingController(text: widget.initialAccessCode);

    // ✅ Initialiser toutes les tâches à quantité 0
    if (widget.campaign.tasks != null) {
      for (var task in widget.campaign.tasks!) {
        _selectedTaskQuantities[task.id] = 0;
      }
    }
  }

  @override
  void dispose() {
    _accessCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rejoindre ${widget.campaign.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message d'information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Choisissez les tâches et indiquez combien vous souhaitez accomplir.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Code d'accès pour campagnes privées
              if (!widget.campaign.isPublic) ...[
                TextFormField(
                  controller: _accessCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Code d\'accès',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Code d\'accès requis pour cette campagne';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Liste des tâches
              const Text(
                'Tâches disponibles :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Afficher chaque tâche
              if (widget.campaign.tasks != null)
                ...widget.campaign.tasks!.map((task) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nom de la tâche
                          Text(
                            task.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Quantité disponible
                          Text(
                            'Disponible : ${task.remainingNumber.toStringAsFixed(0)} / ${task.totalNumber.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Champ de saisie de quantité
                          TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantité souhaitée',
                              hintText: '0',
                              border: const OutlineInputBorder(),
                              suffixIcon: const Icon(Icons.edit),
                              helperText:
                                  'Laissez à 0 pour ne pas souscrire à cette tâche',
                            ),
                            initialValue: '0',
                            onChanged: (value) {
                              final quantity = int.tryParse(value) ?? 0;
                              setState(() {
                                _selectedTaskQuantities[task.id] = quantity;
                              });
                            },
                            validator: (value) {
                              final quantity = int.tryParse(value ?? '0') ?? 0;

                              // Si quantité > 0, vérifier qu'elle est valide
                              if (quantity > 0) {
                                if (quantity > task.remainingNumber) {
                                  return 'Maximum ${task.remainingNumber.toStringAsFixed(0)} disponible';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),

              // Message d'erreur
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        // Bouton Annuler
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),

        // Bouton Valider
        ElevatedButton(
          onPressed: _isLoading ? null : _subscribe,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Valider'),
        ),
      ],
    );
  }

  // ============================================
  // ✅ MÉTHODE DE SOUSCRIPTION CORRIGÉE
  // ============================================
  Future<void> _subscribe() async {
    // Validation du formulaire (code d'accès si privé)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final campaignProvider =
        Provider.of<CampaignProvider>(context, listen: false);
    final userId = authProvider.user?.id;

    // ✅ VALIDATION CRITIQUE #1 : Utilisateur authentifié
    if (userId == null) {
      setState(() {
        _errorMessage = 'Vous devez être connecté pour vous abonner.';
        _isLoading = false;
      });
      return;
    }

    // ✅ VALIDATION CRITIQUE #2 : Au moins 1 tâche avec quantity > 0
    final validSelections = _selectedTaskQuantities.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (validSelections.isEmpty) {
      setState(() {
        _errorMessage =
            'Veuillez sélectionner au moins une tâche avec une quantité supérieure à 0.';
        _isLoading = false;
      });
      return;
    }

    // ✅ VALIDATION CRITIQUE #3 : Vérifier que chaque quantité <= remainingNumber
    for (var entry in validSelections) {
      final task = widget.campaign.tasks!.firstWhere((t) => t.id == entry.key);
      if (entry.value > task.remainingNumber) {
        setState(() {
          _errorMessage =
              'La quantité demandée pour "${task.name}" dépasse le nombre disponible (${task.remainingNumber.toStringAsFixed(0)}).';
          _isLoading = false;
        });
        return;
      }
    }

    // ✅ FORMAT CORRECT : "quantity" au lieu de "subscribed_quantity"
    final List<Map<String, dynamic>> taskSubscriptions = validSelections
        .map((entry) => {
              'task_id': entry.key,
              'quantity': entry.value, // ✅ NOM CORRECT pour le backend
            })
        .toList();

    // ✅ APPEL API AVEC TRY-CATCH
    try {
      final success = await campaignProvider.subscribeToCampaign(
        userId: userId,
        campaignId: widget.campaign.id,
        accessCode:
            widget.campaign.isPublic ? null : _accessCodeController.text,
        selectedTasks: taskSubscriptions,
      );

      if (!mounted) return;

      if (success) {
        // ✅ Succès : Fermer le dialog et notifier
        widget.onSubscriptionSuccess();
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Abonnement réussi !'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // ❌ Échec : Afficher l'erreur du provider
        setState(() {
          _errorMessage = campaignProvider.errorMessage ??
              'Une erreur est survenue lors de l\'abonnement.';
          _isLoading = false;
        });
      }
    } catch (e) {
      // ❌ Exception non capturée : Afficher l'erreur
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Erreur : ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}
