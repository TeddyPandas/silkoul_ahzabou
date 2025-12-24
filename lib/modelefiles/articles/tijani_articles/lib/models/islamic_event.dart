/// Model representing an important Islamic event or holiday
class IslamicEvent {
  final String name;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final DateTime gregorianDate;
  final IslamicDate hijriDate;
  final EventType type;
  final int daysUntil;

  IslamicEvent({
    required this.name,
    required this.nameAr,
    required this.description,
    required this.descriptionAr,
    required this.gregorianDate,
    required this.hijriDate,
    required this.type,
    required this.daysUntil,
  });

  factory IslamicEvent.fromJson(Map<String, dynamic> json) {
    return IslamicEvent(
      name: json['name'] ?? '',
      nameAr: json['nameAr'] ?? '',
      description: json['description'] ?? '',
      descriptionAr: json['descriptionAr'] ?? '',
      gregorianDate: DateTime.parse(json['gregorianDate']),
      hijriDate: IslamicDate.fromJson(json['hijriDate']),
      type: EventType.fromString(json['type'] ?? 'other'),
      daysUntil: json['daysUntil'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nameAr': nameAr,
      'description': description,
      'descriptionAr': descriptionAr,
      'gregorianDate': gregorianDate.toIso8601String(),
      'hijriDate': hijriDate.toJson(),
      'type': type.value,
      'daysUntil': daysUntil,
    };
  }

  /// Check if event is today
  bool get isToday => daysUntil == 0;

  /// Check if event is upcoming (within 30 days)
  bool get isUpcoming => daysUntil > 0 && daysUntil <= 30;

  /// Get formatted days until text
  String get daysUntilText {
    if (daysUntil == 0) return 'Aujourd\'hui';
    if (daysUntil == 1) return 'Demain';
    if (daysUntil < 7) return 'Dans $daysUntil jours';
    if (daysUntil < 30) return 'Dans ${(daysUntil / 7).floor()} semaines';
    return 'Dans ${(daysUntil / 30).floor()} mois';
  }

  @override
  String toString() {
    return 'IslamicEvent(name: $name, date: ${hijriDate.formattedDate}, daysUntil: $daysUntil)';
  }
}

/// Import for IslamicDate
import 'islamic_date.dart';

/// Enum for event types
enum EventType {
  ramadan('ramadan'),
  eid('eid'),
  hijri('hijri'),
  prophet('prophet'),
  other('other');

  final String value;
  const EventType(this.value);

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => EventType.other,
    );
  }

  /// Get icon for event type
  String get icon {
    switch (this) {
      case EventType.ramadan:
        return '🌙';
      case EventType.eid:
        return '🕌';
      case EventType.hijri:
        return '📅';
      case EventType.prophet:
        return '✨';
      case EventType.other:
        return '📆';
    }
  }

  /// Get color for event type
  String get color {
    switch (this) {
      case EventType.ramadan:
        return '#9B7EBD';
      case EventType.eid:
        return '#D4AF37';
      case EventType.hijri:
        return '#0FA958';
      case EventType.prophet:
        return '#0FA958';
      case EventType.other:
        return '#6B7280';
    }
  }
}

/// Predefined important Islamic events
class IslamicEvents {
  /// Get list of important Islamic events for a Hijri year
  static List<Map<String, dynamic>> getYearlyEvents(int hijriYear) {
    return [
      {
        'name': 'Islamic New Year',
        'nameAr': 'رأس السنة الهجرية',
        'description': 'Beginning of the Islamic calendar year',
        'descriptionAr': 'بداية السنة الهجرية الجديدة',
        'hijriMonth': 1,
        'hijriDay': 1,
        'type': 'hijri',
      },
      {
        'name': 'Ashura',
        'nameAr': 'يوم عاشوراء',
        'description': 'Day of Ashura, 10th of Muharram',
        'descriptionAr': 'اليوم العاشر من شهر محرم',
        'hijriMonth': 1,
        'hijriDay': 10,
        'type': 'hijri',
      },
      {
        'name': 'Mawlid al-Nabi',
        'nameAr': 'المولد النبوي الشريف',
        'description': 'Birthday of Prophet Muhammad (PBUH)',
        'descriptionAr': 'ذكرى مولد النبي محمد صلى الله عليه وسلم',
        'hijriMonth': 3,
        'hijriDay': 12,
        'type': 'prophet',
      },
      {
        'name': 'Isra and Mi\'raj',
        'nameAr': 'الإسراء والمعراج',
        'description': 'Night Journey of Prophet Muhammad (PBUH)',
        'descriptionAr': 'رحلة الإسراء والمعراج',
        'hijriMonth': 7,
        'hijriDay': 27,
        'type': 'prophet',
      },
      {
        'name': 'Beginning of Ramadan',
        'nameAr': 'بداية شهر رمضان',
        'description': 'Start of the holy month of fasting',
        'descriptionAr': 'بداية شهر رمضان المبارك',
        'hijriMonth': 9,
        'hijriDay': 1,
        'type': 'ramadan',
      },
      {
        'name': 'Laylat al-Qadr',
        'nameAr': 'ليلة القدر',
        'description': 'Night of Power',
        'descriptionAr': 'ليلة القدر المباركة',
        'hijriMonth': 9,
        'hijriDay': 27,
        'type': 'ramadan',
      },
      {
        'name': 'Eid al-Fitr',
        'nameAr': 'عيد الفطر',
        'description': 'Festival of Breaking the Fast',
        'descriptionAr': 'عيد الفطر المبارك',
        'hijriMonth': 10,
        'hijriDay': 1,
        'type': 'eid',
      },
      {
        'name': 'Day of Arafat',
        'nameAr': 'يوم عرفة',
        'description': 'Day of Arafat during Hajj',
        'descriptionAr': 'يوم عرفة المبارك',
        'hijriMonth': 12,
        'hijriDay': 9,
        'type': 'hijri',
      },
      {
        'name': 'Eid al-Adha',
        'nameAr': 'عيد الأضحى',
        'description': 'Festival of Sacrifice',
        'descriptionAr': 'عيد الأضحى المبارك',
        'hijriMonth': 12,
        'hijriDay': 10,
        'type': 'eid',
      },
    ];
  }
}
