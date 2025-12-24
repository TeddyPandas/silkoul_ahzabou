import 'package:flutter/foundation.dart';
import '../models/islamic_date.dart';
import '../models/islamic_event.dart';
import '../services/islamic_calendar_service.dart';

/// Provider for managing Islamic calendar data
class IslamicCalendarProvider with ChangeNotifier {
  final IslamicCalendarService _service = IslamicCalendarService();

  IslamicDate? _currentHijriDate;
  List<IslamicEvent> _upcomingEvents = [];
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdated;

  // Getters
  IslamicDate? get currentHijriDate => _currentHijriDate;
  List<IslamicEvent> get upcomingEvents => _upcomingEvents;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdated => _lastUpdated;

  /// Check if data needs refresh (older than 1 hour)
  bool get needsRefresh {
    if (_lastUpdated == null) return true;
    final hoursSinceUpdate = DateTime.now().difference(_lastUpdated!).inHours;
    return hoursSinceUpdate >= 1;
  }

  /// Get today's events
  List<IslamicEvent> get todaysEvents {
    return _upcomingEvents.where((event) => event.isToday).toList();
  }

  /// Get upcoming events (next 30 days)
  List<IslamicEvent> get nearUpcomingEvents {
    return _upcomingEvents.where((event) => event.isUpcoming).toList();
  }

  /// Initialize and fetch all data
  Future<void> initialize() async {
    if (!needsRefresh && _currentHijriDate != null) {
      return; // Data is still fresh
    }

    await fetchCurrentDate();
    await fetchUpcomingEvents();
  }

  /// Fetch current Hijri date
  Future<void> fetchCurrentDate() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final date = await _service.getCurrentHijriDate();
      
      if (date != null) {
        _currentHijriDate = date;
        _lastUpdated = DateTime.now();
        _error = null;
      } else {
        _error = 'Failed to fetch current Hijri date';
      }
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      debugPrint('Error fetching current Hijri date: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch upcoming Islamic events
  Future<void> fetchUpcomingEvents({int daysAhead = 90}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final events = await _service.getUpcomingEvents(daysAhead: daysAhead);
      
      _upcomingEvents = events;
      _lastUpdated = DateTime.now();
      _error = null;
    } catch (e) {
      _error = 'Error: ${e.toString()}';
      debugPrint('Error fetching upcoming events: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get Hijri date for a specific Gregorian date
  Future<IslamicDate?> getHijriDateFor(DateTime date) async {
    try {
      return await _service.getHijriDate(date);
    } catch (e) {
      debugPrint('Error getting Hijri date: $e');
      return null;
    }
  }

  /// Check if current date is in Ramadan
  bool get isRamadan {
    return _currentHijriDate?.monthNumber == 9;
  }

  /// Get Ramadan progress (0.0 to 1.0)
  double? get ramadanProgress {
    if (!isRamadan || _currentHijriDate == null) return null;
    return _currentHijriDate!.day / 30.0;
  }

  /// Get next important event
  IslamicEvent? get nextEvent {
    if (_upcomingEvents.isEmpty) return null;
    return _upcomingEvents.first;
  }

  /// Get formatted current date string
  String get currentDateFormatted {
    if (_currentHijriDate == null) return 'Loading...';
    return _currentHijriDate!.formattedDate;
  }

  /// Get formatted current date in Arabic
  String get currentDateFormattedAr {
    if (_currentHijriDate == null) return 'جاري التحميل...';
    return _currentHijriDate!.formattedDateAr;
  }

  /// Refresh all data
  Future<void> refresh() async {
    _lastUpdated = null; // Force refresh
    await initialize();
  }

  /// Clear all data
  void clear() {
    _currentHijriDate = null;
    _upcomingEvents = [];
    _error = null;
    _lastUpdated = null;
    notifyListeners();
  }

  /// Get event by name
  IslamicEvent? getEventByName(String name) {
    try {
      return _upcomingEvents.firstWhere(
        (event) => event.name == name || event.nameAr == name,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get events by type
  List<IslamicEvent> getEventsByType(EventType type) {
    return _upcomingEvents.where((event) => event.type == type).toList();
  }

  /// Check if there's an event today
  bool get hasEventToday => todaysEvents.isNotEmpty;

  /// Get count of upcoming events in next 7 days
  int get weeklyEventsCount {
    return _upcomingEvents.where((event) => event.daysUntil <= 7).length;
  }

  /// Get count of upcoming events in next 30 days
  int get monthlyEventsCount {
    return _upcomingEvents.where((event) => event.daysUntil <= 30).length;
  }

  @override
  void dispose() {
    // Clean up if needed
    super.dispose();
  }
}
