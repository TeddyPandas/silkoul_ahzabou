// lib/providers/campaign_provider.dart
import 'package:flutter/foundation.dart';
import '../models/campaign.dart';
import '../models/campaign_subscriber.dart';
import '../services/campaign_service.dart';
import '../services/notification_service.dart';

class CampaignProvider with ChangeNotifier {
  final CampaignService _campaignService = CampaignService();

  List<Campaign> _campaigns = [];
  List<Campaign> _myCampaigns = [];
  Campaign? _selectedCampaign;
  final Set<String> _readCampaignIds = {};
  List<CampaignSubscriber> _subscribers = [];
  bool _hasMoreSubscribers = true;
  bool _isLoadingSubscribers = false;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Campaign> get campaigns => _campaigns;
  List<Campaign> get myCampaigns => _myCampaigns;
  Campaign? get selectedCampaign => _selectedCampaign;
  List<CampaignSubscriber> get subscribers => _subscribers;
  bool get hasMoreSubscribers => _hasMoreSubscribers;
  bool get isLoadingSubscribers => _isLoadingSubscribers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Campaigns ending in less than 24 hours
  List<Campaign> get endingSoonCampaigns {
    final now = DateTime.now();
    return _myCampaigns.where((c) {
      if (c.isFinished) return false;
      final timeDifference = c.endDate.difference(now);
      return timeDifference.inHours <= 24 && timeDifference.inSeconds > 0;
    }).toList();
  }

  // Check if there are any unread ending soon campaigns
  bool get hasUnreadNotifications {
    return endingSoonCampaigns.any((c) => !_readCampaignIds.contains(c.id));
  }

  // Check if a specific campaign notification is read
  bool isCampaignRead(String campaignId) {
    return _readCampaignIds.contains(campaignId);
  }

  // Mark a campaign notification as read
  void markCampaignAsRead(String campaignId) {
    if (!_readCampaignIds.contains(campaignId)) {
      _readCampaignIds.add(campaignId);
      notifyListeners();
    }
  }

  // ============================================
  // RÉCUPÉRER TOUTES LES CAMPAGNES PUBLIQUES
  // ============================================
  Future<void> fetchCampaigns({String? category, String? searchQuery}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint('🔄 [CampaignProvider] Fetching public campaigns...');
      _campaigns = await _campaignService.getPublicCampaigns(
        category: category,
        searchQuery: searchQuery,
      );
      debugPrint(
          '✅ [CampaignProvider] Fetched ${_campaigns.length} public campaigns');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [CampaignProvider] Error fetching campaigns: $e');
      _errorMessage = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // RÉCUPÉRER MES CAMPAGNES (créées + souscrites)
  // ============================================
  Future<void> fetchMyCampaigns({
    required String userId,
    bool onlyCreated = false,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      debugPrint(
          '🔄 [CampaignProvider] Fetching my campaigns for userId: $userId (onlyCreated: $onlyCreated)...');
      _myCampaigns = await _campaignService.getUserCampaigns(
        userId: userId,
        onlyCreated: onlyCreated,
      );

      // Schedule notifications for ongoing campaigns
      for (var campaign in _myCampaigns) {
        if (!campaign.isFinished && campaign.isActive) {
          NotificationService().scheduleCampaignEndNotification(campaign);
        }
      }
      debugPrint(
          '✅ [CampaignProvider] Fetched ${_myCampaigns.length} user campaigns');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ [CampaignProvider] Error fetching my campaigns: $e');
      _errorMessage = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // RÉCUPÉRER UNE CAMPAGNE PAR ID
  // ============================================
  Future<void> fetchCampaignById(String campaignId,
      {String? accessCode}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _selectedCampaign = await _campaignService.getCampaignById(campaignId,
          accessCode: accessCode);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // RÉCUPÉRER UNE CAMPAGNE PAR ID (RETOURNE LA CAMPAGNE)
  // ============================================
  /// Récupère une campagne par son ID et la retourne
  /// Contrairement à fetchCampaignById, cette méthode retourne la campagne
  /// au lieu de la stocker dans _selectedCampaign
  Future<Campaign?> getCampaignById(String campaignId,
      {String? accessCode}) async {
    _errorMessage = null;
    // Notify listeners implies rebuild, maybe we don't want to flash?
    // But we should clear the state.

    try {
      return await _campaignService.getCampaignById(campaignId,
          accessCode: accessCode);
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      notifyListeners();
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VÉRIFIER SI L'UTILISATEUR EST ABONNÉ (VERSION OPTIMISÉE)
  // ══════════════════════════════════════════════════════════════════════════
  ///
  /// Utilise le nouvel endpoint backend dédié pour une vérification rapide
  /// sans charger toutes les campagnes souscrites.
  ///
  /// PERFORMANCES :
  /// - Avant : 1 requête GET qui charge toutes les campagnes + parsing
  /// - Après : 1 requête GET légère qui retourne juste un boolean
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
      // ✅ Utiliser la nouvelle méthode optimisée
      return await _campaignService.isUserSubscribedOptimized(
        userId: userId,
        campaignId: campaignId,
      );
    } catch (e) {
      // En cas d'erreur, considérer comme non abonné
      debugPrint('Erreur lors de la vérification de souscription: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RÉCUPÉRER LES TÂCHES DÉJÀ SOUSCRITES POUR UNE CAMPAGNE
  // ══════════════════════════════════════════════════════════════════════════
  /// Récupère la liste des tâches auxquelles l'utilisateur est déjà abonné
  /// pour une campagne donnée. Utilisé pour désactiver ces tâches dans le
  /// dialog de souscription.
  ///
  /// RETOURNE :
  /// - List<Map<String, dynamic>> avec task_id, subscribed_quantity, etc.
  /// ══════════════════════════════════════════════════════════════════════════
  Future<List<Map<String, dynamic>>> getUserTaskSubscriptions(
      String campaignId) async {
    try {
      return await _campaignService.getUserTaskSubscriptions(campaignId);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des tâches souscrites: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // RÉCUPÉRER LES ABONNÉS (POUR LE CRÉATEUR)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> fetchSubscribers(String campaignId, {int page = 0, String? searchQuery, bool refresh = false}) async {
    debugPrint('📥 [Provider] fetchSubscribers called - campaign: $campaignId, page: $page, refresh: $refresh');
    
    if (_isLoadingSubscribers) {
      debugPrint('⏳ [Provider] Already loading, skipping...');
      return;
    }

    try {
      _isLoadingSubscribers = true;
      if (refresh) {
        _subscribers = [];
        _hasMoreSubscribers = true;
        // Use Future.microtask to defer notifyListeners to avoid calling it during build
        Future.microtask(() => notifyListeners());
      }

      if (!_hasMoreSubscribers && !refresh) {
        _isLoadingSubscribers = false;
        Future.microtask(() => notifyListeners());
        return;
      }

      final newSubscribers = await _campaignService.getCampaignSubscribers(
        campaignId, 
        page: page, 
        searchQuery: searchQuery
      );

      if (refresh) {
        _subscribers = newSubscribers;
      } else {
        _subscribers.addAll(newSubscribers);
      }

      // Assume if we got less than requested limit (default 20), we reached the end
      if (newSubscribers.length < 20) {
        _hasMoreSubscribers = false;
      }
      
      _isLoadingSubscribers = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Provider: Erreur fetchSubscribers: $e');
      _isLoadingSubscribers = false;
      notifyListeners();
    }
  }

  // ============================================
  // AJOUTER DES TÂCHES À UN ABONNEMENT EXISTANT
  // ============================================
  Future<bool> addTasksToSubscription({
    required String campaignId,
    required List<Map<String, dynamic>> selectedTasks,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Vérifier si la campagne est terminée
      final campaign = await getCampaignById(campaignId);
      if (campaign != null && campaign.isFinished) {
        _errorMessage = "Cette campagne est terminée. Vous ne pouvez plus y participer.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _campaignService.addTasksToSubscription(
        campaignId: campaignId,
        selectedTasks: selectedTasks,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // ✅ S'ABONNER À UNE CAMPAGNE (CORRIGÉ)
  // ============================================
  Future<bool> subscribeToCampaign({
    required String userId,
    required String campaignId,
    String? accessCode,
    required List<Map<String, dynamic>> selectedTasks, // ✅ Un seul paramètre
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Vérifier si la campagne est terminée
      final campaign = await getCampaignById(campaignId);
      if (campaign != null && campaign.isFinished) {
        _errorMessage = "Cette campagne est terminée. Vous ne pouvez plus vous inscrire.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // ✅ CORRECTION : Plus de paramètre dupliqué
      await _campaignService.subscribeToCampaign(
        userId: userId,
        campaignId: campaignId,
        accessCode: accessCode,
        selectedTasks: selectedTasks, // ✅ Un seul paramètre utilisé
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // ✅ AMÉLIORATION : Parser l'erreur pour un message plus clair
      _errorMessage = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CRÉER UNE CAMPAGNE (AVEC VALIDATIONS FRONTEND)
  // ══════════════════════════════════════════════════════════════════════════
  Future<String?> createCampaign({
    required String name,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    required String createdBy,
    String? category,
    required bool isPublic,
    String? accessCode,
    bool isWeekly = false,
    required List<Map<String, dynamic>> tasks,
  }) async {
    // ═══════════════════════════════════════════════════════════════════════
    // VALIDATIONS FRONTEND (avant d'appeler le backend)
    // ═══════════════════════════════════════════════════════════════════════

    // ✅ Validation 1: Vérifier que createdBy n'est pas vide
    if (createdBy.isEmpty) {
      _errorMessage = 'Utilisateur non identifié. Veuillez vous reconnecter.';
      notifyListeners();
      return null;
    }

    // ✅ Validation 2: Vérifier que le nom n'est pas vide
    if (name.trim().isEmpty) {
      _errorMessage = 'Le nom de la campagne est requis.';
      notifyListeners();
      return null;
    }

    // ✅ Validation 3: Vérifier les dates
    if (endDate.isBefore(startDate)) {
      _errorMessage = 'La date de fin doit être après la date de début.';
      notifyListeners();
      return null;
    }

    // ✅ Validation 4: Vérifier qu'il y a au moins une tâche
    if (tasks.isEmpty) {
      _errorMessage = 'Vous devez ajouter au moins une tâche.';
      notifyListeners();
      return null;
    }

    // ✅ Validation 5: Vérifier que toutes les tâches ont un nombre > 0
    for (var task in tasks) {
      if (task['number'] == null || task['number'] <= 0) {
        _errorMessage =
            'Toutes les tâches doivent avoir un nombre supérieur à 0.';
        notifyListeners();
        return null;
      }
    }

    // ✅ Validation 6: Code d'accès pour campagnes privées
    if (!isPublic && (accessCode == null || accessCode.trim().isEmpty)) {
      _errorMessage = 'Un code d\'accès est requis pour les campagnes privées.';
      notifyListeners();
      return null;
    }

    // ═══════════════════════════════════════════════════════════════════════
    // APPEL AU SERVICE (si toutes les validations passent)
    // ═══════════════════════════════════════════════════════════════════════

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final campaignId = await _campaignService.createCampaign(
        name: name,
        description: description,
        startDate: startDate,
        endDate: endDate,
        createdBy: createdBy,
        category: category,
        isPublic: isPublic,
        accessCode: accessCode,
        isWeekly: isWeekly,
        tasks: tasks,
      );

      _isLoading = false;
      notifyListeners();
      return campaignId;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // METTRE À JOUR UNE CAMPAGNE (AVEC VÉRIFICATION DES DROITS)
  // ══════════════════════════════════════════════════════════════════════════
  ///
  /// Met à jour une campagne existante après avoir vérifié que l'utilisateur
  /// est bien le créateur.
  ///
  /// PARAMÈTRES :
  /// - campaignId : UUID de la campagne
  /// - updates : Map des champs à mettre à jour
  /// - userId : UUID de l'utilisateur (pour vérification)
  ///
  /// RETOURNE :
  /// - bool : true si succès, false si erreur
  /// ══════════════════════════════════════════════════════════════════════════
  Future<bool> updateCampaign({
    required String campaignId,
    required Map<String, dynamic> updates,
    required String userId, // ✅ Nouveau paramètre
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // ═══════════════════════════════════════════════════════════════════
      // VÉRIFICATION DES DROITS (avant d'appeler le backend)
      // ═══════════════════════════════════════════════════════════════════

      // ✅ Récupérer la campagne pour vérifier le créateur
      final campaign = await _campaignService.getCampaignById(campaignId);

      if (campaign == null) {
        _errorMessage = 'Campagne non trouvée.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // ✅ Vérifier que l'utilisateur est le créateur
      if (campaign.createdBy != userId) {
        _errorMessage = 'Vous n\'êtes pas autorisé à modifier cette campagne.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // ═══════════════════════════════════════════════════════════════════
      // APPEL AU SERVICE (si vérifications OK)
      // ═══════════════════════════════════════════════════════════════════

      await _campaignService.updateCampaign(campaignId, updates);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SUPPRIMER UNE CAMPAGNE (AVEC VÉRIFICATION DES DROITS)
  // ══════════════════════════════════════════════════════════════════════════
  ///
  /// Supprime une campagne après avoir vérifié que l'utilisateur est bien
  /// le créateur, et la retire des listes locales.
  ///
  /// PARAMÈTRES :
  /// - campaignId : UUID de la campagne
  /// - userId : UUID de l'utilisateur (pour vérification)
  ///
  /// RETOURNE :
  /// - bool : true si succès, false si erreur
  /// ══════════════════════════════════════════════════════════════════════════
  Future<bool> deleteCampaign({
    required String campaignId,
    required String userId, // ✅ Nouveau paramètre
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // ═══════════════════════════════════════════════════════════════════
      // VÉRIFICATION DES DROITS
      // ═══════════════════════════════════════════════════════════════════

      final campaign = await _campaignService.getCampaignById(campaignId);

      if (campaign == null) {
        _errorMessage = 'Campagne non trouvée.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (campaign.createdBy != userId) {
        _errorMessage = 'Vous n\'êtes pas autorisé à supprimer cette campagne.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // ═══════════════════════════════════════════════════════════════════
      // SUPPRESSION
      // ═══════════════════════════════════════════════════════════════════

      await _campaignService.deleteCampaign(campaignId);

      // Retirer de la liste locale
      _campaigns.removeWhere((c) => c.id == campaignId);
      _myCampaigns.removeWhere((c) => c.id == campaignId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================
  // RECHERCHER DES CAMPAGNES
  // ============================================
  Future<void> searchCampaigns(String query) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Si query vide, récupérer toutes les campagnes
      if (query.isEmpty) {
        await fetchCampaigns();
        return;
      }

      // ✅ CORRECTION : Gestion du null sur description
      _campaigns = _campaigns
          .where((campaign) =>
              campaign.name.toLowerCase().contains(query.toLowerCase()) ||
              (campaign.description
                      ?.toLowerCase()
                      .contains(query.toLowerCase()) ??
                  false))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // RÉINITIALISER L'ERREUR
  // ============================================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ============================================
  // ✅ PARSER LES MESSAGES D'ERREUR (NOUVEAU)
  // ============================================
  String _parseErrorMessage(String rawError) {
    // Extraire un message utilisateur clair depuis l'erreur brute

    if (rawError.contains('déjà abonné') ||
        rawError.contains('already subscribed')) {
      return 'Vous êtes déjà abonné à cette campagne.';
    }

    if (rawError.contains('Code d\'accès requis') ||
        rawError.contains('Access code required')) {
      return 'Un code d\'accès est requis pour accéder à cette campagne.';
    }

    if (rawError.contains('Code d\'accès invalide') ||
        rawError.contains('Invalid access code') ||
        rawError.contains('access code')) {
      return 'Le code d\'accès est invalide.';
    }

    if (rawError.contains('Quantité') || rawError.contains('quantity')) {
      return 'La quantité demandée n\'est plus disponible.';
    }

    if (rawError.contains('non authentifié') ||
        rawError.contains('not authenticated')) {
      return 'Vous devez être connecté pour effectuer cette action.';
    }

    if (rawError.contains('400')) {
      // Tentative d'extraction du message d'erreur spécifique du backend
      // Format attendu: "Exception: Erreur 400: Le message du backend"
      if (rawError.contains('Erreur 400:')) {
        return rawError.split('Erreur 400:').last.trim();
      }
      return 'Les données envoyées sont invalides. Veuillez vérifier.';
    }

    if (rawError.contains('404')) {
      return 'La campagne demandée n\'existe pas ou a été supprimée.';
    }

    if (rawError.contains('500') || rawError.contains('503')) {
      return 'Le serveur rencontre un problème. Veuillez réessayer plus tard.';
    }

    if (rawError.contains('réseau') || rawError.contains('network')) {
      return 'Erreur de connexion. Vérifiez votre connexion Internet.';
    }

    // Si aucun pattern reconnu, retourner un message générique
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}
