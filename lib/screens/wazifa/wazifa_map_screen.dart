import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/wazifa_provider.dart';
import '../../models/wazifa_gathering.dart';
import 'add_wazifa_screen.dart';

class WazifaMapScreen extends StatefulWidget {
  const WazifaMapScreen({Key? key}) : super(key: key);

  @override
  State<WazifaMapScreen> createState() => _WazifaMapScreenState();
}

class _WazifaMapScreenState extends State<WazifaMapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Charger les données après le build initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WazifaProvider>(context, listen: false).loadNearbyGatherings();
    });
  }

  bool _hasCentered = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wazifa Finder 📍'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<WazifaProvider>(context, listen: false)
                  .loadNearbyGatherings();
            },
          ),
        ],
      ),
      body: Consumer<WazifaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.gatherings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Auto-centrage à la première réception de la position
          if (provider.currentPosition != null && !_hasCentered) {
            _hasCentered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(
                LatLng(provider.currentPosition!.latitude,
                    provider.currentPosition!.longitude),
                15,
              );
            });
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   // ... error UI
                   Text('Erreur: ${provider.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red)),
                   // ...
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: provider.loadNearbyGatherings,
                     child: const Text('Réessayer'),
                   )
                ],
              ),
            );
          }

          // Point central par défaut (Dakar) si pas encore de GPS
          // Note: le controller.move ci-dessus prendra le relais dès que possible
          final center = const LatLng(14.6928, -17.4467);

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: center, // Utilise la position par défaut ou GPS
                  initialZoom: 13.0,
                  backgroundColor: Colors.grey[100]!, // Couleur de fond si les tuiles chargent pas
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // userAgentPackageName removed to test if it blocks requests
                  ),
                  MarkerLayer(
                    markers: [
                      // Marqueur Utilisateur (Bleu)
                      if (provider.currentPosition != null)
                        Marker(
                          point: LatLng(provider.currentPosition!.latitude,
                              provider.currentPosition!.longitude),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.person_pin_circle,
                              color: Colors.blueAccent, size: 40),
                        ),

                      // Marqueurs Wazifas
                      ...provider.gatherings.map((wazifa) {
                        return Marker(
                          point: LatLng(wazifa.lat, wazifa.lng),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () => _showWazifaDetails(context, wazifa),
                            child: _buildWazifaPin(wazifa.rhythm),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
              
              // ... existing filters ...
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "add_wazifa",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddWazifaScreen()),
              );
            },
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.add_location_alt, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "manual_location",
            mini: true,
            onPressed: () {
              _showManualLocationDialog(context);
            },
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.edit_location, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "my_location",
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('📍 Actualisation de la position...'),
                    duration: Duration(milliseconds: 800)),
              );
              
              // Force le rafraîchissement de la position et des données
              final provider = Provider.of<WazifaProvider>(context, listen: false);
              
              // Si on fait un appui court, on tente de revenir au GPS
              provider.resetToGPS();
              
              if (provider.currentPosition != null) {
                print("📍 Centrage sur: ${provider.currentPosition}");
                _mapController.move(
                    LatLng(provider.currentPosition!.latitude,
                        provider.currentPosition!.longitude),
                    15);
              }
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  void _showManualLocationDialog(BuildContext context) {
    final latController = TextEditingController(text: "14.6928");
    final lngController = TextEditingController(text: "-17.4467");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Position Manuelle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(labelText: "Latitude"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(labelText: "Longitude"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);
              if (lat != null && lng != null) {
                Provider.of<WazifaProvider>(context, listen: false)
                    .setManualLocation(lat, lng);
                Navigator.pop(context);
                
                 // Centrer la carte
                _mapController.move(LatLng(lat, lng), 15);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('📍 Position manuelle définie')),
                );
              }
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WazifaProvider provider,
      WazifaRhythm? rhythm, String label) {
    final isSelected = provider.selectedRhythm == rhythm;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        provider.setRhythmFilter(selected ? rhythm : null);
      },
      backgroundColor: Colors.white.withOpacity(0.9),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
    );
  }

  Widget _buildWazifaPin(WazifaRhythm rhythm) {
    Color color;
    switch (rhythm) {
      case WazifaRhythm.SLOW:
        color = Colors.green;
        break;
      case WazifaRhythm.MEDIUM:
        color = Colors.orange;
        break;
      case WazifaRhythm.FAST:
        color = Colors.red;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.location_on, color: color, size: 35),
      ),
    );
  }

  void _showWazifaDetails(BuildContext context, WazifaGathering wazifa) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    wazifa.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildRhythmBadge(wazifa.rhythm),
              ],
            ),
            const SizedBox(height: 10),
            if (wazifa.description != null)
              Text(
                wazifa.description!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "Matin: ${_formatTime(wazifa.scheduleMorning)} • Soir: ${_formatTime(wazifa.scheduleEvening)}",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchMaps(wazifa.lat, wazifa.lng),
                icon: const Icon(Icons.directions),
                label: const Text('Y ALLER'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRhythmBadge(WazifaRhythm rhythm) {
    String text;
    Color color;
    switch (rhythm) {
      case WazifaRhythm.SLOW:
        text = "Lent";
        color = Colors.green;
        break;
      case WazifaRhythm.MEDIUM:
        text = "Moyen";
        color = Colors.orange;
        break;
      case WazifaRhythm.FAST:
        text = "Rapide";
        color = Colors.red;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "--:--";
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final googleMapsUrl =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      // Fallback Apple Maps ou autre
       final fallbackUrl = Uri.parse("https://maps.apple.com/?q=$lat,$lng");
       if (await canLaunchUrl(fallbackUrl)) {
           await launchUrl(fallbackUrl);
       }
    }
  }
}
