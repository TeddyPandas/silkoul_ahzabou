class Task {
  final String id;
  final String campaignId; // Required - but may be empty if parsed from nested response
  final String name;
  final int totalNumber;
  final int remainingNumber;
  final int? dailyGoal;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int completedCount; // ✅ Adds tracking of global completions

  Task({
    required this.id,
    required this.campaignId,
    required this.name,
    required this.totalNumber,
    required this.remainingNumber,
    this.dailyGoal,
    required this.createdAt,
    required this.updatedAt,
    this.completedCount = 0,
  });

  /// Parse from JSON with robust null handling
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String? ?? '',
      campaignId: json['campaign_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Tâche sans nom',
      totalNumber: (json['total_number'] as num?)?.toInt() ?? 0,
      remainingNumber: (json['remaining_number'] as num?)?.toInt() ?? 0,
      dailyGoal: (json['daily_goal'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'name': name,
      'total_number': totalNumber,
      'remaining_number': remainingNumber,
      'daily_goal': dailyGoal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_count': completedCount,
    };
  }

  // Calculer le pourcentage de complétion globale
  double get completionPercentage {
    if (totalNumber == 0) return 0.0;
    return (completedCount / totalNumber * 100).clamp(0.0, 100.0);
  }

  // Vérifier si la tâche est complète (tous assignés OU tous finis ?)
  bool get isCompleted {
    return remainingNumber <= 0;
  }

  // Nombre déjà complété (Legacy / Subscription usage)
  // Used in task_card.dart. 
  // If task_card wants "how many taken", it's (total - remaining).
  int get completedNumber {
    return totalNumber - remainingNumber;
  }

  Task copyWith({
    String? campaignId,
    String? name,
    int? totalNumber,
    int? remainingNumber,
    int? dailyGoal,
    DateTime? updatedAt,
    int? completedCount,
  }) {
    return Task(
      id: id,
      campaignId: campaignId ?? this.campaignId,
      name: name ?? this.name,
      totalNumber: totalNumber ?? this.totalNumber,
      remainingNumber: remainingNumber ?? this.remainingNumber,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedCount: completedCount ?? this.completedCount,
    );
  }
}
