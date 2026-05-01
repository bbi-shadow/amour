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

  static Future<String?> uploadImage(File file) async {
    if (!await file.exists()) {
      debugPrint("❌ File không tồn tại: ${file.path}");
      return null;
    }

    final fileSize = await file.length();
    debugPrint("📁 Bắt đầu upload (${(fileSize / 1024).toStringAsFixed(1)} KB)");

    try {
      final ext = file.path.split('.').last.toLowerCase();
      final filename = 'amour_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path, filename: filename),
        "upload_preset": _uploadPreset,
      });

      final response = await _buildDio().post(_uploadUrl, data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) debugPrint("⬆️ Upload: ${(sent / total * 100).toStringAsFixed(0)}%");
        },
      );

      if (response.statusCode == 200) {
        final url = response.data["secure_url"] as String;
        debugPrint("✅ Upload thành công: $url");
        return url;
      }
      debugPrint("❌ Server lỗi: ${response.statusCode}");
      return null;
    } on DioException catch (e) {
      debugPrint("❌ Lỗi Dio: ${e.response?.data?["error"]?["message"] ?? e.message}");
      debugPrint("❌ Status: ${e.response?.statusCode}");
      debugPrint("❌ Response: ${e.response?.data}");
      return null;
    } catch (e) {
      debugPrint("❌ Lỗi không xác định: $e");
      return null;
    }
  }

  static Future<String?> uploadImageWeb(Uint8List bytes) async {
    debugPrint("📁 Upload Web (${(bytes.length / 1024).toStringAsFixed(1)} KB)");
    try {
      final formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          bytes,
          filename: 'amour_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        "upload_preset": _uploadPreset,
      });
      final response = await _buildDio().post(_uploadUrl, data: formData);
      final url = response.data["secure_url"] as String;
      debugPrint("✅ Upload Web thành công: $url");
      return url;
    } on DioException catch (e) {
      debugPrint("❌ Lỗi: ${e.response?.data?["error"]?["message"] ?? e.message}");
      return null;
    } catch (e) {
      debugPrint("❌ Lỗi: $e");
      return null;
    }
  }
}