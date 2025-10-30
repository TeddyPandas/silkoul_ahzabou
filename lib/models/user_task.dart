class UserTask {
  final String id;
  final String userId;
  final String taskId;
  final String taskName; // Pour affichage
  final int subscribedQuantity;
  final int completedQuantity;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  UserTask({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.taskName,
    required this.subscribedQuantity,
    this.completedQuantity = 0,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory UserTask.fromJson(Map<String, dynamic> json) {
    return UserTask(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      taskId: json['task_id'] as String,
      taskName: json['task_name'] as String? ?? '',
      subscribedQuantity: json['subscribed_quantity'] as int,
      completedQuantity: json['completed_quantity'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'task_id': taskId,
      'subscribed_quantity': subscribedQuantity,
      'completed_quantity': completedQuantity,
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  // Calculer le pourcentage de progression
  double get progressPercentage {
    if (subscribedQuantity == 0) return 0.0;
    return (completedQuantity / subscribedQuantity * 100).clamp(0.0, 100.0);
  }

  // Quantité restante
  int get remainingQuantity {
    return (subscribedQuantity - completedQuantity).clamp(0, subscribedQuantity);
  }

  // Vérifier si l'utilisateur peut marquer comme complet
  bool get canMarkAsComplete {
    return completedQuantity >= subscribedQuantity && !isCompleted;
  }

  UserTask copyWith({
    String? taskName,
    int? subscribedQuantity,
    int? completedQuantity,
    bool? isCompleted,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return UserTask(
      id: id,
      userId: userId,
      taskId: taskId,
      taskName: taskName ?? this.taskName,
      subscribedQuantity: subscribedQuantity ?? this.subscribedQuantity,
      completedQuantity: completedQuantity ?? this.completedQuantity,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
