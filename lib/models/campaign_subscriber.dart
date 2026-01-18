/// Represents a task that a subscriber has subscribed to
class SubscribedTask {
  final String taskId;
  final String taskName;
  final int subscribedQuantity;

  SubscribedTask({
    required this.taskId,
    required this.taskName,
    required this.subscribedQuantity,
  });

  factory SubscribedTask.fromJson(Map<String, dynamic> json) {
    // Expecting structure from nested join:
    // {
    //   "subscribed_quantity": 10,
    //   "task": {
    //     "id": "...",
    //     "name": "..."
    //   }
    // }
    final task = json['task'] as Map<String, dynamic>? ?? {};
    return SubscribedTask(
      taskId: task['id'] as String? ?? '',
      taskName: task['name'] as String? ?? 'Tâche inconnue',
      subscribedQuantity: json['subscribed_quantity'] as int? ?? 0,
    );
  }
}

class CampaignSubscriber {
  final String visitorId; // Unique subscription ID (user_id in user_campaigns)
  final String visitorUId; // Legacy alias - kept for compatibility
  final String displayName;
  final String? avatarUrl;
  final DateTime joinedAt;
  final List<SubscribedTask> subscribedTasks;

  // Convenience getter for backward compatibility
  String get userId => visitorId;

  CampaignSubscriber({
    required this.visitorId,
    String? visitorUId,
    required this.displayName,
    this.avatarUrl,
    required this.joinedAt,
    this.subscribedTasks = const [],
  }) : visitorUId = visitorUId ?? visitorId;

  factory CampaignSubscriber.fromJson(Map<String, dynamic> json, {String? campaignId}) {
    // Expecting structure from Supabase join:
    // {
    //   "joined_at": "...",
    //   "user_id": "...",
    //   "profiles": {
    //     "id": "...",
    //     "display_name": "...",
    //     "avatar_url": "...",
    //     "user_tasks": [
    //       {
    //         "subscribed_quantity": 10,
    //         "task": { "id": "...", "name": "...", "campaign_id": "..." }
    //       }
    //     ]
    //   }
    // }
    
    final profile = json['profiles'] as Map<String, dynamic>? ?? {};
    final visitorId = profile['id'] as String? ?? json['user_id'] as String;
    
    // Parse user_tasks from inside profiles and filter by campaign
    List<SubscribedTask> tasks = [];
    // Check both locations for user_tasks (inside profiles or at root)
    final userTasksRaw = profile['user_tasks'] ?? json['user_tasks'];
    if (userTasksRaw != null && userTasksRaw is List) {
      for (final ut in userTasksRaw) {
        if (ut is Map<String, dynamic>) {
          final task = ut['task'] as Map<String, dynamic>?;
          // Filter to only include tasks from the specified campaign
          if (campaignId == null || 
              (task != null && task['campaign_id'] == campaignId)) {
            tasks.add(SubscribedTask.fromJson(ut));
          }
        }
      }
    }
    
    return CampaignSubscriber(
      visitorId: visitorId,
      displayName: profile['display_name'] as String? ?? 'Utilisateur inconnu',
      avatarUrl: profile['avatar_url'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      subscribedTasks: tasks,
    );
  }
}
