import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Shared media upload helper for Aiscatty.
///
/// Uses the same unsigned Cloudinary preset the app already uses for pet
/// images, chat media and profile photos, so nothing new has to be configured.
/// Only the resulting URL is stored in Firestore — binary data is never
/// written to the database.
class MediaUploadService {
  static const _cloudName = 'dlwcgas2x';
  static const _uploadPreset = 'pets upload';

  /// Recommended limits for pet status videos.
  static const maxVideoSizeBytes = 50 * 1024 * 1024; // 50 MB
  static const maxVideoDurationSeconds = 30;

  /// Uploads a file and returns its secure URL.
  ///
  /// [resourceType] auto-detects image/video. Returns null on failure.
  static Future<String?> uploadFile(File file, {void Function(double)? onProgress}) async {
    try {
      final size = await file.length();
      if (size > maxVideoSizeBytes) return null;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/auto/upload'),
      )..fields['upload_preset'] = _uploadPreset;

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final res = await http.Response.fromStream(response);
      if (res.statusCode < 200 || res.statusCode >= 300) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['secure_url']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Checks a selected video against the recommended limits.
  /// Returns an error message, or null when the video is acceptable.
  static Future<String?> validateVideo(File file, {Duration? duration}) async {
    try {
      final size = await file.length();
      if (size > maxVideoSizeBytes) {
        return 'Video is too large (max 50 MB). Please pick a shorter clip.';
      }
      if (duration != null && duration.inSeconds > maxVideoDurationSeconds) {
        return 'Video is too long (max 30 seconds). Please trim it first.';
      }
    } catch (_) {
      return 'Could not read the selected video.';
    }
    return null;
  }
}
