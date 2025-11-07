import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/campaign_provider.dart';
import 'campaign_details_screen.dart'; // To be created
import 'create_campaign_screen.dart'; // To be created

class CampaignsTab extends StatefulWidget {
  const CampaignsTab({super.key});

  @override
  State<CampaignsTab> createState() => _CampaignsTabState();
}

class _CampaignsTabState extends State<CampaignsTab> {
  @override
  void initState() {
    super.initState();
    // Load public campaigns when the tab is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CampaignProvider>(context, listen: false).fetchCampaigns();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Campaigns'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateCampaignScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<CampaignProvider>(
        builder: (context, campaignProvider, child) {
          if (campaignProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (campaignProvider.errorMessage != null) {
            return Center(
              child: Text(
                'Error: ${campaignProvider.errorMessage}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }
          if (campaignProvider.campaigns.isEmpty) {
            return const Center(
              child: Text('No public campaigns available.'),
            );
          }

          return ListView.builder(
            itemCount: campaignProvider.campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaignProvider.campaigns[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(campaign.name),
                  subtitle: Text(campaign.description ?? 'No description'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CampaignDetailsScreen(campaignId: campaign.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
