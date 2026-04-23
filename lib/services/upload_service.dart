import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class UploadService {
  // ✅ CSDL Lưu ảnh miễn phí: Cloudinary
  static const String _cloudName = "dtkyv8q9e"; 
  static const String _uploadPreset = "amour_preset"; 

  static Future<String?> uploadImage(File file) async {
    try {
      String url = "https://api.cloudinary.com/v1_1/$_cloudName/image/upload";
      
      // Xử lý gửi ảnh (Multipart)
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(file.path),
        "upload_preset": _uploadPreset,
      });

      Dio dio = Dio();
      var response = await dio.post(url, data: formData);

      if (response.statusCode == 200) {
        // Trả về URL ảnh vĩnh viễn trên Cloudinary
        String secureUrl = response.data["secure_url"];
        debugPrint("Upload Cloudinary thành công: $secureUrl");
        return secureUrl;
      }
      return null;
    } catch (e) {
      debugPrint("Lỗi upload Cloudinary: $e");
      return null;
    }
  }

  // Hỗ trợ upload cho Web (dùng bytes)
  static Future<String?> uploadImageWeb(Uint8List bytes) async {
    try {
      String url = "https://api.cloudinary.com/v1_1/$_cloudName/image/upload";
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(bytes, filename: "upload.jpg"),
        "upload_preset": _uploadPreset,
      });
      var response = await Dio().post(url, data: formData);
      return response.data["secure_url"];
    } catch (e) {
      return null;
    }
  }
}
