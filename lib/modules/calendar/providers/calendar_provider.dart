import 'package:flutter/material.dart';
import '../models/course.dart';
import '../services/calendar_service.dart';

class CalendarProvider extends ChangeNotifier {
  final CalendarService _service = CalendarService();

  List<Course> _courses = [];
  bool _isLoading = false;
  String? _error;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Returns all courses (including expanded recurring ones) for a given day
  List<Course> coursesForDay(DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    final result = <Course>[];

    for (final course in _courses) {
      if (course.recurrence == 'once') {
        // One-time course: exact date match
        final courseDay = DateTime(
          course.startTime.year,
          course.startTime.month,
          course.startTime.day,
        );
        if (courseDay == dayOnly) {
          result.add(course);
        }
      } else if (course.recurrence == 'weekly') {
        // Weekly: match day of week (1=Monday...7=Sunday)
        if (course.startTime.weekday == day.weekday &&
            !day.isBefore(DateTime(
              course.startTime.year,
              course.startTime.month,
              course.startTime.day,
            ))) {
          // Create a virtual course for this specific date
          result.add(Course(
            id: course.id,
            title: course.title,
            description: course.description,
            teacherName: course.teacherName,
            startTime: DateTime(
              day.year,
              day.month,
              day.day,
              course.startTime.hour,
              course.startTime.minute,
            ),
            durationMinutes: course.durationMinutes,
            telegramLink: course.telegramLink,
            recurrence: course.recurrence,
            recurrenceDay: course.recurrenceDay,
            color: course.color,
            isActive: course.isActive,
            createdBy: course.createdBy,
            createdAt: course.createdAt,
          ));
        }
      } else if (course.recurrence == 'daily') {
        // Daily: every day from start date onwards
        final courseStartDay = DateTime(
          course.startTime.year,
          course.startTime.month,
          course.startTime.day,
        );
        if (!dayOnly.isBefore(courseStartDay)) {
          result.add(Course(
            id: course.id,
            title: course.title,
            description: course.description,
            teacherName: course.teacherName,
            startTime: DateTime(
              day.year,
              day.month,
              day.day,
              course.startTime.hour,
              course.startTime.minute,
            ),
            durationMinutes: course.durationMinutes,
            telegramLink: course.telegramLink,
            recurrence: course.recurrence,
            recurrenceDay: course.recurrenceDay,
            color: course.color,
            isActive: course.isActive,
            createdBy: course.createdBy,
            createdAt: course.createdAt,
          ));
        }
      }
    }

    // Sort by time
    result.sort((a, b) => a.startTime.compareTo(b.startTime));
    return result;
  }

  /// Check if a day has any courses
  bool hasCourses(DateTime day) => coursesForDay(day).isNotEmpty;

  /// Fetch all courses from Supabase
  Future<void> fetchCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _courses = await _service.fetchCourses();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new course
  Future<bool> createCourse(Map<String, dynamic> data) async {
    try {
      final course = await _service.createCourse(data);
      if (course != null) {
        _courses.add(course);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update a course
  Future<bool> updateCourse(String courseId, Map<String, dynamic> data, {String? oldStartTime}) async {
    try {
      final updated = await _service.updateCourse(courseId, data, oldStartTime: oldStartTime);
      if (updated != null) {
        final index = _courses.indexWhere((c) => c.id == courseId);
        if (index != -1) {
          _courses[index] = updated;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cancel a course (soft-delete + Telegram notification)
  Future<bool> cancelCourse(String courseId) async {
    try {
      await _service.cancelCourse(courseId);
      _courses.removeWhere((c) => c.id == courseId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete a course (no notification)
  Future<bool> deleteCourse(String courseId) async {
    try {
      await _service.deleteCourse(courseId);
      _courses.removeWhere((c) => c.id == courseId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
