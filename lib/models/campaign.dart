import 'package:silkoul_ahzabou/models/task.dart';

class Campaign {
  final String id;
  final String name;
  final String? reference;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;
  final String? createdByName; // Pour afficher le nom du créateur
  final String? category;
  final bool isPublic;
  final String? accessCode;
  final bool isWeekly;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Task>? tasks;
  final int subscribersCount;

  Campaign({
    required this.id,
    required this.name,
    this.reference,
    this.description,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    this.createdByName,
    this.category,
    this.isPublic = true,
    this.accessCode,
    this.isWeekly = false,
    required this.createdAt,
    required this.updatedAt,
    this.tasks,
    this.subscribersCount = 0,
  });

  /// ══════════════════════════════════════════════════════════════════════════
  /// PARSER JSON ROBUSTE AVEC GESTION DES ERREURS
  /// ══════════════════════════════════════════════════════════════════════════
  ///
  /// Parse un objet Campaign depuis JSON avec gestion robuste des erreurs :
  /// - Gère les champs null ou manquants
  /// - Protège contre les erreurs de parsing de tâches individuelles
  /// - Continue le parsing même si certaines tâches sont invalides
  /// ══════════════════════════════════════════════════════════════════════════
  factory Campaign.fromJson(Map<String, dynamic> json) {
    // ✅ Protéger contre null ET champ manquant
    var tasksList = (json['tasks'] as List?) ?? [];

    // ✅ Gérer les erreurs de parsing de tâches individuelles
    List<Task> parsedTasks = [];
    for (var taskJson in tasksList) {
      try {
        if (taskJson is Map<String, dynamic>) {
          parsedTasks.add(Task.fromJson(taskJson));
        }
      } catch (e) {
        // Continuer avec les autres tâches en cas d'erreur
        print('Erreur lors du parsing d\'une tâche: $e');
      }
    }

    // ✅ Extract creator display_name from nested object
    String? createdByName;
    if (json['creator'] != null && json['creator'] is Map) {
      createdByName = json['creator']['display_name'] as String?;
    } else {
      createdByName = json['created_by_name'] as String?;
    }

    // ✅ Extract subscribers count if available (from backend aggregation)
    // Often comes as user_campaigns_count or similar depending on query
    // For now we look for 'subscribers_count' or nested aggregate
    int subCount = 0;
    if (json['subscribers_count'] != null) {
      subCount = json['subscribers_count'] is int
          ? json['subscribers_count']
          : int.tryParse(json['subscribers_count'].toString()) ?? 0;
    } else if (json['user_campaigns'] != null &&
        json['user_campaigns'] is List) {
      // Loopback/count case if array is returned
      subCount = (json['user_campaigns'] as List).length;
    } else if (json['user_campaigns_count'] != null) {
      subCount = json['user_campaigns_count'] is int
          ? json['user_campaigns_count']
          : int.tryParse(json['user_campaigns_count'].toString()) ?? 0;
    }

    return Campaign(
      id: json['id'] as String,
      name: json['name'] as String,
      reference: json['reference'] as String?,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      createdBy: json['created_by'] as String,
      createdByName: createdByName,
      category: json['category'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      accessCode: json['access_code'] as String?,
      isWeekly: json['is_weekly'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      // ✅ Retourner null si aucune tâche valide, sinon la liste
      tasks: parsedTasks.isEmpty ? null : parsedTasks,
      subscribersCount: subCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'reference': reference,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'created_by': createdBy,
      'category': category,
      'is_public': isPublic,
      'access_code': accessCode,
      'is_weekly': isWeekly,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'subscribers_count': subscribersCount,
    };
  }

  // Vérifier si la campagne est active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  // Vérifier si la campagne est terminée
  bool get isCompleted {
    return DateTime.now().isAfter(endDate);
  }

  // Vérifier si la campagne est à venir
  bool get isUpcoming {
    return DateTime.now().isBefore(startDate);
  }

  // Calculer le nombre de jours restants
  int get daysRemaining {
    if (isCompleted) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  // Calculer le pourcentage de temps écoulé
  double get timeProgress {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;

    final totalDuration = endDate.difference(startDate).inMilliseconds;
    final elapsed = now.difference(startDate).inMilliseconds;

    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  Campaign copyWith({
    String? name,
    String? reference,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? createdBy,
    String? createdByName,
    String? category,
    bool? isPublic,
    String? accessCode,
    bool? isWeekly,
    DateTime? updatedAt,
    int? subscribersCount,
  }) {
    return Campaign(
      id: id,
      name: name ?? this.name,
      reference: reference ?? this.reference,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      category: category ?? this.category,
      isPublic: isPublic ?? this.isPublic,
      accessCode: accessCode ?? this.accessCode,
      isWeekly: isWeekly ?? this.isWeekly,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscribersCount: subscribersCount ?? this.subscribersCount,
    );
  }
}
