
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const LocationPickerScreen({
    super.key,
    this.initialLat = 14.6928, // Default Dakar
    this.initialLng = -17.4467,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final MapController _mapController;
  late LatLng _centerPosition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _centerPosition = LatLng(widget.initialLat, widget.initialLng);
  }

  void _onPositionChanged(MapPosition position, bool hasGesture) {
    if (position.center != null) {
      setState(() {
        _centerPosition = position.center!;
      });
    }
  }

  Future<void> _jumpToCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Service de localisation désactivé';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permission refusée';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permission refusée définitivement';
      }

      final position = await Geolocator.getCurrentPosition();
      final newCenter = LatLng(position.latitude, position.longitude);
      
      _mapController.move(newCenter, 15.0);
      setState(() {
        _centerPosition = newCenter;
      });
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmSelection() {
    Navigator.of(context).pop(_centerPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir la position'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _confirmSelection,
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _centerPosition,
              initialZoom: 15.0,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ousmanediane.silkoulAhzabou',
              ),
            ],
          ),
          
          // PIN FIXE AU CENTRE
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0), // Pour que le bas du pin pointe le centre
              child: Icon(
                Icons.location_on,
                size: 50,
                color: Colors.red,
              ),
            ),
          ),
          
          // INSTRUCTION OVERLAY
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Bougez la carte pour placer le repère sur le lieu exact',
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // LOADING
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _jumpToCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
