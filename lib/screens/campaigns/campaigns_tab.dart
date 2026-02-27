import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';
import 'campaign_details_screen.dart';
import 'create_campaign_screen.dart';

class CampaignsTab extends StatefulWidget {
  final bool showMyCampaigns;

  const CampaignsTab({super.key, this.showMyCampaigns = false});

  @override
  State<CampaignsTab> createState() => _CampaignsTabState();
}

class _CampaignsTabState extends State<CampaignsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CampaignProvider>(context, listen: false).fetchCampaigns();
    });
  }

  void _openCreateCampaign() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateCampaignScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = context.watch<AuthProvider>().isGuest;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.campaigns),
        actions: [
          if (!isGuest)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _openCreateCampaign,
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
                l10n.errorWithMessage(campaignProvider.errorMessage ?? ''),
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }
          if (campaignProvider.campaigns.isEmpty) {
            return Center(child: Text(l10n.noCampaignsAvailable));
          }

          return RefreshIndicator(
            onRefresh: () => campaignProvider.fetchCampaigns(),
            child: ListView.builder(
              itemCount: campaignProvider.campaigns.length,
              itemBuilder: (context, index) {
                final campaign = campaignProvider.campaigns[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(campaign.name),
                    subtitle: Text(campaign.description ?? l10n.noDescription),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CampaignDetailsScreen(campaignId: campaign.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: isGuest
          ? null
          : FloatingActionButton.extended(
              onPressed: _openCreateCampaign,
              label: Text(l10n.createCampaign),
              icon: const Icon(Icons.add),
              backgroundColor: AppColors.primary,
            ),
    );
  }
}
