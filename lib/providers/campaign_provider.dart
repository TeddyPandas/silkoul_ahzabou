import 'package:flutter/foundation.dart';
import '../models/campaign.dart';
import '../models/task.dart';
import '../services/campaign_service.dart';

class CampaignProvider with ChangeNotifier {
  final CampaignService _campaignService = CampaignService();

  List<Campaign> _publicCampaigns = [];
  List<Campaign> _myCampaigns = [];
  List<Campaign> _createdCampaigns = [];
  List<Task> _currentCampaignTasks = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<Campaign> get publicCampaigns => _publicCampaigns;
  List<Campaign> get myCampaigns => _myCampaigns;
  List<Campaign> get createdCampaigns => _createdCampaigns;
  List<Task> get currentCampaignTasks => _currentCampaignTasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Créer une nouvelle campagne
  Future<String?> createCampaign({
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
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Charger les campagnes publiques
  Future<void> loadPublicCampaigns({
    String? category,
    String? searchQuery,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _publicCampaigns = await _campaignService.getPublicCampaigns(
        category: category,
        searchQuery: searchQuery,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les campagnes de l'utilisateur (souscrites)
  Future<void> loadMyCampaigns(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _myCampaigns = await _campaignService.getUserCampaigns(
        userId: userId,
        onlyCreated: false,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les campagnes créées par l'utilisateur
  Future<void> loadCreatedCampaigns(String userId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _createdCampaigns = await _campaignService.getUserCampaigns(
        userId: userId,
        onlyCreated: true,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les tâches d'une campagne
  Future<void> loadCampaignTasks(String campaignId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _currentCampaignTasks = await _campaignService.getCampaignTasks(
        campaignId,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// S'abonner à une campagne
  Future<bool> subscribeToCampaign({
    required String userId,
    required String campaignId,
    String? accessCode,
    required List<Map<String, dynamic>> selectedTasks,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _campaignService.subscribeToCampaign(
        userId: userId,
        campaignId: campaignId,
        accessCode: accessCode,
        selectedTasks: selectedTasks, // ✅ Un seul paramètre, nom clair
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Parser l'erreur pour extraire un message clair
      String userMessage = 'Erreur lors de l\'abonnement à la campagne';
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('déjà abonné') || errorString.contains('already subscribed')) {
        userMessage = 'Vous êtes déjà abonné à cette campagne';
      } else if (errorString.contains('code d\'accès') || errorString.contains('access code') || errorString.contains('code invalide')) {
        userMessage = 'Code d\'accès invalide';
      } else if (errorString.contains('quantité') || errorString.contains('quantity') || errorString.contains('disponible')) {
        userMessage = 'La quantité demandée n\'est plus disponible';
      } else if (errorString.contains('campagne terminée') || errorString.contains('campaign ended')) {
        userMessage = 'Cette campagne est terminée';
      } else if (errorString.contains('non authentifié') || errorString.contains('not authenticated')) {
        userMessage = 'Vous devez être connecté pour vous abonner';
      } else if (errorString.contains('404')) {
        userMessage = 'Campagne introuvable';
      } else if (errorString.contains('400')) {
        userMessage = 'Données invalides. Veuillez vérifier votre sélection';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        userMessage = 'Erreur de connexion. Vérifiez votre réseau';
      }

      _errorMessage = userMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Vérifier si l'utilisateur est abonné à une campagne
  Future<bool> isUserSubscribed({
    required String userId,
    required String campaignId,
  }) async {
    try {
      return await _campaignService.isUserSubscribed(
        userId: userId,
        campaignId: campaignId,
      );
    } catch (e) {
      return false;
    }
  }

  /// Obtenir une campagne par ID
  Future<Campaign?> getCampaignById(String campaignId) async {
    try {
      return await _campaignService.getCampaignById(campaignId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Effacer le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
