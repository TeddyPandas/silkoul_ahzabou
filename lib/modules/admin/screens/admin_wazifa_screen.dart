import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import '../../../../services/wazifa_service.dart';
import '../../../../models/wazifa_gathering.dart';
import 'admin_scaffold.dart';

class AdminWazifaScreen extends StatefulWidget {
  const AdminWazifaScreen({super.key});

  @override
  State<AdminWazifaScreen> createState() => _AdminWazifaScreenState();
}

class _AdminWazifaScreenState extends State<AdminWazifaScreen> {
  late Future<List<WazifaGathering>> _gatheringsFuture;

  @override
  void initState() {
    super.initState();
    _refreshGatherings();
  }

  void _refreshGatherings() {
    setState(() {
      _gatheringsFuture = WazifaService.instance.getAllGatherings();
    });
  }

  Future<void> _deleteGathering(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Confirmer la suppression", style: TextStyle(color: Colors.white)),
        content: const Text("Voulez-vous vraiment supprimer ce lieu ?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Annuler")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await WazifaService.instance.deleteGathering(id);
        _refreshGatherings();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lieu supprimé.")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentRoute: '/admin/wazifa',
      title: 'Modération Wazifa Finder',
      body: FutureBuilder<List<WazifaGathering>>(
        future: _gatheringsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text("Erreur: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }

          final gatherings = snapshot.data ?? [];

          if (gatherings.isEmpty) {
             return const Center(child: Text("Aucun lieu trouvé.", style: TextStyle(color: Colors.white)));
          }

          return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: gatherings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final gathering = gatherings[index];
                return Card(
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.white.withOpacity(0.1))),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.tealPrimary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.mosque, color: AppColors.tealPrimary),
                          ),
                          title: Text(gathering.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(gathering.address ?? "Pas d'adresse", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (gathering.scheduleMorning != null) Text("🌅 ${gathering.scheduleMorning!.format(context)}  ", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  if (gathering.scheduleEvening != null) Text("🌇 ${gathering.scheduleEvening!.format(context)}", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _StatusBadge(status: gathering.status),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (gathering.status == WazifaStatus.PENDING)
                              TextButton.icon(
                                icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                                label: const Text("Valider", style: TextStyle(color: Colors.greenAccent)),
                                onPressed: () async {
                                  try {
                                    await WazifaService.instance.updateGathering(gathering.id, {'status': 'APPROVED'});
                                    _refreshGatherings();
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lieu validé !")));
                                  } catch (e) {
                                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red));
                                  }
                                },
                              ),
                            TextButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              label: const Text("Supprimer", style: TextStyle(color: Colors.redAccent)),
                              onPressed: () => _deleteGathering(gathering.id),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final WazifaStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case WazifaStatus.APPROVED:
        color = Colors.green;
        text = "APPROUVÉ";
        break;
      case WazifaStatus.REJECTED:
        color = Colors.red;
        text = "REJETÉ";
        break;
      case WazifaStatus.PENDING:
      default:
        color = Colors.orange;
        text = "EN ATTENTE";
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
