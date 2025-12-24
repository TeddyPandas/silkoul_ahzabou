import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';

/// ══════════════════════════════════════════════════════════════════════════════
/// DIALOG POUR TERMINER UNE TÂCHE
/// ══════════════════════════════════════════════════════════════════════════════
///
/// Permet à l'utilisateur de marquer sa tâche comme terminée en indiquant
/// combien il a réellement accompli. La différence est retournée au pool global.
///
/// EXEMPLE :
/// - User souscrit à 5 unités, entre 2 → 3 unités retournées au pool
/// - User souscrit à 5 unités, entre 5 → Tâche complète, rien retourné
/// ══════════════════════════════════════════════════════════════════════════════
class FinishTaskDialog extends StatefulWidget {
  final String taskName;
  final int subscribedQuantity;
  final int currentCompletedQuantity;

  const FinishTaskDialog({
    super.key,
    required this.taskName,
    required this.subscribedQuantity,
    this.currentCompletedQuantity = 0,
  });

  @override
  State<FinishTaskDialog> createState() => _FinishTaskDialogState();
}

class _FinishTaskDialogState extends State<FinishTaskDialog> {
  late TextEditingController _quantityController;
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default to the FULL current session pledge
    _quantityController = TextEditingController(
      text: _currentSessionSubscribed.toString(),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  int get _enteredQuantity {
    return int.tryParse(_quantityController.text) ?? 0;
  }

  // Quantité souscrite "fraîche" pour cette session
  // (Total souscrit - ce qu'on avait déjà validé avant)
  int get _currentSessionSubscribed {
    return widget.subscribedQuantity - widget.currentCompletedQuantity;
  }

  // Combien sera retourné au pool ?
  // (Total Souscrit) - (Ce qu'on avait fait avant + Ce qu'on vient de faire)
  int get _returnedToPool {
    final entered = _enteredQuantity;
    final totalDone = widget.currentCompletedQuantity + entered;

    if (totalDone > widget.subscribedQuantity) return 0; // Should not happen
    return widget.subscribedQuantity - totalDone;
  }

  void _handleConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final quantityNow = _enteredQuantity;
    final totalCompleted = widget.currentCompletedQuantity + quantityNow;

    if (quantityNow > _currentSessionSubscribed) {
      setState(() {
        _errorMessage =
            'La quantité ne peut pas dépasser $_currentSessionSubscribed';
      });
      return;
    }

    if (quantityNow < 0) {
      setState(() {
        _errorMessage = 'La quantité ne peut pas être négative';
      });
      return;
    }

    // Return the TOTAL completed (History + Now)
    Navigator.of(context).pop(totalCompleted);
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required bool isDark,
    IconData? icon,
    bool isBold = false,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold
                ? AppColors.primary
                : (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1c2536) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Terminer la tâche',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Name
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF232f48) : AppColors.offWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.assignment,
                      color:
                          isDark ? Colors.grey[400] : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.taskName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Info Block: History + Current Pledge
              if (widget.currentCompletedQuantity > 0) ...[
                _buildInfoRow(
                  label: "Déjà terminé :",
                  value: "${widget.currentCompletedQuantity}",
                  isDark: isDark,
                  icon: Icons.history,
                ),
                const SizedBox(height: 8),
              ],

              _buildInfoRow(
                label: "Nouvel engagement :",
                value: "$_currentSessionSubscribed",
                isDark: isDark,
                icon: Icons.new_releases_outlined,
                isBold: true,
              ),

              const SizedBox(height: 16),

              // Question
              Text(
                'Sur ces $_currentSessionSubscribed, combien avez-vous fait ?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              // Quantity Input
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF232f48) : AppColors.offWhite,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1,
                    ),
                  ),
                  hintText: 'Entrez la quantité',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                onChanged: (_) {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une quantité';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null) {
                    return 'Quantité invalide';
                  }
                  if (qty < 0) {
                    return 'La quantité ne peut pas être négative';
                  }
                  if (qty > _currentSessionSubscribed) {
                    return 'Max : $_currentSessionSubscribed';
                  }
                  return null;
                },
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Info about returned quantity
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _returnedToPool > 0
                      ? Colors.orange.withOpacity(0.1)
                      : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _returnedToPool > 0
                        ? Colors.orange.withOpacity(0.3)
                        : AppColors.success.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _returnedToPool > 0
                          ? Icons.info_outline
                          : Icons.check_circle,
                      color: _returnedToPool > 0
                          ? Colors.orange
                          : AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _returnedToPool > 0
                            ? '$_returnedToPool unité(s) seront retournées au pool global'
                            : 'Tâche complète ! Rien ne sera retourné.',
                        style: TextStyle(
                          fontSize: 13,
                          color: _returnedToPool > 0
                              ? Colors.orange[700]
                              : AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Annuler',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
              : const Text(
                  'Confirmer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
