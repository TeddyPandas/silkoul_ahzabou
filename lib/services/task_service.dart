import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_task.dart';
import 'supabase_service.dart';

/// ════════════════════════════════════════════════════════════════════════════
/// SERVICE DE GESTION DES TÂCHES UTILISATEUR
/// ════════════════════════════════════════════════════════════════════════════
///
/// Ce service gère toutes les opérations liées aux tâches personnelles :
/// - Récupération des tâches de l'utilisateur
/// - Mise à jour incrémentielle du progrès
/// - Marquage des tâches comme complètes
/// - Statistiques personnelles
/// - Désabonnement des campagnes
///
/// ARCHITECTURE :
/// - Utilise le backend Node.js pour toutes les opérations
/// - Authentification via JWT Supabase (Bearer token)
/// - Toutes les routes nécessitent une authentification
///
/// SYSTÈME DE PROGRESSION :
/// - Incrémentiel : L'utilisateur met à jour sa progression au fur et à mesure
/// - Marquage "complet" : Système d'honneur quand subscribed_quantity atteinte
/// - Statistiques : Calcul automatique du pourcentage global de progression
///
/// CONFIGURATION :
/// - API_BASE_URL doit être défini dans .env
/// - Pour téléphone physique : http://192.168.1.X:3000/api
/// ════════════════════════════════════════════════════════════════════════════

class TaskService {
  final SupabaseClient _supabase = SupabaseService.client;

  /// URL de base du backend récupérée depuis .env
  final String? _baseUrl = dotenv.env['API_BASE_URL'];

  /// ══════════════════════════════════════════════════════════════════════════
  /// RÉCUPÉRER LES TÂCHES D'UN UTILISATEUR POUR UNE CAMPAGNE SPÉCIFIQUE
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Récupère toutes les tâches auxquelles l'utilisateur est abonné pour une
  /// campagne donnée, avec informations de progression.
  ///
  /// PARAMÈTRES :
  /// - userId : UUID de l'utilisateur
  /// - campaignId : UUID de la campagne
  ///
  /// DONNÉES RETOURNÉES POUR CHAQUE TÂCHE :
  /// - id : UUID de la user_task
  /// - task_id : UUID de la tâche originale
  /// - task_name : Nom de la tâche
  /// - subscribed_quantity : Quantité à laquelle l'utilisateur s'est engagé
  /// - completed_quantity : Quantité déjà complétée
  /// - is_completed : Statut de complétion (bool)
  /// - progress_percentage : Pourcentage calculé (completed/subscribed * 100)
  /// - remaining_quantity : Quantité restante à faire
  ///
  /// QUERY PARAM BACKEND :
  /// - ?campaign_id=uuid → Filtre par campagne
  ///
  /// AUTHENTIFICATION : REQUISE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<List<UserTask>> getUserTasksForCampaign({
    required String userId,
    required String campaignId,
  }) async {
    if (_baseUrl == null) {
      throw Exception('API_BASE_URL non configurée dans .env');
    }

    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTION DE L'URL AVEC FILTRE PAR CAMPAGNE
    // ─────────────────────────────────────────────────────────────────────────
    final queryParams = {
      'campaign_id': campaignId,
    };

    final uri =
        Uri.parse('$_baseUrl/tasks').replace(queryParameters: queryParams);

    final headers = {
      'Authorization': 'Bearer $token',
    };

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────r
    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> userTaskList = responseData['data'];
        return userTaskList.map((json) => UserTask.fromJson(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des tâches de l\'utilisateur pour la campagne: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// RÉCUPÉRER TOUTES LES TÂCHES D'UN UTILISATEUR (TOUTES CAMPAGNES)
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Récupère toutes les tâches auxquelles l'utilisateur est abonné,
  /// avec option de filtrage par statut de complétion.
  ///
  /// PARAMÈTRES :
  /// - userId : UUID de l'utilisateur
  /// - onlyIncomplete : Si true, retourne uniquement les tâches non complètes
  ///
  /// QUERY PARAM BACKEND :
  /// - ?is_completed=false → Filtre les tâches non complètes
  /// - ?is_completed=true → Filtre les tâches complètes
  /// - (pas de param) → Toutes les tâches
  ///
  /// USAGE TYPIQUE :
  /// - Dashboard "Mes Tâches" : onlyIncomplete = true
  /// - Historique : onlyIncomplete = false
  ///
  /// AUTHENTIFICATION : REQUISE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<List<UserTask>> getAllUserTasks({
    required String userId,
    bool onlyIncomplete = false,
  }) async {
    if (_baseUrl == null) {
      throw Exception('API_BASE_URL non configurée');
    }

    final token = _supabase.auth.currentSession?.accessToken;
    if (token == null) {
      throw Exception('Utilisateur non authentifié');
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CONSTRUCTION DE L'URL AVEC FILTRES
    // ─────────────────────────────────────────────────────────────────────────
    final queryParams = {
      if (onlyIncomplete) 'is_completed': 'false',
    };

    final uri =
        Uri.parse('$_baseUrl/tasks').replace(queryParameters: queryParams);

    final headers = {
      'Authorization': 'Bearer $token',
    };

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    try {
      debugPrint('🔄 [TaskService] querying: $uri');
      final response = await http.get(uri, headers: headers);
      if (kDebugMode) {
        debugPrint('📥 [TaskService] response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> userTaskList = responseData['data'];
        return userTaskList.map((json) => UserTask.fromJson(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      debugPrint('❌ [TaskService] Error fetching user tasks: $e');
      throw Exception(
          'Erreur lors de la récupération des tâches de l\'utilisateur: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// METTRE À JOUR LA PROGRESSION D'UNE TÂCHE (INCRÉMENTIEL)
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Met à jour la quantité complétée pour une tâche donnée.
  /// La mise à jour est INCRÉMENTIELLE : on envoie la nouvelle quantité totale.
  ///
  /// EXEMPLE DE FLUX :
  /// 1. User s'abonne à une tâche avec quantity = 10000
  /// 2. Jour 1 : Complète 2000 → updateTaskProgress(userTaskId, 2000)
  /// 3. Jour 2 : Complète 3500 de plus → updateTaskProgress(userTaskId, 5500)
  /// 4. Jour 3 : Complète tout → updateTaskProgress(userTaskId, 10000)
  ///
  /// PARAMÈTRES :
  /// - userTaskId : UUID de la user_task (pas le task_id !)
  /// - completedQuantity : Nouvelle quantité complétée TOTALE (pas delta)
  ///
  /// VALIDATION BACKEND :
  /// - completedQuantity <= subscribed_quantity
  /// - completedQuantity >= 0
  ///
  /// MARQUAGE AUTO "COMPLET" :
  /// Si completedQuantity >= subscribed_quantity, le backend marque
  /// automatiquement is_completed = true
  ///
  /// AUTHENTIFICATION : REQUISE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<void> updateTaskProgress({
    required String userTaskId,
    required int completedQuantity,
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
    final url = Uri.parse('$_baseUrl/tasks/$userTaskId/progress');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = json.encode({
      'completed_quantity': completedQuantity,
    });

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';

        // Gestion d'erreurs spécifiques
        if (errorMessage.contains('dépasser')) {
          throw Exception('Quantité complétée dépasse la quantité souscrite');
        }

        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors de la mise à jour de la progression de la tâche: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// MARQUER UNE TÂCHE COMME COMPLÈTE (SYSTÈME D'HONNEUR)
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Marque une tâche comme complète en un seul appel, sans avoir à atteindre
  /// progressivement la quantité souscrite. C'est un système d'honneur.
  ///
  /// EFFET :
  /// - is_completed = true
  /// - completed_quantity = subscribed_quantity
  /// - completed_at = NOW()
  ///
  /// VALIDATION BACKEND :
  /// - La tâche ne doit pas déjà être complète
  ///
  /// USAGE TYPIQUE :
  /// - Bouton "Marquer comme terminé" dans l'UI
  /// - Cas où l'utilisateur a fait le zikr hors application
  ///
  /// PARAMÈTRES :
  /// - userTaskId : UUID de la user_task
  ///
  /// AUTHENTIFICATION : REQUISE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<void> markTaskAsCompleted({
    required String userTaskId,
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
    final url = Uri.parse('$_baseUrl/tasks/$userTaskId/complete');
    final headers = {
      'Authorization': 'Bearer $token',
    };

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE (PUT sans body)
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.put(url, headers: headers);

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';

        if (errorMessage.contains('déjà')) {
          throw Exception('Cette tâche est déjà marquée comme complète');
        }

        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception(
          'Erreur lors du marquage de la tâche comme complétée: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// DÉMARQUER UNE TÂCHE COMPLÉTÉE (ANNULER LE MARQUAGE)
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Annule le marquage "complet" d'une tâche en remettant completed_quantity à 0.
  /// Utile si l'utilisateur a marqué par erreur ou veut recommencer.
  ///
  /// MÉTHODE : Appelle updateTaskProgress avec completedQuantity = 0
  ///
  /// EFFET :
  /// - completed_quantity = 0
  /// - is_completed = false
  /// - completed_at = null
  ///
  /// PARAMÈTRES :
  /// - userTaskId : UUID de la user_task
  ///
  /// AUTHENTIFICATION : REQUISE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<void> unmarkTaskAsCompleted({
    required String userTaskId,
  }) async {
    try {
      await updateTaskProgress(userTaskId: userTaskId, completedQuantity: 0);
    } catch (e) {
      throw Exception('Erreur lors du démarquage de la tâche: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// RÉCUPÉRER LES STATISTIQUES DES TÂCHES DE L'UTILISATEUR
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Récupère des statistiques agrégées sur toutes les tâches de l'utilisateur.
  ///
  /// DONNÉES RETOURNÉES :
  /// {
  ///   "total_subscribed": 50000,      // Total de quantités souscrites
  ///   "total_completed": 35000,        // Total de quantités complétées
  ///   "completed_tasks": 3,            // Nombre de tâches complètes
  ///   "total_tasks": 5,                // Nombre total de tâches
  ///   "progress_percentage": 70.00     // Pourcentage global (2 décimales)
  /// }
  ///
  /// USAGE TYPIQUE :
  /// - Dashboard principal
  /// - Écran "Mon Progrès"
  /// - Affichage de statistiques globales
  ///
  /// PARAMÈTRES :
  /// - userId : UUID de l'utilisateur
  ///
  /// AUTHENTIFICATION : REQUISE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> getUserTaskStats({
    required String userId,
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
    final url = Uri.parse('$_baseUrl/tasks/stats');
    final headers = {
      'Authorization': 'Bearer $token',
    };

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Map<String, dynamic>.from(responseData['data']);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';
        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// RÉCUPÉRER LES TÂCHES QUOTIDIENNES D'AUJOURD'HUI
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Récupère les tâches que l'utilisateur devrait faire aujourd'hui.
  ///
  /// LOGIQUE :
  /// - Pour l'instant, retourne toutes les tâches non complètes
  /// - TODO : Implémenter la logique de tâches quotidiennes basée sur daily_goal
  ///
  /// PARAMÈTRES :
  /// - userId : UUID de l'utilisateur
  ///
  /// RETOURNE :
  /// - List<UserTask> : Tâches du jour
  ///
  /// USAGE TYPIQUE :
  /// - Dashboard "Mes Tâches du Jour"
  /// - Notifications quotidiennes
  ///
  /// AUTHENTIFICATION : REQUISE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<List<UserTask>> getTodayTasks({
    required String userId,
  }) async {
    try {
      // TODO: Implémenter la logique de tâches quotidiennes côté backend
      // Pour l'instant, retourner toutes les tâches non complètes
      final tasks = await getAllUserTasks(
        userId: userId,
        onlyIncomplete: true,
      );

      return tasks;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des tâches du jour: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// SE DÉSABONNER D'UNE CAMPAGNE (ANNULER TOUTES LES TÂCHES)
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Désabonne l'utilisateur d'une campagne complète, supprimant :
  /// - L'entrée user_campaigns
  /// - Toutes les entrées user_tasks associées
  /// - Remet les quantités non complétées dans tasks.remaining_number
  ///
  /// EFFET SUR LES TÂCHES GLOBALES :
  /// Pour chaque user_task de cette campagne :
  /// - remaining_quantity = subscribed_quantity - completed_quantity
  /// - tasks.remaining_number += remaining_quantity
  ///
  /// EXEMPLE :
  /// - User avait souscrit à 10000, complété 3000
  /// - Désabonnement : tasks.remaining_number += 7000
  ///
  /// PARAMÈTRES :
  /// - campaignId : UUID de la campagne
  /// - userId : UUID de l'utilisateur (extrait du token)
  ///
  /// VALIDATION BACKEND :
  /// - L'utilisateur doit être abonné à la campagne
  ///
  /// AUTHENTIFICATION : REQUISE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<void> unsubscribeFromCampaign({
    required String campaignId,
    required String userId, // Non utilisé, extrait du token
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
    final url = Uri.parse('$_baseUrl/tasks/unsubscribe/$campaignId');
    final headers = {
      'Authorization': 'Bearer $token',
    };

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE DELETE
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.delete(url, headers: headers);

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';

        if (response.statusCode == 404) {
          throw Exception('Vous n\'êtes pas abonné à cette campagne');
        }

        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Erreur lors du désabonnement de la campagne: $e');
    }
  }

  /// ══════════════════════════════════════════════════════════════════════════
  /// TERMINER UNE TÂCHE AVEC RETOUR DU RESTE AU POOL GLOBAL
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Permet à l'utilisateur de marquer sa tâche comme terminée en indiquant
  /// combien il a réellement accompli. La différence entre la quantité souscrite
  /// et la quantité réellement accomplie est automatiquement retournée au pool
  /// global (remaining_number de la tâche).
  ///
  /// EXEMPLE DE FLUX :
  /// 1. User s'abonne à 5 unités d'une tâche
  /// 2. User termine et indique avoir fait 2 unités
  /// 3. Les 3 unités restantes sont retournées au pool global
  /// 4. La user_task est marquée complète avec completed_quantity = 2
  ///
  /// PARAMÈTRES :
  /// - userTaskId : UUID de la user_task (pas le task_id !)
  /// - actualCompletedQuantity : Quantité réellement accomplie
  ///
  /// VALIDATION BACKEND :
  /// - actualCompletedQuantity <= subscribed_quantity
  /// - actualCompletedQuantity >= 0
  /// - La tâche ne doit pas déjà être complète
  ///
  /// RETOUR :
  /// - Map contenant user_task mis à jour et returned_to_pool (quantité retournée)
  ///
  /// AUTHENTIFICATION : REQUISE
  /// ══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> finishTask({
    required String userTaskId,
    required int actualCompletedQuantity,
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
    final url = Uri.parse('$_baseUrl/tasks/$userTaskId/finish');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = json.encode({
      'actual_completed_quantity': actualCompletedQuantity,
    });

    // ─────────────────────────────────────────────────────────────────────────
    // ENVOI DE LA REQUÊTE
    // ─────────────────────────────────────────────────────────────────────────
    try {
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Map<String, dynamic>.from(responseData['data']);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Une erreur est survenue';

        if (errorMessage.contains('déjà terminée')) {
          throw Exception('Cette tâche est déjà terminée');
        }
        if (errorMessage.contains('dépasser')) {
          throw Exception(
              'La quantité accomplie dépasse la quantité souscrite');
        }

        throw Exception('Erreur ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Erreur lors de la finalisation de la tâche: $e');
    }
  }
}
