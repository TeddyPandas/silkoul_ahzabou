import 'package:flutter/foundation.dart';
import '../models/user_task.dart';
import '../services/task_service.dart';
import '../services/user_service.dart'; // Import UserService
import '../utils/error_handler.dart';
import 'auth_provider.dart';

class UserProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();
  final UserService _userService = UserService(); // Instantiate UserService
  AuthProvider _authProvider; // To access and update AuthProvider's profile

  UserProvider(this._authProvider); // Constructor to receive AuthProvider

  void update(AuthProvider authProvider) {
    _authProvider = authProvider;
    notifyListeners();
  }

  List<UserTask> _userTasks = [];
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _users = []; // List to store other users
  bool _isLoading = false;
  String? _errorMessage;

  List<UserTask> get userTasks => _userTasks;
  Map<String, dynamic>? get stats => _stats;
  List<Map<String, dynamic>> get users => _users; // Getter for other users
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charger la liste des utilisateurs
  Future<void> loadUsers() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _users = await _userService.getUsers();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.sanitize(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _userService.updateUserProfile(
        userId: userId,
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      // Update the profile in AuthProvider as well
      _authProvider.updateProfile(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.sanitize(e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Charger les tâches d'un utilisateur pour une campagne
  Future<void> loadUserTasksForCampaign({
    required String userId,
    required String campaignId,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _userTasks = await _taskService.getUserTasksForCampaign(
        userId: userId,
        campaignId: campaignId,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.sanitize(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger toutes les tâches d'un utilisateur
  Future<void> loadAllUserTasks({
    required String userId,
    bool onlyIncomplete = false,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      ErrorHandler.log(
          '🔄 [UserProvider] loadAllUserTasks called for userId: $userId, onlyIncomplete: $onlyIncomplete');
      _userTasks = await _taskService.getAllUserTasks(
        userId: userId,
        onlyIncomplete: onlyIncomplete,
      );
      ErrorHandler.log(
          '✅ [UserProvider] loadAllUserTasks success. Found ${_userTasks.length} tasks.');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.sanitize(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mettre à jour la progression d'une tâche
  Future<bool> updateTaskProgress({
    required String userTaskId,
    required int incrementBy,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final index = _userTasks.indexWhere((t) => t.id == userTaskId);
      if (index == -1) {
        // Handle case where task is not found, maybe refresh the list
        throw Exception('Task not found in local list');
      }

      final task = _userTasks[index];
      final newCompletedQuantity = (task.completedQuantity + incrementBy)
          .clamp(0, task.subscribedQuantity);

      await _taskService.updateTaskProgress(
        userTaskId: userTaskId,
        completedQuantity: newCompletedQuantity,
      );

      // Update locally
      _userTasks[index] = task.copyWith(
        completedQuantity: newCompletedQuantity,
        isCompleted: newCompletedQuantity >= task.subscribedQuantity,
        updatedAt: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.sanitize(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Marquer une tâche comme complétée
  Future<bool> markTaskAsCompleted({
    required String userTaskId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _taskService.markTaskAsCompleted(userTaskId: userTaskId);

      // Mettre à jour localement
      final index = _userTasks.indexWhere((t) => t.id == userTaskId);
      if (index != -1) {
        final task = _userTasks[index];
        _userTasks[index] = task.copyWith(
          completedQuantity: task.subscribedQuantity,
          isCompleted: true,
          updatedAt: DateTime.now(),
          completedAt: DateTime.now(),
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.sanitize(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Démarquer une tâche complétée
  Future<bool> unmarkTaskAsCompleted({
    required String userTaskId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _taskService.unmarkTaskAsCompleted(userTaskId: userTaskId);

      // Mettre à jour localement
      final index = _userTasks.indexWhere((t) => t.id == userTaskId);
      if (index != -1) {
        final task = _userTasks[index];
        _userTasks[index] = task.copyWith(
          isCompleted: false,
          completedAt: null,
          updatedAt: DateTime.now(),
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = ErrorHandler.sanitize(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les statistiques de l'utilisateur
  Future<void> loadUserStats({
    required String userId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      _stats = await _taskService.getUserTaskStats(userId: userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.sanitize(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtenir les tâches du jour
  Future<void> loadTodayTasks({
    required String userId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      _userTasks = await _taskService.getTodayTasks(userId: userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = ErrorHandler.sanitize(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Effacer le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
