import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import '../../../../services/silsila_service.dart';
import '../../../../models/silsila_node.dart';
import '../screens/admin_scaffold.dart';
import '../widgets/admin_silsila_node_dialog.dart';

class AdminSilsilaListScreen extends StatefulWidget {
  const AdminSilsilaListScreen({super.key});

  @override
  State<AdminSilsilaListScreen> createState() => _AdminSilsilaListScreenState();
}

class _AdminSilsilaListScreenState extends State<AdminSilsilaListScreen> {
  final SilsilaService _service = SilsilaService();
  final TextEditingController _searchController = TextEditingController();
  
  List<SilsilaNode> _nodes = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalCount = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadNodes();
  }

  Future<void> _loadNodes() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.getNodesPaginated(
        page: _currentPage,
        limit: _limit,
        searchQuery: _searchController.text.trim(),
        isGlobal: true, // Focusing on Global/Historical nodes for this screen
      );
      setState(() {
        _nodes = result.nodes;
        _totalCount = result.count;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _openEditor(SilsilaNode? node) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AdminSilsilaNodeDialog(node: node),
    );
    
    if (result == true) {
      _loadNodes();
    }
  }

  void _deleteNode(SilsilaNode node) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text("Supprimer ${node.name} ?", style: const TextStyle(color: Colors.white)),
        content: const Text("Cette action est irréversible.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
       try {
        await _service.deleteNode(node.id);
        _loadNodes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: '/admin/silsila',
      title: 'Gestion de la Silsila (Chaîne)',
      actions: [
        ElevatedButton.icon(
          onPressed: () => _openEditor(null),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Ajouter un Maillon", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldPrimary),
        ),
      ],
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Rechercher un compagnon...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _currentPage = 1;
                    _loadNodes();
                  },
                ),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              onSubmitted: (val) {
                _currentPage = 1;
                _loadNodes();
              },
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _nodes.isEmpty
                    ? const Center(child: Text("Aucun maillon trouvé.", style: TextStyle(color: Colors.white)))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 350,
                          childAspectRatio: 3.5 / 1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _nodes.length,
                        itemBuilder: (context, index) {
                          final node = _nodes[index];
                          return Card(
                            color: const Color(0xFF1E1E1E),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.white.withOpacity(0.1))),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.tealPrimary.withOpacity(0.2),
                                    child: const Icon(Icons.link, color: AppColors.goldPrimary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(node.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                        if (node.parentIds.isNotEmpty)
                                           Text("Dans la chaîne", style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent), onPressed: () => _openEditor(node)),
                                  IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent), onPressed: () => _deleteNode(node)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Pagination Controls
          if (!_isLoading && _totalCount > _limit)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _currentPage > 1 ? () {
                      setState(() => _currentPage--);
                      _loadNodes();
                    } : null,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Page $_currentPage / ${(_totalCount / _limit).ceil()}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _currentPage < (_totalCount / _limit).ceil() ? () {
                      setState(() => _currentPage++);
                      _loadNodes();
                    } : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
