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

  // ============================================
  // CRÉER UNE CAMPAGNE
  // ============================================
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
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // ✅ CORRECTION : Ajout du paramètre createdBy requis
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

  // ============================================
  // METTRE À JOUR UNE CAMPAGNE
  // ============================================
  // TODO: Implémenter updateCampaign dans CampaignService
  // Le backend supporte PUT /api/campaigns/:id mais le service ne l'expose pas encore
  /*
  Future<bool> updateCampaign(
    String campaignId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

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
  */

  // ============================================
  // SUPPRIMER UNE CAMPAGNE
  // ============================================
  // TODO: Implémenter deleteCampaign dans CampaignService
  // Le backend supporte DELETE /api/campaigns/:id mais le service ne l'expose pas encore
  /*
  Future<bool> deleteCampaign(String campaignId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

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
  */

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
              (campaign.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
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
