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
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
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

              // ✅ SÉLECTION DE L'INTERFACE (Grid vs List)
              if (widget.campaign.category == 'Quran')
                _buildQuranGrid()
              else
                _buildStandardList(),

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
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET: GRILLE CORAN (Interactif)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildQuranGrid() {
    // Trier les tâches pour être sûr d'avoir Juz 1 à 30 dans l'ordre
    final List<dynamic> sortedTasks = List.from(widget.campaign.tasks ?? []);
    sortedTasks.sort((a, b) {
      // Extraction simple du numéro : "Juz 1" -> 1
      int numA = int.tryParse(a.name.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      int numB = int.tryParse(b.name.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return numA.compareTo(numB);
    });

    int currentSelectionCount =
        _selectedTaskQuantities.values.where((q) => q > 0).length;

    return Column(
      children: [
        Text(
          "Sélectionnez vos Juz (${currentSelectionCount}/3)",
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, // 🟢 PLUS PETIT (7 colonnes)
            childAspectRatio: 1.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: sortedTasks.length,
          itemBuilder: (context, index) {
            final task = sortedTasks[index];
            bool isSelected = (_selectedTaskQuantities[task.id] ?? 0) > 0;
            bool isAvailable = task.remainingNumber > 0;
            // Bloquer si max atteint (3) et pas déjà sélectionné par moi
            bool isLocked = !isSelected && currentSelectionCount >= 3;

            // Couleur
            Color bgColor = Colors.grey.shade100;
            Color textColor = Colors.black87;
            Color borderColor = Colors.grey.shade300;

            if (!isAvailable) {
               // Pris par quelqu'un d'autre (Gris foncé ou désactivé)
               bgColor = Colors.grey.shade300;
               textColor = Colors.grey.shade500;
               borderColor = Colors.grey.shade400;
            } else if (isSelected) {
               // ✅ Sélectionné par moi -> ROUGE VIF (comme demandé)
               bgColor = Colors.redAccent;
               textColor = Colors.white;
               borderColor = Colors.red;
            } else if (isLocked) {
               // Verrouillé (limite atteinte)
               bgColor = Colors.grey.shade50;
               textColor = Colors.grey.shade300;
            } else {
               // Disponible
               bgColor = Colors.white;
               borderColor = Colors.grey.shade400;
            }

            return InkWell(
              onTap: (!isAvailable || (isLocked && !isSelected))
                  ? null
                  : () {
                      setState(() {
                         // Toggle : 1 si 0, 0 si 1
                        int newQty = isSelected ? 0 : 1;
                        _selectedTaskQuantities[task.id] = newQty;
                      });
                    },
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: isSelected ? 0 : 1), // Pas de bordure si rempli
                  boxShadow: isSelected ? [
                    BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 4, offset: const Offset(0,2))
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      "${index + 1}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        fontSize: 12,
                      ),
                    ),
                    if (isSelected)
                      const Positioned(
                        bottom: 2,
                         right: 2,
                        child: Icon(Icons.check, size: 10, color: Colors.white),
                      ),
                    if (!isAvailable)
                       Positioned(
                        child: Icon(Icons.block, size: 24, color: Colors.grey.withOpacity(0.5)),
                      )
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET: LISTE STANDARD (Ancien design)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStandardList() {
    if (widget.campaign.tasks == null) return const SizedBox();

    return Column(
      children: widget.campaign.tasks!.map((task) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Disponible : ${task.remainingNumber.toStringAsFixed(0)} / ${task.totalNumber.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantité souhaitée',
                    hintText: '0',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.edit),
                    helperText: 'Laissez à 0 pour ne pas souscrire',
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
                    if (quantity > 0) {
                      if (quantity > task.remainingNumber) {
                        return 'Max ${task.remainingNumber}';
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

    // ✅ Validation Spécifique CORAN : Max 3 Juz
    if (widget.campaign.category == 'Quran') {
      if (validSelections.length > 3) {
        setState(() {
          _errorMessage =
              'Pour une campagne Coran, vous ne pouvez choisir que 3 Juz maximum.';
          _isLoading = false;
        });
        return;
      }
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
