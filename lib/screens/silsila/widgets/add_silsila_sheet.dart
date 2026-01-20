
import 'package:flutter/material.dart';
import 'package:silkoul_ahzabou/models/silsila.dart';
import 'package:silkoul_ahzabou/services/silsila_service.dart';

class AddSilsilaSheet extends StatefulWidget {
  final Function(Silsila selectedNode)? onSelect;

  const AddSilsilaSheet({super.key, this.onSelect});

  @override
  State<AddSilsilaSheet> createState() => _AddSilsilaSheetState();
}

class _AddSilsilaSheetState extends State<AddSilsilaSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SilsilaService _silsilaService = SilsilaService();
  
  // Search State
  final TextEditingController _searchController = TextEditingController();
  List<Silsila> _searchResults = [];
  bool _isSearching = false;
  
  // Create State
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;
  
  // Logic for Nested Parent Search
  Silsila? _selectedParent;
  List<Silsila> _parentSearchResults = [];
  bool _isSearchingParent = false;

  Future<void> _performParentSearch(String query) async {
    setState(() => _isSearchingParent = true);
    try {
      final results = await _silsilaService.searchSilsila(query);
      if (mounted) setState(() => _parentSearchResults = results);
    } finally {
      if (mounted) setState(() => _isSearchingParent = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await _silsilaService.searchSilsila(query);
      if (mounted) setState(() => _searchResults = results);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _createAndSelect() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 0. Vérification anti-doublon (UX Improvement)
    final nameToCheck = _nameController.text.trim();
    setState(() => _isCreating = true);
    
    try {
      // Recherche rapide de similitude
      final existing = await _silsilaService.searchSilsila(nameToCheck);
      final potentialDuplicate = existing.firstWhere(
        (e) => e.name.toLowerCase() == nameToCheck.toLowerCase() || e.isGlobal, 
        orElse: () => Silsila(id: '', name: '', level:0, isGlobal: false, createdAt: DateTime.now())
      );

      if (potentialDuplicate.id.isNotEmpty && mounted) {
        // Doublon potentiel détecté !
        setState(() => _isCreating = false);
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Doublon possible ⚠️"),
            content: Text(
              "Il existe déjà un '${potentialDuplicate.name}' dans la base globale.\n\n"
              "Voulez-vous vraiment créer un NOUVEAU nœud local avec le même nom, ou annuler pour vous relier à l'existant ?"
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false), // Annuler
                child: const Text("Annuler (Utiliser l'existant)"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true), // Forcer création
                child: const Text("Créer quand même"),
              ),
            ],
          ),
        );
        
        if (confirm != true) return; // L'utilisateur a annulé
        setState(() => _isCreating = true); // On repart
      }

      // 1. Créer le noeud avec ou sans parent
      final nodeId = await _silsilaService.createNode(
        name: nameToCheck,
        parentId: _selectedParent?.id, 
        isGlobal: false, 
      );
      
      // 2. Construire un objet Silsila temporaire pour le retour
      final newNode = Silsila(
        id: nodeId,
        name: nameToCheck,
        level: 1, 
        createdAt: DateTime.now(),
        isGlobal: false
      );
      
      widget.onSelect?.call(newNode);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "🔍 Rechercher"),
              Tab(text: "➕ Créer Nouveau"),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorSize: TabBarIndicatorSize.label,
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: SEARCH
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: "Nom du Cheikh / Muqaddam...",
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                        ),
                        onChanged: (val) {
                          if (val.length > 2) _performSearch(val);
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_isSearching)
                        const LinearProgressIndicator()
                      else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("Aucun résultat. Essayez l'onglet 'Créer Nouveau'."),
                        ),
                        
                      Expanded(
                        child: ListView.separated(
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final node = _searchResults[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                backgroundImage: node.imageUrl != null ? NetworkImage(node.imageUrl!) : null,
                                child: node.imageUrl == null ? Text(node.name[0]) : null,
                              ),
                              title: Text(node.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: node.isGlobal 
                                  ? Row(children: [
                                      Icon(Icons.verified, size: 14, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 4),
                                      const Text("Cheikh Reconnu"),
                                    ])
                                  : null,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                widget.onSelect?.call(node);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // TAB 2: CREATE NEW (Step by Step)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.person_add_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          "Ajouter un Muqaddam Local",
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Créez la fiche de votre Muqaddam et reliez-le à son maître.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        
                        // 1. Nom du Muqaddam
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Nom du Muqaddam",
                            hintText: "Ex: Imam Moussa...",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => (v == null || v.length < 3) ? "Nom trop court" : null,
                        ),
                        const SizedBox(height: 16),

                        // 2. Sélection du Parent (OPTIONNEL)
                        Text("De qui tient-il le Wird ? (Optionnel)", style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 8),
                        
                        // Zone de recherche simplifiée pour le parent
                        if (_selectedParent == null) ...[
                          TextField(
                            decoration: InputDecoration(
                              hintText: "Rechercher son Maître (Laisser vide si inconnu)...",
                              prefixIcon: const Icon(Icons.search),
                              fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              suffixIcon: _isSearchingParent 
                                  ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)) 
                                  : null,
                            ),
                            onChanged: (val) {
                              if (val.length > 2) _performParentSearch(val);
                            },
                          ),
                          if (_parentSearchResults.isNotEmpty)
                            Container(
                              height: 150,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                itemCount: _parentSearchResults.length,
                                itemBuilder: (context, index) {
                                  final node = _parentSearchResults[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text(node.name),
                                    leading: const Icon(Icons.person_outline, size: 20),
                                    onTap: () => setState(() {
                                      _selectedParent = node;
                                      _parentSearchResults = [];
                                    }),
                                  );
                                },
                              ),
                            ),
                        ] else ...[
                          // Parent sélectionné
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).colorScheme.primary),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link, color: Colors.green),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Connecté à :", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(_selectedParent!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () => setState(() => _selectedParent = null),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isCreating ? null : _createAndSelect,
                            icon: _isCreating 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check),
                            label: Text(_selectedParent == null ? "Créer sans Maître (pour l'instant)" : "Valider et Lier"),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
