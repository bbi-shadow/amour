import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/upload_service.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

class EditProfileController extends GetxController {
  static EditProfileController get to => Get.find();

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final String uid = AuthController.to.currentUid ?? '';

  final nameCtrl = TextEditingController();
  final bioCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final jobCtrl = TextEditingController();
  final schoolCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  final RxList<String?> photoUrls = RxList<String?>(List.filled(6, null));
  final RxList<XFile?> newFiles = RxList<XFile?>(List.filled(6, null));
  final RxString gender = 'Nam'.obs;
  final RxList<String> selectedHobbies = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    bioCtrl.dispose();
    ageCtrl.dispose();
    jobCtrl.dispose();
    schoolCtrl.dispose();
    locationCtrl.dispose();
    super.onClose();
  }

  Future<void> loadUserData() async {
    if (uid.isEmpty) return;
    isLoading.value = true;
    try {
      final user = await FirestoreService.getUser(uid);
      if (user != null) {
        nameCtrl.text = user.name;
        bioCtrl.text = user.bio;
        ageCtrl.text = user.age.toString();
        jobCtrl.text = user.job;
        schoolCtrl.text = user.school;
        locationCtrl.text = user.city;
        gender.value = user.gender;
        selectedHobbies.assignAll(user.interests);
        
        for (int i = 0; i < 6; i++) {
          if (i < user.photos.length) {
            photoUrls[i] = user.photos[i];
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickPhoto(int index, ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        newFiles[index] = picked;
      }
    } catch (e) {
      AppHelpers.showError("Khong the chon anh");
    }
  }

  void removePhoto(int index) {
    photoUrls[index] = null;
    newFiles[index] = null;
  }

  void toggleHobby(String label) {
    if (selectedHobbies.contains(label)) {
      selectedHobbies.remove(label);
    } else {
      selectedHobbies.add(label);
    }
  }

  Future<void> saveProfile() async {
    if (nameCtrl.text.trim().isEmpty) {
      AppHelpers.showError("Vui lòng nhập tên");
      return;
    }

    isSaving.value = true;
    try {
      List<String> finalUrls = [];
      for (int i = 0; i < 6; i++) {
        if (newFiles[i] != null) {
          String? url;
          if (kIsWeb) {
            url = await UploadService.uploadImageWeb(await newFiles[i]!.readAsBytes());
          } else {
            url = await UploadService.uploadImage(File(newFiles[i]!.path));
          }
          if (url != null) finalUrls.add(url);
        } else if (photoUrls[i] != null) {
          finalUrls.add(photoUrls[i]!);
        }
      }

      await FirestoreService.updateProfile(uid, {
        'name': nameCtrl.text.trim(),
        'bio': bioCtrl.text.trim(),
        'age': int.tryParse(ageCtrl.text.trim()) ?? 18,
        'job': jobCtrl.text.trim(),
        'school': schoolCtrl.text.trim(),
        'city': locationCtrl.text.trim(),
        'gender': gender.value,
        'interests': selectedHobbies,
        'photoUrl': finalUrls.isNotEmpty ? finalUrls.first : "",
        'photos': finalUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppHelpers.showSuccess("Cập nhật thành công");
      Get.back();
    } catch (e) {
      AppHelpers.showError("Lỗi khi lưu: $e");
    } finally {
      isSaving.value = false;
    }
  }
}
