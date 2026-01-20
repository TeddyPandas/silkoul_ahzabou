import 'package:flutter/material.dart';
import '../../../../services/campaign_service.dart';
import '../../../../models/campaign.dart';
import '../screens/admin_scaffold.dart';
import '../widgets/admin_campaign_edit_dialog.dart';
import 'package:intl/intl.dart';

class AdminCampaignsScreen extends StatefulWidget {
  const AdminCampaignsScreen({super.key});

  @override
  State<AdminCampaignsScreen> createState() => _AdminCampaignsScreenState();
}

class _AdminCampaignsScreenState extends State<AdminCampaignsScreen> {
  final CampaignService _service = CampaignService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Campaign> _campaigns = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final int _limit = 20;
  String _currentCategory = '';

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _isLoading = true);
    try {
      // NOTE: getPublicCampaigns returns List<Campaign>. 
      // Supabase's current wrapper in getPublicCampaigns doesn't return total count yet.
      // For now, we fetch the page.
      final campaigns = await _service.getPublicCampaigns(
        page: _currentPage,
        limit: _limit,
        searchQuery: _searchController.text.trim(),
        category: _currentCategory.isEmpty ? null : _currentCategory,
      );
      
      setState(() {
        _campaigns = campaigns;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
         setState(() => _isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _openEditor(Campaign campaign) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AdminCampaignEditDialog(campaign: campaign),
    );

    if (result == true) {
      _loadCampaigns();
    }
  }

  void _deleteCampaign(Campaign campaign) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text("Supprimer ${campaign.name} ?", style: const TextStyle(color: Colors.white)),
        content: const Text("Toutes les tâches et abonnements seront supprimés. Cette action est irréversible.", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteCampaign(campaign.id);
        _loadCampaigns();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: '/admin/campaigns',
      title: 'Gestion des Campagnes',
      body: Column(
        children: [
          // Toolbar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Rechercher une campagne...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (val) {
                      _currentPage = 1;
                      _loadCampaigns();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF1E1E1E),
                  value: _currentCategory,
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: '', child: Text("Toutes les catégories")),
                    DropdownMenuItem(value: 'Zikr', child: Text("Zikr")),
                    DropdownMenuItem(value: 'Quran', child: Text("Coran")),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _currentCategory = val!;
                      _currentPage = 1;
                    });
                    _loadCampaigns();
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _campaigns.isEmpty
                    ? const Center(child: Text("Aucune campagne trouvée.", style: TextStyle(color: Colors.white)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _campaigns.length,
                        itemBuilder: (context, index) {
                          final campaign = _campaigns[index];
                          final bool isActive = campaign.isActive;
                          
                          return Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (isActive ? Colors.green : Colors.grey).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isActive ? Icons.play_circle_fill : Icons.stop_circle,
                                  color: isActive ? Colors.green : Colors.grey,
                                ),
                              ),
                              title: Text(
                                campaign.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "${DateFormat('dd/MM/yyyy').format(campaign.startDate)} - ${DateFormat('dd/MM/yyyy').format(campaign.endDate)} | ${campaign.subscribersCount} Participants",
                                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                    onPressed: () => _openEditor(campaign),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _deleteCampaign(campaign),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Pagination
          if (!_isLoading && (_campaigns.length == _limit || _currentPage > 1))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadCampaigns();
                          }
                        : null,
                  ),
                  Text("Page $_currentPage", style: const TextStyle(color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _campaigns.length == _limit
                        ? () {
                            setState(() => _currentPage++);
                            _loadCampaigns();
                          }
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
