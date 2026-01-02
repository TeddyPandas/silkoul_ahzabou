
import 'package:flutter/material.dart';

enum WazifaRhythm {
  SLOW,
  MEDIUM,
  FAST,
}

class WazifaGathering {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final WazifaRhythm rhythm;
  final TimeOfDay? scheduleMorning;
  final TimeOfDay? scheduleEvening;
  final String? contactPhone;
  final double lat;
  final double lng;
  final double? distanceMeters; // Pour l'affichage de la distance

  WazifaGathering({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.rhythm = WazifaRhythm.MEDIUM,
    this.scheduleMorning,
    this.scheduleEvening,
    this.contactPhone,
    required this.lat,
    required this.lng,
    this.distanceMeters,
  });

  /// Convertit depuis la réponse de la fonction RPC Supabase
  factory WazifaGathering.fromJson(Map<String, dynamic> json) {
    return WazifaGathering(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      address: json['address'],
      rhythm: _parseRhythm(json['rhythm']),
      scheduleMorning: _parseTime(json['schedule_morning']),
      scheduleEvening: _parseTime(json['schedule_evening']),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      contactPhone: json['contact_phone'],
    );
  }

  static WazifaRhythm _parseRhythm(String? value) {
    switch (value) {
      case 'SLOW':
        return WazifaRhythm.SLOW;
      case 'FAST':
        return WazifaRhythm.FAST;
      default:
        return WazifaRhythm.MEDIUM;
    }
  }

  static TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }
}
