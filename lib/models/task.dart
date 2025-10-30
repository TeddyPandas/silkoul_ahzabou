class Task {
  final String id;
  final String campaignId;
  final String name;
  final int totalNumber;
  final int remainingNumber;
  final int? dailyGoal;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.campaignId,
    required this.name,
    required this.totalNumber,
    required this.remainingNumber,
    this.dailyGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String,
      name: json['name'] as String,
      totalNumber: json['total_number'] as int,
      remainingNumber: json['remaining_number'] as int,
      dailyGoal: json['daily_goal'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
    };
  }

  // Calculer le pourcentage de complétion globale
  double get completionPercentage {
    if (totalNumber == 0) return 0.0;
    final completed = totalNumber - remainingNumber;
    return (completed / totalNumber * 100).clamp(0.0, 100.0);
  }

  // Vérifier si la tâche est complète
  bool get isCompleted {
    return remainingNumber <= 0;
  }

  // Nombre déjà complété
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
    );
  }
}
