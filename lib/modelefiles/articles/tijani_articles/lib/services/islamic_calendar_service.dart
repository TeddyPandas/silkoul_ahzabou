import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/islamic_date.dart';
import '../models/islamic_event.dart';

/// Service for fetching Islamic calendar data from Aladhan API
class IslamicCalendarService {
  static const String baseUrl = 'https://api.aladhan.com/v1';
  
  /// Get current Hijri date
  /// 
  /// Returns the current Islamic date with Gregorian equivalent
  Future<IslamicDate?> getCurrentHijriDate() async {
    try {
      // Get current date
      final now = DateTime.now();
      final timestamp = (now.millisecondsSinceEpoch / 1000).round();
      
      final response = await http.get(
        Uri.parse('$baseUrl/gToH/$timestamp'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          return IslamicDate.fromJson(data['data']['hijri']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching current Hijri date: $e');
      return null;
    }
  }

  /// Get Hijri date for a specific Gregorian date
  /// 
  /// [date] - The Gregorian date to convert
  /// Returns the corresponding Islamic date
  Future<IslamicDate?> getHijriDate(DateTime date) async {
    try {
      final timestamp = (date.millisecondsSinceEpoch / 1000).round();
      
      final response = await http.get(
        Uri.parse('$baseUrl/gToH/$timestamp'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          return IslamicDate.fromJson(data['data']['hijri']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching Hijri date: $e');
      return null;
    }
  }

  /// Convert Hijri date to Gregorian
  /// 
  /// [day] - Day of Islamic month (1-30)
  /// [month] - Islamic month number (1-12)
  /// [year] - Islamic year
  /// Returns the corresponding Gregorian date
  Future<DateTime?> hijriToGregorian(int day, int month, int year) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/hToG/$day-$month-$year'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200 && data['data'] != null) {
          final gregorian = data['data']['gregorian'];
          return DateTime(
            int.parse(gregorian['year']),
            int.parse(gregorian['month']['number']),
            int.parse(gregorian['day']),
          );
        }
      }
      return null;
    } catch (e) {
      print('Error converting Hijri to Gregorian: $e');
      return null;
    }
  }

  /// Get upcoming Islamic events
  /// 
  /// Returns a list of upcoming important Islamic dates
  Future<List<IslamicEvent>> getUpcomingEvents({int daysAhead = 90}) async {
    try {
      final currentHijri = await getCurrentHijriDate();
      if (currentHijri == null) return [];

      final currentYear = int.parse(currentHijri.year);
      final events = IslamicEvents.getYearlyEvents(currentYear);
      final nextYearEvents = IslamicEvents.getYearlyEvents(currentYear + 1);
      
      final allEvents = [...events, ...nextYearEvents];
      final upcomingEvents = <IslamicEvent>[];

      for (var event in allEvents) {
        // Convert Hijri event date to Gregorian
        final gregorianDate = await hijriToGregorian(
          event['hijriDay'],
          event['hijriMonth'],
          event['hijriMonth'] > currentHijri.monthNumber 
              ? currentYear 
              : currentYear + 1,
        );

        if (gregorianDate != null) {
          final now = DateTime.now();
          final daysUntil = gregorianDate.difference(now).inDays;

          // Only include events within the specified range
          if (daysUntil >= 0 && daysUntil <= daysAhead) {
            final hijriEventDate = await getHijriDate(gregorianDate);
            if (hijriEventDate != null) {
              upcomingEvents.add(IslamicEvent(
                name: event['name'],
                nameAr: event['nameAr'],
                description: event['description'],
                descriptionAr: event['descriptionAr'],
                gregorianDate: gregorianDate,
                hijriDate: hijriEventDate,
                type: EventType.fromString(event['type']),
                daysUntil: daysUntil,
              ));
            }
          }
        }
      }

      // Sort by days until
      upcomingEvents.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
      
      return upcomingEvents;
    } catch (e) {
      print('Error fetching upcoming events: $e');
      return [];
    }
  }

  /// Get Islamic month names in Arabic
  static List<String> getMonthNamesArabic() {
    return [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];
  }

  /// Get Islamic month names in English
  static List<String> getMonthNamesEnglish() {
    return [
      'Muharram',
      'Safar',
      'Rabi\' al-awwal',
      'Rabi\' al-thani',
      'Jumada al-awwal',
      'Jumada al-thani',
      'Rajab',
      'Sha\'ban',
      'Ramadan',
      'Shawwal',
      'Dhu al-Qi\'dah',
      'Dhu al-Hijjah',
    ];
  }

  /// Check if a date is in Ramadan
  Future<bool> isRamadan(DateTime date) async {
    final hijriDate = await getHijriDate(date);
    return hijriDate?.monthNumber == 9;
  }

  /// Get number of days until Ramadan
  Future<int?> daysUntilRamadan() async {
    try {
      final events = await getUpcomingEvents(daysAhead: 365);
      final ramadanEvent = events.firstWhere(
        (event) => event.type == EventType.ramadan && event.hijriDate.day == 1,
        orElse: () => events.first,
      );
      return ramadanEvent.daysUntil;
    } catch (e) {
      print('Error calculating days until Ramadan: $e');
      return null;
    }
  }

  /// Get Hijri calendar for a specific month
  /// 
  /// [month] - Islamic month number (1-12)
  /// [year] - Islamic year
  /// Returns list of dates for that month
  Future<List<IslamicDate>> getMonthCalendar(int month, int year) async {
    try {
      final dates = <IslamicDate>[];
      
      // Islamic months can have 29 or 30 days
      for (int day = 1; day <= 30; day++) {
        final gregorianDate = await hijriToGregorian(day, month, year);
        if (gregorianDate != null) {
          final hijriDate = await getHijriDate(gregorianDate);
          if (hijriDate != null) {
            dates.add(hijriDate);
          }
        }
      }
      
      return dates;
    } catch (e) {
      print('Error fetching month calendar: $e');
      return [];
    }
  }
}
