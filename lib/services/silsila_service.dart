import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:silkoul_ahzabou/models/silsila.dart';
import 'package:silkoul_ahzabou/models/silsila_node.dart';

class SilsilaService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Récupère le graphique complet pour un nœud de départ (l'utilisateur)
  /// Retourne une liste de SilsilaNode prêts à être affichés
  /// Récupère le graphique complet pour un nœud de départ (l'utilisateur)
  /// Retourne une liste de SilsilaNode prêts à être affichés avec Niveaux Relatifs
  Future<List<SilsilaNode>> getSilsilaGraph(String startNodeId) async {
    // 1. Récupérer toutes les données brutes (Nodes & Relations)
    // Optimisation possible: Fetch recursif côté SQL, mais pour < 1000 items, tout charger est OK.
    final nodesResponse = await _client.from('silsilas').select();
    final allSilsilas = (nodesResponse as List).map((e) => Silsila.fromJson(e)).toList();
    
    final relationsResponse = await _client.from('silsila_relations').select();
    final allRelations = relationsResponse as List; 

    // 2. BFS pour construire le graphe ET calculer les niveaux relatifs
    // Map<NodeId, RelativeLevel>
    final Map<String, int> nodeLevels = {startNodeId: 0};
    final Set<String> visited = {startNodeId};
    final List<String> queue = [startNodeId];
    final List<SilsilaNode> resultNodes = [];

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      final currentLevel = nodeLevels[currentId]!;

      try {
        final silsila = allSilsilas.firstWhere((s) => s.id == currentId);
        
        // Trouver les parents (Niveau + 1)
        final parentIds = allRelations
            .where((r) => r['child_id'] == currentId)
            .map((r) => r['parent_id'] as String)
            .toList();

        // Trouver les enfants (Juste pour info structurelle)
        final childrenIds = allRelations
            .where((r) => r['parent_id'] == currentId)
            .map((r) => r['child_id'] as String)
            .toList();

        resultNodes.add(SilsilaNode(
          id: silsila.id,
          name: silsila.name,
          image: silsila.imageUrl,
          isGlobal: silsila.isGlobal,
          isUser: silsila.id == startNodeId,
          level: currentLevel, // UTILISE LE NIVEAU RELATIF CALCULÉ
          parentIds: parentIds,
          childrenIds: childrenIds,
        ));

        // Ajouter les parents à la file pour processing
        for (final pId in parentIds) {
          if (!visited.contains(pId)) {
            visited.add(pId);
            nodeLevels[pId] = currentLevel + 1; // Niveau du parent = Niveau courant + 1
            queue.add(pId);
          }
        }
      } catch (e) {
        debugPrint("Erreur lors du processing du noeud $currentId: $e");
      }
    }
    
    return resultNodes;
  }

  /// Recherche de Silsilas existantes
  Future<List<Silsila>> searchSilsila(String query) async {
    final res = await _client
        .from('silsilas')
        .select()
        .ilike('name', '%$query%') // Recherche insensible à la casse
        .limit(10);
    
    return (res as List).map((e) => Silsila.fromJson(e)).toList();
  }

  /// Initialise le réseau pour un utilisateur (Création de son noeud + lien parent)
  Future<void> initializeUserNetwork({
    required String userId,
    required String userName, // Nom affiché (Profile Name)
    required String parentId, // ID du Cheikh choisi
  }) async {
    // 1. Créer le nœud de l'utilisateur dans la table silsilas
    final userNodeRes = await _client.from('silsilas').insert({
      'name': userName,
      'level': 0, // Niveau de base pour l'utilisateur
      'is_global': false,
    }).select().single();
    
    final userNodeId = userNodeRes['id'] as String;

    // 2. Créer le lien avec le parent choisi
    await _client.from('silsila_relations').insert({
      'parent_id': parentId,
      'child_id': userNodeId,
    });

    // 3. Mettre à jour le profil utilisateur avec cet ID
    await _client.from('profiles').update({
      'silsila_id': userNodeId,
    }).eq('id', userId);
  }

  /// Crée un nouveau nœud (ex: Muqaddam local) ET le connecte à son maître (si fourni)
  /// Retourne l'ID du nouveau nœud
  Future<String> createNode({
    required String name,
    String? parentId, // Le maître du nouveau Muqaddam (OPTIONNEL)
    bool isGlobal = false,
  }) async {
    // 1. Créer le nœud
    final res = await _client.from('silsilas').insert({
      'name': name,
      'is_global': isGlobal,
      'level': 1, 
    }).select().single();
    
    final newNodeId = res['id'] as String;

    // 2. Créer le lien vers SON maître (si fourni)
    if (parentId != null) {
      await _client.from('silsila_relations').insert({
        'parent_id': parentId,
        'child_id': newNodeId,
      });
    }
    
    return newNodeId;
  }

  /// Delete a node (only if allowed by RLS, i.e., is_global=false)
  Future<void> deleteNode(String nodeId) async {
    // RLS policy will prevent deletion of global nodes automatically
    await _client.from('silsilas').delete().eq('id', nodeId);
  }
  
  /// ADMIN: Update a node (name, image, is_global)
  Future<void> updateNode(String nodeId, {String? name, String? imageUrl, bool? isGlobal}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (isGlobal != null) updates['is_global'] = isGlobal;

    if (updates.isEmpty) return; 

    await _client.from('silsilas').update(updates).eq('id', nodeId);
  }

  /// ADMIN: Fetch nodes with Pagination & Search
  /// Returns a tuple: (List<SilsilaNode>, int totalCount)
  Future<({List<SilsilaNode> nodes, int count})> getNodesPaginated({
    int page = 1,
    int limit = 20,
    String? searchQuery,
    bool? isGlobal,
  }) async {
    // 1. Build Query
    var query = _client.from('silsilas').select('*, silsila_relations!child_id(parent_id)');
    
    if (isGlobal != null) {
      query = query.eq('is_global', isGlobal);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    // 2. Get Total Count (separate lightweight query or use count option if Supabase supports exact count in one go easily)
    // For simplicity/performance, let's fetch count separately for now or rely on client-side if list is mapped. 
    // Supabase .count() is distinct.
    // 2. Get Total Count
    var countQuery = _client.from('silsilas').count(CountOption.exact);
    if (isGlobal != null) {
      countQuery = countQuery.eq('is_global', isGlobal);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      countQuery = countQuery.ilike('name', '%$searchQuery%');
    }
    
    final total = await countQuery;


    // 3. Get Data
    final from = (page - 1) * limit;
    final to = from + limit - 1;
    
    final response = await query
        .order('name', ascending: true)
        .range(from, to);

    final data = response as List;
    
    final nodes = data.map((json) {
       // Extract relations to find parent (single parent assumption for Silsila usually, but Relation is many-to-many structure)
       List<String> parentIds = [];
       if (json['silsila_relations'] != null) {
         parentIds = (json['silsila_relations'] as List)
             .map((r) => r['parent_id'] as String)
             .toList();
       }

       return SilsilaNode(
        id: json['id'],
        name: json['name'],
        image: json['image_url'],
        isGlobal: json['is_global'] ?? false,
        parentIds: parentIds,
      );
    }).toList();

    return (nodes: nodes, count: total);
  }

  /// Insère un nouveau nœud entre un enfant et son parent actuel
  /// (Ex: "A -> C" devient "A -> B -> C")
  Future<void> insertNodeBetween({
    required String childId,
    required String parentId, // Le parent actuel (C)
    required String newName, // Le nom du nouveau nœud (B)
  }) async {
    // 1. Créer le nouveau nœud intermédiaire (B)
    final newNodeId = await createNode(name: newName, parentId: parentId); // B -> C créé ici

    // 2. Lier le nouveau nœud à l'enfant (A -> B)
    // Note: addConnection est directionnel: child -> parent
    await addConnection(childId: childId, parentId: newNodeId); 

    // 3. Supprimer l'ancienne liaison directe (A -> C)
    await _client.from('silsila_relations')
        .delete()
        .match({
          'child_id': childId, 
          'parent_id': parentId
        });
  }

  /// Ajoute une connexion pour l'utilisateur courant vers un nœud existant
  Future<void> addConnection({
    required String childId,
    required String parentId,
  }) async {
    await _client.from('silsila_relations').insert({
      'parent_id': parentId,
      'child_id': childId,
    });
  }

  /// Removes the link between a child and a specific parent
  Future<void> unlinkParent({required String childId, required String parentId}) async {
     await _client.from('silsila_relations').delete().match({
       'child_id': childId,
       'parent_id': parentId,
     });
  }
  
  /// Simple search for dropdowns
  Future<List<SilsilaNode>> searchNodes(String query) async {
    final res = await _client
        .from('silsilas')
        .select()
        .ilike('name', '%$query%')
        .limit(20);
        
    return (res as List).map((e) => SilsilaNode(
      id: e['id'], 
      name: e['name'],
      isGlobal: e['is_global'] ?? false,
    )).toList();
  }
}
