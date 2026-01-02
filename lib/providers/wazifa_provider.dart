
import 'package:flutter/foundation.dart';
import '../models/wazifa_gathering.dart';
import '../services/wazifa_service.dart';
import 'package:geolocator/geolocator.dart';

class WazifaProvider with ChangeNotifier {
  final WazifaService _service = WazifaService.instance;

  List<WazifaGathering> _gatherings = [];
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;
  
  // Filtres
  WazifaRhythm? _selectedRhythm; // Null = Tous

  List<WazifaGathering> get gatherings {
    if (_selectedRhythm == null) {
      return _gatherings;
    }
    return _gatherings.where((w) => w.rhythm == _selectedRhythm).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get currentPosition => _currentPosition;
  WazifaRhythm? get selectedRhythm => _selectedRhythm;

  void setRhythmFilter(WazifaRhythm? rhythm) {
    _selectedRhythm = rhythm;
    notifyListeners();
  }

  bool _isManualLocation = false;

  Future<void> loadNearbyGatherings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Obtenir la position actuelle (si pas en mode manuel)
      if (!_isManualLocation) {
        try {
          _currentPosition = await _determinePosition();
        } catch (locationError) {
          print("⚠️ Impossible d'obtenir le GPS: $locationError");
          // Fallback silencieux ou via position par défaut (Dakar) pour ne pas bloquer l'app
          // On ne met pas _currentPosition à null si on veut qu'il utilise le fallback
          // Mais pour l'instant, disons qu'on utilise une position par défaut si null
        }
      }

      // Position utilisée pour la requête (GPS ou Dakar par défaut)
      final queryLat = _currentPosition?.latitude ?? 14.6928;
      final queryLng = _currentPosition?.longitude ?? -17.4467;
      
      // 2. Charger les données (même si pas de GPS, on charge autour de Dakar)
      _gatherings = await _service.getNearbyGatherings(
        lat: queryLat,
        lng: queryLng,
      );

    } catch (e) {
      _error = e.toString();
      print("Erreur WazifaProvider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setManualLocation(double lat, double lng) async {
    _isManualLocation = true;
    _currentPosition = Position(
      longitude: lng,
      latitude: lat,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0, 
      altitudeAccuracy: 0, 
      headingAccuracy: 0,
    );
    await loadNearbyGatherings();
  }

  void resetToGPS() {
    _isManualLocation = false;
    loadNearbyGatherings();
  }

  Future<void> addGathering({
    required String name,
    required String description,
    required double lat,
    required double lng,
    required WazifaRhythm rhythm,
    required String scheduleMorning,
    required String scheduleEvening,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.createGathering(
        name: name,
        description: description,
        lat: lat,
        lng: lng,
        rhythm: rhythm,
        scheduleMorning: scheduleMorning,
        scheduleEvening: scheduleEvening,
      );
      // Recharger la liste après ajout
      await loadNearbyGatherings();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Position> _determinePosition() async {
    print('📍 [WazifaProvider] Début _determinePosition');
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Vérifier si le service est activé
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    print('📍 [WazifaProvider] Service localisation activé: $serviceEnabled');
    if (!serviceEnabled) {
      throw Exception('Les services de localisation sont désactivés. Activez le GPS.');
    }

    // 2. Vérifier la permission actuelle
    permission = await Geolocator.checkPermission();
    print('📍 [WazifaProvider] Permission actuelle: $permission');
    
    if (permission == LocationPermission.denied) {
      // 3. Demander la permission
      permission = await Geolocator.requestPermission();
      print('📍 [WazifaProvider] Permission après demande: $permission');
      if (permission == LocationPermission.denied) {
        throw Exception('Les permissions de localisation sont refusées');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('📍 [WazifaProvider] Permission refusée définitivement');
      throw Exception(
          'Les permissions de localisation sont définitivement refusées.');
    }

    // 4. Obtenir la position
    print('📍 [WazifaProvider] Récupération de la position...');
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Réduit pour tester
        timeLimit: const Duration(seconds: 10), // Timeout de 10s
      );
      print('📍 [WazifaProvider] Position obtenue: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('📍 [WazifaProvider] Erreur getCurrentPosition: $e');
      rethrow;
    }
  }
}
