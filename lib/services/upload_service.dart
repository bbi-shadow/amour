import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class UploadService {
  static const String _cloudName = "dbhqr7bsz";
  static const String _uploadPreset = "amour_preset";
  static const String _uploadUrl =
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload";

  static Dio _buildDio() {
    final dio = Dio();
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(seconds: 60);
    dio.options.sendTimeout = const Duration(seconds: 60);
    return dio;
  }

  /// Upload ảnh từ File (Mobile)
  static Future<String?> uploadImage(File file) async {
    if (!await file.exists()) {
      debugPrint("❌ File không tồn tại: ${file.path}");
      return null;
    }

    try {
      final ext = file.path.split('.').last.toLowerCase();
      final filename = 'amour_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: filename),
        "upload_preset": _uploadPreset,
      });

      final dio = _buildDio();
      final response = await dio.post(_uploadUrl, data: formData);

      if (response.statusCode == 200) {
        final url = response.data["secure_url"] as String;
        debugPrint("✅ Cloudinary Upload Success: $url");
        return url;
      }
      return null;
    } catch (e) {
      debugPrint("❌ Cloudinary Upload Error: $e");
      return null;
    }
  }

  /// Upload ảnh từ Bytes (Web hoặc Memory)
  static Future<String?> uploadImageWeb(Uint8List bytes) async {
    try {
      final formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          bytes,
          filename: 'amour_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        "upload_preset": _uploadPreset,
      });
      final response = await _buildDio().post(_uploadUrl, data: formData);
      return response.data["secure_url"] as String;
    } catch (e) {
      debugPrint("❌ Cloudinary Web Upload Error: $e");
      return null;
    }
  }
}
