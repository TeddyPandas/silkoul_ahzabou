import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:silkoul_ahzabou/models/silsila_node.dart';
import 'package:silkoul_ahzabou/providers/auth_provider.dart';
import 'package:silkoul_ahzabou/services/silsila_service.dart';
import 'package:silkoul_ahzabou/widgets/silsila_tree_viewer.dart';
import 'package:silkoul_ahzabou/screens/silsila/widgets/add_silsila_sheet.dart';
import 'package:silkoul_ahzabou/modules/teachings/screens/article_reader_screen.dart';
import 'package:silkoul_ahzabou/modules/teachings/models/article.dart';
import 'package:silkoul_ahzabou/modules/teachings/models/author.dart';
import 'package:silkoul_ahzabou/modules/teachings/models/category.dart';
import 'package:silkoul_ahzabou/content/pole_biography.dart';

class SilsilaScreen extends StatefulWidget {
  const SilsilaScreen({super.key});

  @override
  State<SilsilaScreen> createState() => _SilsilaScreenState();
}

class _SilsilaScreenState extends State<SilsilaScreen> {
  final SilsilaService _silsilaService = SilsilaService();
  late Future<List<SilsilaNode>> _graphFuture;

  @override
  void initState() {
    super.initState();
    _loadGraph();
  }

  void _loadGraph() {
    final userProfile = Provider.of<AuthProvider>(context, listen: false).profile;
    if (userProfile?.silsilaId != null) {
      _graphFuture = _silsilaService.getSilsilaGraph(userProfile!.silsilaId!);
    } else {
      // Pas de silsila configurée, future immédiat vide
      _graphFuture = Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si l'utilisateur n'est pas connecté ou pas de profil chargé
    // (Géré en amont normalement, mais sécurité)
    final profile = context.watch<AuthProvider>().profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Silsila'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Exporter l'image de la Silsila
            },
          ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<SilsilaNode>>(
              future: _graphFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erreur: ${snapshot.error}'),
                  );
                }

                final nodes = snapshot.data ?? [];

                // Cas 1: Pas de Silsila du tout -> Écran de création initial
                if (nodes.isEmpty) {
                  return _buildEmptyState(context);
                }

                // Cas 2: Affichage du graphe
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Votre chaîne spirituelle remonte jusqu\'au Pôle Caché.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: SilsilaTreeViewer(
                          nodes: nodes,
                          onNodeTap: (node) => _showNodeDetails(context, node, nodes),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: profile != null && profile.silsilaId != null ? FloatingActionButton.extended(
        onPressed: () => _showAddSilsilaSheet(context, isRoot: false),
        icon: const Icon(Icons.add_link),
        label: const Text('Ajouter une connexion'),
      ) : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_tree_outlined, size: 80, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            'Aucune Silsila configurée',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text('Commencez par définir votre Muqaddam.'),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddSilsilaSheet(context, isRoot: true),
            icon: const Icon(Icons.add),
            label: const Text('Créer ma Chaîne'),
          ),
        ],
      ),
    );
  }

  void _showAddSilsilaSheet(BuildContext context, {required bool isRoot}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Pour prendre plus de place
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddSilsilaSheet(
        onSelect: (selectedSilsila) async {
          final profile = context.read<AuthProvider>().profile!;
          
          if (isRoot) {
            // Initialisation (User -> Selected)
            await _silsilaService.initializeUserNetwork(
              userId: profile.id,
              userName: profile.displayName,
              parentId: selectedSilsila.id,
            );
            
            // Recharger le profil pour avoir le silsilaId
            if (context.mounted) {
              await context.read<AuthProvider>().updateProfile(); // Force refresh
            }
          } else {
            // Ajout (Selected -> User Node)
            if (profile.silsilaId != null) {
              await _silsilaService.addConnection(
                childId: profile.silsilaId!,
                parentId: selectedSilsila.id,
              );
            }
          }
          
          setState(() {
            _loadGraph(); // Rafraîchir le graphe
          });
        },
      ),
    );
  }

  void _showNodeDetails(BuildContext context, SilsilaNode node, List<SilsilaNode> allNodes) {
    // Trouver les objets parents complets pour afficher leurs noms
    final parents = allNodes.where((n) => node.parentIds.contains(n.id)).toList();
    final isCheikhRoot = node.name.contains('Cheikh Ahmad At-Tidiani') || node.name.contains('Prophet');

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              backgroundImage: node.image != null ? NetworkImage(node.image!) : null,
              child: node.image == null 
                ? Text(node.name.isNotEmpty ? node.name[0] : '?', style: const TextStyle(fontSize: 24)) 
                : null,
            ),
            const SizedBox(height: 16),
            Text(
              node.name,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            
            
            // 🌟 BIOGRAPHIE DU PÔLE (Si Cheikh Ahmad At-Tidiani)
            if (isCheikhRoot) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      "Seïdina Ahmed Tijani (qu’Allah sanctifie son précieux secret) est né en 1150 de l’Hégire (1737/38) à ‘Aïn Madhi. Issu d'une lignée de savants et de saints, il est le Fondateur de la Tariqa Tidjaniya et le Sceau des Saints (Khatm al-Awliya).",
                      textAlign: TextAlign.justify,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        // Construire l'article statique
                        final article = Article(
                          id: 'biography_ahmed_tijani',
                          titleFr: poleBiographyTitle,
                          titleAr: "حياة الشيخ أحمد التجاني رضي الله عنه",
                          contentFr: poleBiographyContent,
                          contentAr: "", // Optionnel
                          publishedAt: DateTime(1737),
                          author: Author(id: 'tidjaniya', name: 'Tidjaniya.com', bio: 'Source Officielle'),
                          category: Category(id: 'biography', nameFr: 'Biographie', nameAr: 'سيرة ذاتية', slug: 'biography'),
                          readTimeMinutes: 20,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArticleReaderScreen(
                              article: article,
                              heroTag: 'pole_star', // Trigger Hero animation
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.brown,
                        side: const BorderSide(color: Colors.brown),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(Icons.menu_book_rounded, size: 16),
                      label: const Text("Lire la biographie complète"),
                    ),
                  ],
                ),
              ),
            ],

            // Parents / Connexions vers le haut
            if (parents.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const Align(alignment: Alignment.centerLeft, child: Text("Tient le Wird de :", style: TextStyle(color: Colors.grey))),
              ...parents.map((parent) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.arrow_upward, size: 16),
                title: Text(parent.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.add_link, color: Colors.orange), // Icone d'insertion
                  tooltip: "Insérer un intermédiaire",
                  onPressed: () {
                     // Action d'insertion
                     Navigator.pop(ctx);
                     _showInsertDialog(context, node, parent.id, parent.name);
                  },
                ),
              )),
            ],

            const SizedBox(height: 16),
            if (node.isGlobal) ...[
                const Chip(
                  label: Text('Cheikh Reconnu'),
                  avatar: Icon(Icons.verified, size: 16),
                ),
            ],

            // Option: Ajouter un maître (si orphelin ET pas le grand Cheikh)
            if (node.parentIds.isEmpty && !isCheikhRoot && node.level < 1000) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                "Ce nœud n'a pas de connexion connue vers le haut.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Fermer details
                  _showParentPicker(context, node);
                },
                icon: const Icon(Icons.link),
                label: const Text('Ajouter son Maître (Étendre la chaîne)'),
              ),
            ],
            
            // Delete Action (Only for local nodes)
            if (!node.isGlobal) ...[

              const SizedBox(height: 24),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.delete_outline),
                label: const Text("Supprimer ce nœud"),
                onPressed: () => _confirmDelete(context, node),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, SilsilaNode node) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: Text("Voulez-vous vraiment supprimer '${node.name}' ?\nCette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) Navigator.pop(context); 
      try {
        await _silsilaService.deleteNode(node.id);
        if (mounted) {
          final profile = context.read<AuthProvider>().profile;
           if (node.id == profile?.silsilaId) {
             // Reload
           }
          setState(() => _loadGraph());
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nœud supprimé.')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _showParentPicker(BuildContext context, SilsilaNode childNode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddSilsilaSheet(
        onSelect: (selectedParent) async {
          try {
            await _silsilaService.addConnection(childId: childNode.id, parentId: selectedParent.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connexion ajoutée !')));
              setState(() => _loadGraph());
            }
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
          }
        },
      ),
    );
  }

  // --- Insertion Logic ---

  Future<void> _showInsertDialog(BuildContext context, SilsilaNode childNode, String parentId, String parentName) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Insérer un intermédiaire"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Vous allez insérer une personne entre :\n'${childNode.name}'\net\n'$parentName'",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: "Nom de l'intermédiaire",
                  hintText: "Ex: Mon Père...",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.length < 3) ? "Nom trop court" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx); 
                try {
                  await _silsilaService.insertNodeBetween(
                    childId: childNode.id,
                    parentId: parentId,
                    newName: controller.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(context); // Close details
                    setState(() => _loadGraph());
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Intermédiaire inséré avec succès !')));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur insertion: $e')));
                }
              }
            },
            child: const Text("Insérer"),
          ),
        ],
      ),
    );
  }
}
