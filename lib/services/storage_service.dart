import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final SupabaseClient _client = SupabaseService.client;

  /// Uploads an audio file to the 'teachings' bucket.
  /// Returns the public URL of the uploaded file.
  Future<String> uploadAudio({
    File? file,
    Uint8List? bytes,
    required String path, // e.g., "podcasts/show_id/filename.mp3"
  }) async {
    try {
      final String fullPath = path;
      print('📂 Uploading to: $fullPath');

      // 1. Upload
      if (bytes != null) {
        // Web / Bytes
        await _client.storage.from('teachings').uploadBinary(
              fullPath,
              bytes,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );
      } else if (file != null) {
        // Mobile / File
        await _client.storage.from('teachings').upload(
              fullPath,
              file,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );
      } else {
        throw Exception("Both file and bytes are null");
      }

      // 2. Get Public URL
      final String publicUrl = _client.storage.from('teachings').getPublicUrl(fullPath);
      
      print('✅ Upload successful: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Storage Upload Error: $e');
      rethrow;
    }
  }

  /// Deletes a file from storage
  Future<void> deleteFile(String path) async {
    try {
       await _client.storage.from('teachings').remove([path]);
    } catch (e) {
      print('❌ Storage Delete Error: $e');
      // Non-critical, just log
    }
  }
}
