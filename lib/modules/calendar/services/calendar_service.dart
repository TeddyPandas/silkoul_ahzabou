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
      return Course.fromJson(response);
    } catch (e) {
      debugPrint('❌ [CalendarService] Error creating course: $e');
      rethrow;
    }
  }

  /// Update a course
  Future<Course?> updateCourse(String courseId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('courses')
          .update(updates)
          .eq('id', courseId)
          .select()
          .single();
      return Course.fromJson(response);
    } catch (e) {
      debugPrint('❌ [CalendarService] Error updating course: $e');
      rethrow;
    }
  }

  /// Delete (soft) a course
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
}
