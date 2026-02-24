import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/course.dart';

class CalendarService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all active courses
  Future<List<Course>> fetchCourses() async {
    try {
      final response = await _supabase
          .from('courses')
          .select()
          .eq('is_active', true)
          .order('start_time', ascending: true);

      final data = response as List<dynamic>;
      return data.map((json) => Course.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [CalendarService] Error fetching courses: $e');
      return [];
    }
  }

  /// Create a new course (admin only)
  Future<Course?> createCourse(Map<String, dynamic> courseData) async {
    try {
      final response = await _supabase
          .from('courses')
          .insert(courseData)
          .select()
          .single();
      final course = Course.fromJson(response);
      
      // Notify Telegram
      await _notifyTelegram('created', response);
      
      return course;
    } catch (e) {
      debugPrint('❌ [CalendarService] Error creating course: $e');
      rethrow;
    }
  }

  /// Update a course
  Future<Course?> updateCourse(String courseId, Map<String, dynamic> updates, {String? oldStartTime}) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('courses')
          .update(updates)
          .eq('id', courseId)
          .select()
          .single();
      final course = Course.fromJson(response);
      
      // Notify Telegram about rescheduling
      await _notifyTelegram('rescheduled', response, oldStartTime: oldStartTime);
      
      return course;
    } catch (e) {
      debugPrint('❌ [CalendarService] Error updating course: $e');
      rethrow;
    }
  }

  /// Cancel a course (soft-delete + notify)
  Future<void> cancelCourse(String courseId) async {
    try {
      // Fetch current course data before cancelling (for notification)
      final courseData = await _supabase
          .from('courses')
          .select()
          .eq('id', courseId)
          .single();

      await _supabase
          .from('courses')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', courseId);

      // Notify Telegram about cancellation
      await _notifyTelegram('cancelled', courseData);
    } catch (e) {
      debugPrint('❌ [CalendarService] Error cancelling course: $e');
      rethrow;
    }
  }

  /// Delete (soft) a course — legacy, no notification
  Future<void> deleteCourse(String courseId) async {
    try {
      await _supabase
          .from('courses')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', courseId);
    } catch (e) {
      debugPrint('❌ [CalendarService] Error deleting course: $e');
      rethrow;
    }
  }

  /// Send notification to Telegram via Edge Function
  Future<void> _notifyTelegram(String event, Map<String, dynamic> courseData, {String? oldStartTime}) async {
    try {
      final body = {
        'event': event,
        'course': courseData,
        if (oldStartTime != null) 'old_start_time': oldStartTime,
      };

      await _supabase.functions.invoke(
        'telegram-course-notify',
        body: body,
      );
      debugPrint('✅ [CalendarService] Telegram notification sent: $event');
    } catch (e) {
      // Don't rethrow — notification failure shouldn't block the course action
      debugPrint('⚠️ [CalendarService] Telegram notification failed (non-blocking): $e');
    }
  }
}
