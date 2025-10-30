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
        taskSubscriptions: selectedTasks,
        selectedTasks: selectedTasks,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
