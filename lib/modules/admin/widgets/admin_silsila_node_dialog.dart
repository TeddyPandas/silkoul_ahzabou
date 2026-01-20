import 'package:flutter/material.dart';
import '../../../../services/silsila_service.dart';
import '../../../../models/silsila_node.dart';
import '../../../../utils/app_theme.dart';

class AdminSilsilaNodeDialog extends StatefulWidget {
  final SilsilaNode? node;

  const AdminSilsilaNodeDialog({super.key, this.node});

  @override
  State<AdminSilsilaNodeDialog> createState() => _AdminSilsilaNodeDialogState();
}

class _AdminSilsilaNodeDialogState extends State<AdminSilsilaNodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = SilsilaService();
  late TextEditingController _nameController;
  late TextEditingController _searchParentController;
  
  String? _parentId;
  String? _parentName; // For display
  
  List<SilsilaNode> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isGlobal = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.node?.name ?? '');
    _searchParentController = TextEditingController();
    _isGlobal = widget.node?.isGlobal ?? true;
    
    // Attempt to load current parent if editing
    if (widget.node != null && widget.node!.parentIds.isNotEmpty) {
      _parentId = widget.node!.parentIds.first;
      _loadParentName(_parentId!);
    }
  }

  Future<void> _loadParentName(String id) async {
    // We can't easily fetch just one node by ID with current service without full graph query or search
    // But we can search by ID if we tweak search, or just search by name if we knew it to confirm?
    // Let's implement a 'getNodeById' ideally, but for now let's just use what we have or assume user knows.
    // Actually, let's just fetch all global nodes or search to find it. 
    // Hack: search by ID if it was supported, otherwise we might just show "Parent ID: ..." until we have a proper fetch.
    // Better: Add getById to service. For now, let's leave name empty until user sets it or we improve service.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchParentController.dispose();
    super.dispose();
  }

  Future<void> _searchParents(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    
    setState(() => _isSearching = true);
    try {
      final results = await _service.searchNodes(query);
      setState(() {
        _searchResults = results.where((n) => n.id != widget.node?.id).toList();
      });
    } catch (e) {
      print("Error searching: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.node != null) {
        // Edit Basic Info
        await _service.updateNode(
          widget.node!.id,
          name: _nameController.text.trim(),
          isGlobal: _isGlobal,
        );
        
        // Handle Parent/Chain Change
        final currentParents = widget.node!.parentIds;
        final oldParentId = currentParents.isNotEmpty ? currentParents.first : null;

        if (_parentId != oldParentId) {
          // Changed
          if (oldParentId != null) {
            await _service.unlinkParent(childId: widget.node!.id, parentId: oldParentId);
          }
          if (_parentId != null) {
            await _service.addConnection(childId: widget.node!.id, parentId: _parentId!);
          }
        }

      } else {
        // Create
        await _service.createNode(
          name: _nameController.text.trim(),
          isGlobal: _isGlobal,
          parentId: _parentId
        );
      }
      if (mounted) Navigator.pop(context, true);
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
    final darkTheme = Theme.of(context).brightness == Brightness.dark;
    final bgColor = darkTheme ? const Color(0xFF1E1E1E) : Colors.white;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView( // Handle keyboard
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.node == null ? "Nouveau Maillon (Compagnon)" : "Modifier Maillon",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "La Silsila représente la chaîne de transmission spirituelle.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
        
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Nom du Compagnon / Cheikh", prefixIcon: Icon(Icons.person)),
                  validator: (v) => v!.isEmpty ? "Requis" : null,
                ),
                const SizedBox(height: 16),
        
                SwitchListTile(
                  title: const Text("Visible dans l'arbre global ?"),
                  subtitle: const Text("Cochez pour les compagnons historiques."),
                  value: _isGlobal,
                  onChanged: (val) => setState(() => _isGlobal = val),
                   contentPadding: EdgeInsets.zero,
                ),
        
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                
                Text("Vient de (Maître Spirituel)", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                
                if (_parentId != null)
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(color: AppColors.tealPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                     child: Row(
                       children: [
                         const Icon(Icons.link, color: AppColors.tealPrimary),
                         const SizedBox(width: 12),
                         Expanded(child: Text(_parentName ?? "Maître sélectionné (ID: $_parentId)")),
                         IconButton(
                           icon: const Icon(Icons.close, color: Colors.red), 
                           onPressed: () => setState(() { _parentId = null; _parentName = null; }),
                           tooltip: "Retirer le lien",
                         )
                       ],
                     ),
                   )
                else
                  const Text("Aucun maître défini (Racine ou Orphelin)", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  
                const SizedBox(height: 16),
                TextFormField(
                  controller: _searchParentController,
                  decoration: InputDecoration(
                    labelText: "Rechercher le maître...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) : null
                  ),
                  onChanged: (val) {
                    if (val.length > 2) _searchParents(val);
                  },
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    height: 150,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: ListView.separated(
                      itemCount: _searchResults.length,
                      separatorBuilder: (_,__) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final node = _searchResults[index];
                        return ListTile(
                          title: Text(node.name),
                          dense: true,
                          onTap: () {
                             setState(() {
                               _parentId = node.id;
                               _parentName = node.name;
                               _searchResults = [];
                               _searchParentController.clear();
                             });
                          },
                        );
                      }
                    ),
                  ),
        
                const SizedBox(height: 32),
        
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                     TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Annuler"),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldPrimary, // Premium/Admin color
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("Enregistrer"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
