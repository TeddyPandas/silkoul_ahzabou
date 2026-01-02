
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wazifa_gathering.dart';
import '../services/supabase_service.dart';

class WazifaService {
  WazifaService._();

  static final WazifaService instance = WazifaService._();

  final SupabaseClient _client = SupabaseService.client;

  /// Récupérer les Wazifas à proximité (via RPC)
  Future<List<WazifaGathering>> getNearbyGatherings({
    required double lat,
    required double lng,
    double radiusMeters = 50000, // 50km par défaut
  }) async {
    try {
      final List<dynamic> response = await _client.rpc(
        'get_nearby_wazifas',
        params: {
          'p_lat': lat,
          'p_lng': lng,
          'radius_meters': radiusMeters,
        },
      );

      return response.map((json) => WazifaGathering.fromJson(json)).toList();
    } catch (e) {
      print('❌ Erreur lors de la récupération des Wazifas: $e');
      rethrow;
    }
  }

  /// Ajouter un nouveau lieu de Wazifa
  Future<void> createGathering({
    required String name,
    required String description,
    required double lat,
    required double lng,
    required WazifaRhythm rhythm,
    required String scheduleMorning, // Format "HH:mm"
    required String scheduleEvening, // Format "HH:mm"
  }) async {
    try {
      await _client.rpc('create_wazifa', params: {
        'p_name': name,
        'p_description': description,
        'p_lat': lat,
        'p_lng': lng,
        'p_rhythm': rhythm.name.toUpperCase(), // Enum to String
        'p_morning': scheduleMorning,
        'p_evening': scheduleEvening,
      });
      print('✅ Lieu Wazifa créé avec succès');
    } catch (e) {
      print('❌ Erreur lors de la création du Wazifa: $e');
      rethrow;
    }
  }
}
