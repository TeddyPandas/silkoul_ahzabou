import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final SupabaseClient _client = SupabaseService.client;

  /// Validates that a storage path is safe (no directory traversal).
  void _validatePath(String path) {
    if (path.isEmpty) throw ArgumentError('Storage path cannot be empty');
    if (path.contains('..')) throw ArgumentError('Storage path must not contain ".."');
    if (path.startsWith('/')) throw ArgumentError('Storage path must be relative');
    if (RegExp(r'[<>:"|?*\x00-\x1F]').hasMatch(path)) {
      throw ArgumentError('Storage path contains invalid characters');
    }
  }

  /// Uploads an audio file to the 'teachings' bucket.
  /// Returns the public URL of the uploaded file.
  Future<String> uploadAudio({
    File? file,
    Uint8List? bytes,
    required String path, // e.g., "podcasts/show_id/filename.mp3"
  }) async {
    try {
      _validatePath(path);
      final String fullPath = path;
      debugPrint('📂 Uploading to: $fullPath');

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
      
      debugPrint('✅ Upload successful: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('❌ Storage Upload Error: $e');
      rethrow;
    }
  }

  /// Deletes a file from storage
  Future<void> deleteFile(String path) async {
    try {
       await _client.storage.from('teachings').remove([path]);
    } catch (e) {
      debugPrint('❌ Storage Delete Error: $e');
      // Non-critical, just log
    }
  }
}
