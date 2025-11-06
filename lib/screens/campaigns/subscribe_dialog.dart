import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/campaign.dart';
import '../../models/task.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/auth_provider.dart';

class SubscribeDialog extends StatefulWidget {
  final Campaign campaign;
  final VoidCallback onSubscriptionSuccess;

  const SubscribeDialog({
    super.key,
    required this.campaign,
    required this.onSubscriptionSuccess,
  });

  @override
  State<SubscribeDialog> createState() => _SubscribeDialogState();
}

class _SubscribeDialogState extends State<SubscribeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accessCodeController = TextEditingController();
  final Map<String, int> _selectedTaskQuantities = {}; // taskId -> quantity
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize selected quantities for tasks
    if (widget.campaign.tasks != null) {
      for (var task in widget.campaign.tasks!) {
        _selectedTaskQuantities[task.id] = 0; // Default to 0
      }
    }
  }

  @override
  void dispose() {
    _accessCodeController.dispose();
    super.dispose();
  }

  void _updateTaskQuantity(String taskId, int quantity) {
    setState(() {
      _selectedTaskQuantities[taskId] = quantity;
    });
  }

  Future<void> _subscribe() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final campaignProvider =
          Provider.of<CampaignProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        setState(() {
          _errorMessage = 'User not authenticated.';
          _isLoading = false;
        });
        return;
      }

      try {
        // Validation locale avant l'appel API
        final validSelections = _selectedTaskQuantities.entries
            .where((entry) => entry.value > 0)
            .toList();

        if (validSelections.isEmpty) {
          setState(() {
            _errorMessage = 'Veuillez sélectionner au moins une tâche';
            _isLoading = false;
          });
          return;
        }

        // Vérifier que chaque quantité ne dépasse pas le disponible
        for (var entry in validSelections) {
          final task = widget.campaign.tasks!.firstWhere((t) => t.id == entry.key);
          if (entry.value > task.remainingNumber) {
            setState(() {
              _errorMessage = 'Quantité trop élevée pour "${task.name}". Maximum disponible : ${task.remainingNumber}';
              _isLoading = false;
            });
            return;
          }
        }

        final List<Map<String, dynamic>> taskSubscriptions =
            validSelections
                .map((entry) => {
                      'task_id': entry.key,
                      'quantity': entry.value, // ✅ CORRECTION : "quantity" au lieu de "subscribed_quantity"
                    })
                .toList();

        final success = await campaignProvider.subscribeToCampaign(
          userId: userId,
          campaignId: widget.campaign.id,
          accessCode:
              widget.campaign.isPublic ? null : _accessCodeController.text,
          selectedTasks: taskSubscriptions,
        );

        if (success) {
          // Fermer le dialog
          Navigator.of(context).pop();

          // Afficher un message de succès
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Abonnement réussi ! 🎉'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 3),
              ),
            );
          }

          // Callback pour rafraîchir les données
          widget.onSubscriptionSuccess();
        } else if (campaignProvider.errorMessage != null) {
          setState(() {
            _errorMessage = campaignProvider.errorMessage;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join Campaign'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Campaign: ${widget.campaign.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (!widget.campaign.isPublic)
                TextFormField(
                  controller: _accessCodeController,
                  decoration: const InputDecoration(labelText: 'Access Code'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the access code';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              if (widget.campaign.tasks != null &&
                  widget.campaign.tasks!.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Tasks to Join:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...widget.campaign.tasks!.map((task) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${task.name} (Available: ${task.remainingNumber})',
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue:
                                    _selectedTaskQuantities[task.id].toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 12),
                                ),
                                onChanged: (value) {
                                  int? quantity = int.tryParse(value);
                                  if (quantity != null &&
                                      quantity >= 0 &&
                                      quantity <= task.remainingNumber) {
                                    _updateTaskQuantity(task.id, quantity);
                                  } else if (quantity != null &&
                                      quantity > task.remainingNumber) {
                                    _updateTaskQuantity(task.id,
                                        task.remainingNumber); // Cap at remaining
                                  } else {
                                    _updateTaskQuantity(task.id,
                                        0); // Default to 0 for invalid input
                                  }
                                },
                                validator: (value) {
                                  int? quantity = int.tryParse(value ?? '0');
                                  if (quantity == null ||
                                      quantity < 0 ||
                                      quantity > task.remainingNumber) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _subscribe,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Join'),
        ),
      ],
    );
  }
}
