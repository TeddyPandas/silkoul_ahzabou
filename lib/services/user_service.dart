import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// SERVICE DE GESTION DES UTILISATEURS ET PROFILS
/// ════════════════════════════════════════════════════════════════════════════
///
/// Ce service gère toutes les opérations liées aux utilisateurs :
/// - Mise à jour du profil utilisateur
/// - Récupération de la liste des utilisateurs (communauté)
/// - Recherche d'utilisateurs
///
/// ARCHITECTURE :
/// - Utilise le backend Node.js pour les opérations complexes
/// - Authentification via JWT Supabase (Bearer token)
/// - Les routes nécessitent généralement une authentification
///
/// DONNÉES DE PROFIL :
/// - display_name : Nom affiché
/// - avatar_url : URL de l'avatar
/// - phone : Numéro de téléphone
/// - address : Adresse
/// - date_of_birth : Date de naissance
/// - silsila_id : ID de la chaîne spirituelle
/// - points : Points accumulés
/// - level : Niveau de l'utilisateur
///
/// CONFIGURATION :
/// - API_BASE_URL doit être défini dans .env
/// - Pour téléphone physique : http://192.168.1.X:3000/api
/// ════════════════════════════════════════════════════════════════════════════

class UserService {
  final SupabaseClient _supabase = SupabaseService.client;

  /// URL de base du backend récupérée depuis .env
  final String? _baseUrl = dotenv.env['API_BASE_URL'];

  /// ══════════════════════════════════════════════════════════════════════════
  /// METTRE À JOUR LE PROFIL UTILISATEUR
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Met à jour les informations du profil de l'utilisateur dans la base de données.
  /// Seuls les champs fournis sont mis à jour (paramètres optionnels).
  ///
  /// PARAMÈTRES :
  /// - userId : UUID de l'utilisateur (NON UTILISÉ - extrait du token)
  /// - displayName : Nouveau nom à afficher (optionnel)
  /// - avatarUrl : Nouvelle URL d'avatar (optionnel)
  /// - phone : Nouveau numéro de téléphone (optionnel)
  /// - address : Nouvelle adresse (optionnel)
  /// - dateOfBirth : Nouvelle date de naissance (optionnel)
  ///
  /// CHAMPS NON MODIFIABLES VIA CETTE API :
  /// - id : UUID utilisateur (immuable)
  /// - email : Email (géré par Supabase Auth)
  /// - created_at : Date de création (immuable)
  /// - points : Géré automatiquement par le système
  /// - level : Calculé automatiquement depuis les points
  ///
  /// ENDPOINT BACKEND : PUT /api/users/:userId
  ///
  /// VALIDATION BACKEND :
  /// - L'utilisateur ne peut modifier que son propre profil
  /// - display_name : 2-100 caractères
  /// - phone : Format téléphone valide
  ///
  /// AUTHENTIFICATION : REQUISE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
  }) async {
    if (_baseUrl == null) {
      throw Exception('API_BASE_URL non configurée dans .env');
    }

    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTION DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    // Note : Bien que userId soit passé en paramètre, le backend utilise
    // req.userId extrait du token JWT pour plus de sécurité
    final url = Uri.parse('$_baseUrl/users/$userId');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTION DU BODY AVEC UNIQUEMENT LES CHAMPS FOURNIS
    // ─────────────────────────────────────────────────────────────────────────
    // On ne construit le body qu'avec les champs non-null pour éviter
    // d'écraser des valeurs existantes avec null
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (phone != null) updates['phone'] = phone;
    if (address != null) updates['address'] = address;
    if (dateOfBirth != null) {
      updates['date_of_birth'] = dateOfBirth.toIso8601String();
    }

    // Si aucun champ à mettre à jour, retourner directement
    if (updates.isEmpty) {
      return;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE PUT
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(updates),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';

        // ───────────────────────────────────────────────────────────────────
        // GESTION DES ERREURS SPÉCIFIQUES
        // ───────────────────────────────────────────────────────────────────
        if (response.statusCode == 403) {
          throw Exception('Vous ne pouvez modifier que votre propre profil');
        } else if (response.statusCode == 400) {
          throw Exception('Données invalides : $errorMessage');
        } else {
          throw Exception('Erreur ${response.statusCode}: $errorMessage');
        }
      }

      // ─────────────────────────────────────────────────────────────────────
      // SUCCÈS - Le profil a été mis à jour
      // ─────────────────────────────────────────────────────────────────────
      // Note : Pas besoin de retourner les données, le provider les récupérera
    } catch (e) {
      throw Exception(
          'Erreur lors de la mise à jour du profil utilisateur: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// RÉCUPÉRER LA LISTE DES UTILISATEURS (COMMUNAUTÉ)
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Récupère la liste de tous les utilisateurs de la plateforme pour afficher
  /// la communauté, les classements, etc.
  ///
  /// DONNÉES RETOURNÉES POUR CHAQUE UTILISATEUR :
  /// - id : UUID de l'utilisateur
  /// - display_name : Nom affiché
  /// - avatar_url : URL de l'avatar
  /// - email : Email (peut être masqué selon les permissions)
  /// - level : Niveau actuel
  /// - points : Points accumulés
  /// - created_at : Date d'inscription
  ///
  /// ENDPOINT BACKEND : GET /api/users
  ///
  /// PAGINATION :
  /// - Par défaut : 20 utilisateurs par page
  /// - Peut être étendu avec query params (page, limit)
  ///
  /// USAGE TYPIQUE :
  /// - Onglet "Communauté"
  /// - Classements (leaderboard)
  /// - Liste de disciples
  ///
  /// AUTHENTIFICATION : REQUISE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getUsers() async {
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
    final url = Uri.parse('$_baseUrl/users');
    final headers = {
      'Authorization': 'Bearer $token',
    };

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE GET
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Le backend retourne { status: "success", data: [...] }
        return List<Map<String, dynamic>>.from(responseData['data']);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// RECHERCHER DES UTILISATEURS PAR NOM OU EMAIL
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Recherche des utilisateurs par leur nom d'affichage ou email.
  /// Utile pour trouver des disciples, inviter à des campagnes privées, etc.
  ///
  /// PARAMÈTRES :
  /// - query : Terme de recherche (min 2 caractères recommandé)
  /// - limit : Nombre maximum de résultats (défaut: 20)
  ///
  /// RECHERCHE BACKEND :
  /// - Insensible à la casse
  /// - Recherche partielle (LIKE %query%)
  /// - Cherche dans display_name ET email
  ///
  /// ENDPOINT BACKEND : GET /api/users/search?query=...&limit=...
  ///
  /// EXEMPLE D'UTILISATION :
  /// ```dart
  /// final results = await userService.searchUsers(
  ///   query: 'ahmed',
  ///   limit: 10,
  /// );
  /// ```
  ///
  /// RETOURNE :
  /// - List<Map<String, dynamic>> : Utilisateurs correspondants
  ///
  /// AUTHENTIFICATION : OPTIONNELLE (publique)
  /// ══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    int limit = 20,
  }) async {
    if (_baseUrl == null) {
      throw Exception('API_BASE_URL non configurée');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // VALIDATION DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    if (query.trim().isEmpty) {
      return []; // Retourner liste vide si query vide
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTION DE L'URL AVEC PARAMÈTRES DE RECHERCHE
    // ─────────────────────────────────────────────────────────────────────────
    final queryParams = {
      'query': query.trim(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$_baseUrl/users/search')
        .replace(queryParameters: queryParams);

    // ─────────────────────────────────────────────────────────────────────────
    // HEADERS (optionnel : ajouter token si disponible)
    // ─────────────────────────────────────────────────────────────────────────
    final token = _supabase.auth.currentSession?.accessToken;
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(responseData['data']);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Erreur lors de la recherche d\'utilisateurs: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// RÉCUPÉRER LE PROFIL PUBLIC D'UN UTILISATEUR
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Récupère le profil public d'un utilisateur spécifique par son ID.
  ///
  /// DONNÉES PUBLIQUES RETOURNÉES :
  /// - id : UUID
  /// - display_name : Nom
  /// - avatar_url : Avatar
  /// - level : Niveau
  /// - points : Points (optionnel selon privacy settings)
  /// - created_at : Date d'inscription
  /// - silsila : Informations de la silsila (optionnel)
  ///
  /// DONNÉES PRIVÉES NON RETOURNÉES :
  /// - email (sauf si l'utilisateur lui-même)
  /// - phone
  /// - address
  /// - date_of_birth
  ///
  /// ENDPOINT BACKEND : GET /api/users/:userId
  ///
  /// PARAMÈTRES :
  /// - userId : UUID de l'utilisateur
  ///
  /// RETOURNE :
  /// - Map<String, dynamic> : Profil public
  ///
  /// AUTHENTIFICATION : OPTIONNELLE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> getUserProfile({
    required String userId,
  }) async {
    if (_baseUrl == null) {
      throw Exception('API_BASE_URL non configurée');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTION DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    final url = Uri.parse('$_baseUrl/users/$userId');

    final token = _supabase.auth.currentSession?.accessToken;
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Map<String, dynamic>.from(responseData['data']);
      } else if (response.statusCode == 404) {
        return null; // Utilisateur non trouvé
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// RÉCUPÉRER LA LISTE DES SILSILAS (CHAÎNES SPIRITUELLES)
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Récupère la liste de toutes les silsilas (chaînes d'initiation spirituelle)
  /// disponibles dans le système.
  ///
  /// STRUCTURE D'UNE SILSILA :
  /// - id : UUID
  /// - name : Nom de la silsila
  /// - parent_id : ID de la silsila parent (null si racine)
  /// - level : Niveau dans la hiérarchie (0 = racine)
  /// - description : Description optionnelle
  /// - created_at : Date de création
  ///
  /// ENDPOINT BACKEND : GET /api/users/silsilas
  ///
  /// USAGE TYPIQUE :
  /// - Sélection de silsila lors de l'inscription
  /// - Modification du profil
  /// - Affichage de la hiérarchie spirituelle
  ///
  /// RETOURNE :
  /// - List<Map<String, dynamic>> : Liste des silsilas ordonnées par level
  ///
  /// AUTHENTIFICATION : OPTIONNELLE (données publiques)
  /// ══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getSilsilas() async {
    if (_baseUrl == null) {
      throw Exception('API_BASE_URL non configurée');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTION DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    final url = Uri.parse('$_baseUrl/users/silsilas');

    final token = _supabase.auth.currentSession?.accessToken;
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return List<Map<String, dynamic>>.from(responseData['data']);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des silsilas: $e');
    }
  }
}
