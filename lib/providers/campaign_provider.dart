// lib/providers/campaign_provider.dart
import 'package:flutter/foundation.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';

class CampaignProvider with ChangeNotifier {
  final CampaignService _campaignService = CampaignService();

  List<Campaign> _campaigns = [];
  List<Campaign> _myCampaigns = [];
  Campaign? _selectedCampaign;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Campaign> get campaigns => _campaigns;
  List<Campaign> get myCampaigns => _myCampaigns;
  Campaign? get selectedCampaign => _selectedCampaign;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ============================================
  // RÉCUPÉRER TOUTES LES CAMPAGNES PUBLIQUES
  // ============================================
  Future<void> fetchCampaigns({String? category, String? searchQuery}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // ✅ CORRECTION : getPublicCampaigns sans paramètre onlyPublic
      _campaigns = await _campaignService.getPublicCampaigns(
        category: category,
        searchQuery: searchQuery,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
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

      // ✅ CORRECTION : getUserCampaigns avec userId requis
      _myCampaigns = await _campaignService.getUserCampaigns(
        userId: userId,
        onlyCreated: onlyCreated,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================
  // RÉCUPÉRER UNE CAMPAGNE PAR ID
  // ============================================
  Future<void> fetchCampaignById(String campaignId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _selectedCampaign = await _campaignService.getCampaignById(campaignId);

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
  Future<Campaign?> getCampaignById(String campaignId) async {
    try {
      return await _campaignService.getCampaignById(campaignId);
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
      _errorMessage =
          'Un code d\'accès est requis pour les campagnes privées.';
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
        _errorMessage =
            'Vous n\'êtes pas autorisé à supprimer cette campagne.';
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

    if (rawError.contains('Code d\'accès') ||
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
