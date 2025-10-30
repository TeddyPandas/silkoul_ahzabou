import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/campaign.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/auth_provider.dart';
import 'subscribe_dialog.dart'; // To be created

class CampaignDetailsScreen extends StatefulWidget {
  final String campaignId;

  const CampaignDetailsScreen({super.key, required this.campaignId});

  @override
  State<CampaignDetailsScreen> createState() => _CampaignDetailsScreenState();
}

class _CampaignDetailsScreenState extends State<CampaignDetailsScreen> {
  Campaign? _campaign;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadCampaignDetails();
  }

  Future<void> _loadCampaignDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final campaignProvider =
          Provider.of<CampaignProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      final campaign =
          await campaignProvider.getCampaignById(widget.campaignId);
      if (campaign != null) {
        _campaign = campaign;
        if (userId != null) {
          _isSubscribed = await campaignProvider.isUserSubscribed(
            userId: userId,
            campaignId: widget.campaignId,
          );
        }
      } else {
        _errorMessage = 'Campaign not found.';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: AppColors.error),
                  ),
                )
              : _campaign == null
                  ? const Center(child: Text('Campaign not found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _campaign!.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'By ${_campaign!.createdByName ?? "Unknown"}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _campaign!.description ??
                                'No description provided.',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Category: ${_campaign!.category ?? "N/A"}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Starts: ${_campaign!.startDate.toLocal().toIso8601String().split('T').first}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ends: ${_campaign!.endDate.toLocal().toIso8601String().split('T').first}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          if (_campaign!.tasks != null &&
                              _campaign!.tasks!.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tasks:',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._campaign!.tasks!.map((task) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        '- ${task.name} (Total: ${task.totalNumber}, Remaining: ${task.remainingNumber})',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    )),
                              ],
                            ),
                          const SizedBox(height: 24),
                          if (!_isSubscribed)
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => SubscribeDialog(
                                      campaign: _campaign!,
                                      onSubscriptionSuccess: () {
                                        _loadCampaignDetails(); // Refresh details after subscription
                                      },
                                    ),
                                  );
                                },
                                child: const Text('Join Campaign'),
                              ),
                            )
                          else
                            const Center(
                              child: Text(
                                'You are already subscribed to this campaign.',
                                style: TextStyle(
                                    fontSize: 16, color: AppColors.primary),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }
}
