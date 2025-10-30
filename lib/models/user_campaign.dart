class UserCampaign {
  final String id;
  final String userId;
  final String campaignId;
  final DateTime joinedAt;

  UserCampaign({
    required this.id,
    required this.userId,
    required this.campaignId,
    required this.joinedAt,
  });

  factory UserCampaign.fromJson(Map<String, dynamic> json) {
    return UserCampaign(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      campaignId: json['campaign_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'campaign_id': campaignId,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
