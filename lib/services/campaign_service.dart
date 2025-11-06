import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/campaign.dart';
import '../models/task.dart';
import 'supabase_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// SERVICE DE GESTION DES CAMPAGNES
/// ════════════════════════════════════════════════════════════════════════════
///
/// Ce service gère toutes les opérations liées aux campagnes :
/// - Création de campagnes avec tâches multiples
/// - Récupération des campagnes publiques
/// - Récupération des campagnes de l'utilisateur (créées/souscrites)
/// - Souscription aux campagnes
///
/// ARCHITECTURE :
/// - Utilise le backend Node.js pour les opérations complexes
/// - Authentification via JWT Supabase (Bearer token)
/// - Toutes les routes nécessitent une authentification sauf les campagnes publiques
///
/// CONFIGURATION :
/// - API_BASE_URL doit être défini dans .env
/// - Pour téléphone physique : http://192.168.1.X:3000/api
/// - Pour émulateur Android : http://10.0.2.2:3000/api
/// - Pour production : https://your-backend.com/api
/// ════════════════════════════════════════════════════════════════════════════

class CampaignService {
  final SupabaseClient _supabase = SupabaseService.client;

  /// URL de base du backend récupérée depuis .env
  /// CRITIQUE : Cette URL doit pointer vers votre backend Node.js
  final String? _baseUrl = dotenv.env['API_BASE_URL'];

  /// ══════════════════════════════════════════════════════════════════════════
  /// CRÉER UNE NOUVELLE CAMPAGNE AVEC SES TÂCHES
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Crée une campagne via le backend Node.js qui :
  /// 1. Valide les données (dates, nom, tâches)
  /// 2. Crée la campagne dans Supabase
  /// 3. Crée toutes les tâches associées atomiquement
  /// 4. Retourne l'ID de la campagne créée
  ///
  /// PARAMÈTRES :
  /// - name : Nom de la campagne (3-100 caractères)
  /// - description : Description optionnelle (max 500 caractères)
  /// - startDate : Date de début (ISO 8601)
  /// - endDate : Date de fin (doit être > startDate)
  /// - createdBy : UUID de l'utilisateur créateur (NON UTILISÉ - extrait du token)
  /// - category : Catégorie optionnelle (Istighfar, Salawat, etc.)
  /// - isPublic : Si true, visible par tous
  /// - accessCode : Code d'accès pour campagnes privées (si isPublic = false)
  /// - isWeekly : Si la campagne se répète chaque semaine
  /// - tasks : Liste des tâches avec name, total_number, daily_goal
  ///
  /// RETOURNE :
  /// - String : ID de la campagne créée (UUID)
  ///
  /// ERREURS :
  /// - Exception si API_BASE_URL non configurée
  /// - Exception si utilisateur non authentifié (pas de token)
  /// - Exception si validation échoue (400)
  /// - Exception si erreur serveur (500)
  /// ══════════════════════════════════════════════════════════════════════════
  Future<String> createCampaign({
    required String name,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
    String? category,
    bool isPublic = true,
    String? accessCode,
    bool isWeekly = false,
    required List<Map<String, dynamic>> tasks,
  }) async {
    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATION DE LA CONFIGURATION
    // ─────────────────────────────────────────────────────────────────────────
    if (_baseUrl == null) {
      throw Exception('API_BASE_URL non configurée dans .env\n'
          'Ajoutez : API_BASE_URL=http://192.168.1.X:3000/api');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // RÉCUPÉRATION DU TOKEN D'AUTHENTIFICATION
    // ─────────────────────────────────────────────────────────────────────────
    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PRÉPARATION DE LA REQUÊTE HTTP
    // ─────────────────────────────────────────────────────────────────────────
    final url = Uri.parse('$_baseUrl/campaigns');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // ─────────────────────────────────────────────────────────────────────────
    // FORMATAGE DES TÂCHES POUR LE BACKEND
    // ─────────────────────────────────────────────────────────────────────────
    // Le backend attend : { name, total_number, daily_goal }
    // Flutter envoie : { name, number, daily_goal }
    // Donc on doit renommer 'number' en 'total_number'
    final tasksPayload = tasks
        .map((task) => {
              'name': task['name'],
              'total_number': task['number'], // ✅ Backend attend 'total_number'
              'daily_goal': task['daily_goal'],
            })
        .toList();

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTION DU BODY DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    // IMPORTANT : Ne PAS envoyer 'created_by' dans le body !
    // Le backend l'extrait automatiquement depuis req.userId (du token JWT)
    final body = json.encode({
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'category': category,
      'is_public': isPublic,
      'access_code': accessCode,
      'tasks': tasksPayload,
    });

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE AU BACKEND
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.post(url, headers: headers, body: body);

      // ───────────────────────────────────────────────────────────────────────
      // GESTION DES RÉPONSES
      // ───────────────────────────────────────────────────────────────────────
      if (response.statusCode == 201) {
        // ✅ SUCCÈS - Campagne créée
        final responseData = json.decode(response.body);
        return responseData['data']['id'] as String;
      } else {
        // ❌ ERREUR - Récupérer le message d'erreur du backend
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      // ───────────────────────────────────────────────────────────────────────
      // GESTION DES ERREURS RÉSEAU
      // ───────────────────────────────────────────────────────────────────────
      throw Exception('Erreur lors de la création de la campagne: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// RÉCUPÉRER TOUTES LES CAMPAGNES PUBLIQUES
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Récupère la liste des campagnes via le backend avec filtrage et pagination.
  ///
  /// FILTRES DISPONIBLES :
  /// - category : Filtrer par catégorie (Istighfar, Salawat, etc.)
  /// - searchQuery : Recherche dans nom/description
  /// - page : Numéro de page (défaut: 1)
  /// - limit : Nombre de résultats par page (défaut: 20)
  ///
  /// RETOURNE :
  /// - List<Campaign> : Liste des campagnes avec leurs tâches
  ///
  /// NOTE : Cette route ne nécessite PAS d'authentification
  /// ══════════════════════════════════════════════════════════════════════════
  Future<List<Campaign>> getPublicCampaigns({
    String? category,
    String? searchQuery,
    int page = 1,
    int limit = 20,
  }) async {
    if (_baseUrl == null) {
      throw Exception('API_BASE_URL non configurée');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTION DE L'URL AVEC PARAMÈTRES DE REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (category != null && category.isNotEmpty) 'category': category,
      if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
    };

    final uri =
        Uri.parse('$_baseUrl/campaigns').replace(queryParameters: queryParams);

    // ─────────────────────────────────────────────────────────────────────────
    // HEADERS (optionnel : ajouter token si utilisateur connecté)
    // ─────────────────────────────────────────────────────────────────────────
    final token = _supabase.auth.currentSession?.accessToken;
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> campaignList = responseData['data'];
        return campaignList.map((json) => Campaign.fromJson(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des campagnes publiques: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// RÉCUPÉRER LES CAMPAGNES DE L'UTILISATEUR
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Récupère les campagnes créées par l'utilisateur OU auxquelles il est abonné.
  ///
  /// PARAMÈTRES :
  /// - userId : UUID de l'utilisateur
  /// - onlyCreated : Si true, retourne uniquement les campagnes créées par l'utilisateur
  ///                 Si false, retourne les campagnes souscrites
  ///
  /// QUERY PARAM BACKEND :
  /// - ?type=created   → Campagnes créées par moi
  /// - ?type=subscribed → Campagnes auxquelles je suis abonné
  /// - ?type=all       → Les deux (défaut)
  ///
  /// AUTHENTIFICATION : REQUISE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<List<Campaign>> getUserCampaigns({
    required String userId,
    bool onlyCreated = false,
  }) async {
    if (_baseUrl == null) {
      throw Exception('API_BASE_URL non configurée');
    }

    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTION DE L'URL AVEC TYPE DE CAMPAGNES
    // ─────────────────────────────────────────────────────────────────────────
    final queryParams = {
      'type': onlyCreated ? 'created' : 'subscribed',
    };

    final uri = Uri.parse('$_baseUrl/campaigns/my')
        .replace(queryParameters: queryParams);

    final headers = {
      'Authorization': 'Bearer $token',
    };

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> campaignList = responseData['data'];
        return campaignList.map((json) => Campaign.fromJson(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des campagnes de l\'utilisateur: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// RÉCUPÉRER UNE CAMPAGNE PAR SON ID
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Récupère les détails complets d'une campagne incluant :
  /// - Informations de la campagne
  /// - Liste des tâches associées
  /// - Informations du créateur
  ///
  /// PARAMÈTRES :
  /// - campaignId : UUID de la campagne
  ///
  /// RETOURNE :
  /// - Campaign? : L'objet Campaign ou null si non trouvé
  ///
  /// AUTHENTIFICATION : Optionnelle (obligatoire pour campagnes privées)
  /// ══════════════════════════════════════════════════════════════════════════
  Future<Campaign?> getCampaignById(String campaignId) async {
    if (_baseUrl == null) {
      throw Exception('API_BASE_URL non configurée');
    }

    final token = _supabase.auth.currentSession?.accessToken;
    final headers = {
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final uri = Uri.parse('$_baseUrl/campaigns/$campaignId');

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Campaign.fromJson(responseData['data']);
      } else if (response.statusCode == 404) {
        return null; // Campagne non trouvée
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la campagne: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// RÉCUPÉRER LES TÂCHES D'UNE CAMPAGNE
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Récupère uniquement les tâches d'une campagne (sans les détails de campagne).
  /// Utilise getCampaignById en interne.
  ///
  /// PARAMÈTRES :
  /// - campaignId : UUID de la campagne
  ///
  /// RETOURNE :
  /// - List<Task> : Liste des tâches de la campagne
  /// ══════════════════════════════════════════════════════════════════════════
  Future<List<Task>> getCampaignTasks(String campaignId) async {
    try {
      final campaign = await getCampaignById(campaignId);
      if (campaign == null) {
        throw Exception('Campagne non trouvée');
      }
      return campaign.tasks ?? [];
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des tâches de la campagne: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// S'ABONNER À UNE CAMPAGNE AVEC SÉLECTION DE TÂCHES
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Abonne l'utilisateur à une campagne en utilisant la fonction RPC atomique
  /// 'register_and_subscribe' qui garantit :
  /// - Pas de double souscription
  /// - Décrémentation atomique des quantités disponibles
  /// - Rollback complet en cas d'erreur
  ///
  /// FLUX :
  /// 1. Frontend envoie les tâches sélectionnées avec quantités
  /// 2. Backend appelle la RPC Supabase
  /// 3. RPC vérifie les quantités disponibles
  /// 4. RPC crée user_campaigns + user_tasks atomiquement
  /// 5. RPC décrémente tasks.remaining_number
  ///
  /// PARAMÈTRES :
  /// - campaignId : UUID de la campagne
  /// - accessCode : Code d'accès (obligatoire si campagne privée)
  /// - selectedTasks : Liste de maps avec { task_id, quantity }
  ///   Exemple : [
  ///     { "task_id": "uuid-1", "quantity": 10000 },
  ///     { "task_id": "uuid-2", "quantity": 5000 }
  ///   ]
  /// - userId : UUID utilisateur (non utilisé, extrait du token)
  ///
  /// ERREURS POSSIBLES :
  /// - 400 : Validation échouée (quantité > remainingNumber)
  /// - 401 : Non authentifié
  /// - 403 : Code d'accès invalide
  /// - 409 : Déjà abonné
  ///
  /// AUTHENTIFICATION : REQUISE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<void> subscribeToCampaign({
    required String campaignId,
    String? accessCode,
    required List<Map<String, dynamic>> selectedTasks,
    required String
        userId, // Paramètre gardé pour compatibilité mais non utilisé
  }) async {
    if (_baseUrl == null) {
      throw Exception('API_BASE_URL non configurée');
    }

    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTION DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    final url = Uri.parse('$_baseUrl/tasks/subscribe');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // ─────────────────────────────────────────────────────────────────────────
    // FORMAT ATTENDU PAR LE BACKEND
    // ─────────────────────────────────────────────────────────────────────────
    // Le backend Node.js attend :
    // {
    //   "campaign_id": "uuid",
    //   "access_code": "CODE123", // optionnel
    //   "task_subscriptions": [
    //     { "task_id": "uuid", "quantity": 10000 }
    //   ]
    // }
    final body = json.encode({
      'campaign_id': campaignId,
      'access_code': accessCode,
      'task_subscriptions': selectedTasks,
    });

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode != 201) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';

        // ───────────────────────────────────────────────────────────────────
        // GESTION DES ERREURS SPÉCIFIQUES
        // ───────────────────────────────────────────────────────────────────
        if (response.statusCode == 409) {
          throw Exception('Vous êtes déjà abonné à cette campagne');
        } else if (response.statusCode == 403) {
          throw Exception('Code d\'accès invalide');
        } else if (response.statusCode == 400) {
          throw Exception('Quantité demandée non disponible');
        } else {
          throw Exception('Erreur ${response.statusCode}: $errorMessage');
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de la souscription à la campagne: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// VÉRIFIER SI L'UTILISATEUR EST ABONNÉ À UNE CAMPAGNE
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Vérifie si l'utilisateur est déjà abonné à une campagne donnée.
  /// Utile pour afficher/masquer le bouton "S'abonner".
  ///
  /// MÉTHODE : Récupère les campagnes souscrites et cherche l'ID
  ///
  /// PARAMÈTRES :
  /// - userId : UUID de l'utilisateur
  /// - campaignId : UUID de la campagne
  ///
  /// RETOURNE :
  /// - bool : true si abonné, false sinon
  /// ══════════════════════════════════════════════════════════════════════════
  Future<bool> isUserSubscribed({
    required String userId,
    required String campaignId,
  }) async {
    try {
      final subscribedCampaigns = await getUserCampaigns(
        userId: userId,
        onlyCreated: false,
      );
      return subscribedCampaigns.any((campaign) => campaign.id == campaignId);
    } catch (e) {
      // En cas d'erreur, considérer comme non abonné
      return false;
    }
  }
}
