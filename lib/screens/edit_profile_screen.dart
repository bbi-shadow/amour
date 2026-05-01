import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/edit_profile_controller.dart';
import '../controllers/theme_controller.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EditProfileController());
    final isDark = ThemeController.to.isDark;
    final bg = isDark ? AppColors.darkBg : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Obx(() => TextButton(
            onPressed: controller.isSaving.value ? null : controller.saveProfile,
            child: controller.isSaving.value 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Lưu', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoGrid(controller, isDark),
              const SizedBox(height: 32),
              _buildSectionTitle('Thông tin cơ bản', isDark),
              const SizedBox(height: 16),
              _buildBasicInfo(controller, isDark),
              const SizedBox(height: 32),
              _buildSectionTitle('Sở thích', isDark),
              const SizedBox(height: 16),
              _buildHobbies(controller, isDark),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white38 : Colors.grey.shade600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPhotoGrid(EditProfileController controller, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: 6,
      itemBuilder: (context, i) {
        return Obx(() {
          final photoUrl = controller.photoUrls[i];
          final newFile = controller.newFiles[i];
          final hasPhoto = photoUrl != null || newFile != null;

          return GestureDetector(
            onTap: () => _showPickerOptions(context, controller, i),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                image: hasPhoto ? DecorationImage(
                  image: newFile != null 
                    ? FileImage(File(newFile.path)) as ImageProvider // ✅ Đã sửa: XFile -> File
                    : NetworkImage(photoUrl!),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: Stack(
                children: [
                  if (!hasPhoto)
                    const Center(child: Icon(Icons.add_a_photo_outlined, color: AppColors.primary)),
                  if (hasPhoto)
                    Positioned(
                      top: 6, right: 6,
                      child: GestureDetector(
                        onTap: () => controller.removePhoto(i),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showPickerOptions(BuildContext context, EditProfileController controller, int index) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Thêm ảnh hồ sơ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh ngay'),
              onTap: () { Get.back(); controller.pickPhoto(index, ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () { Get.back(); controller.pickPhoto(index, ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfo(EditProfileController controller, bool isDark) {
    return Column(
      children: [
        _buildTextField(controller.nameCtrl, 'Họ tên', Icons.person_outline, isDark),
        const SizedBox(height: 12),
        _buildTextField(controller.ageCtrl, 'Tuổi', Icons.cake_outlined, isDark, keyboardType: TextInputType.number),
        const SizedBox(height: 12),
        _buildTextField(controller.jobCtrl, 'Nghề nghiệp', Icons.work_outline, isDark),
        const SizedBox(height: 12),
        _buildTextField(controller.bioCtrl, 'Giới thiệu bản thân', Icons.info_outline, isDark, maxLines: 3),
        const SizedBox(height: 12),
        _buildTextField(controller.locationCtrl, 'Thành phố', Icons.location_on_outlined, isDark),
      ],
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, bool isDark, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildHobbies(EditProfileController controller, bool isDark) {
    final List<Map<String, dynamic>> hobbies = [
      {'icon': Icons.music_note, 'label': 'Âm nhạc'},
      {'icon': Icons.movie_outlined, 'label': 'Phim ảnh'},
      {'icon': Icons.fitness_center, 'label': 'Gym'},
      {'icon': Icons.flight_takeoff, 'label': 'Du lịch'},
      {'icon': Icons.book_outlined, 'label': 'Đọc sách'},
      {'icon': Icons.restaurant_menu, 'label': 'Nấu ăn'},
      {'icon': Icons.videogame_asset_outlined, 'label': 'Gaming'},
      {'icon': Icons.pets_outlined, 'label': 'Thú cưng'},
      {'icon': Icons.palette_outlined, 'label': 'Nghệ thuật'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: hobbies.map((h) {
        return Obx(() {
          final selected = controller.selectedHobbies.contains(h['label']);
          return GestureDetector(
            onTap: () => controller.toggleHobby(h['label']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : (isDark ? Colors.white10 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? AppColors.primary : (isDark ? Colors.white10 : Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(h['icon'], size: 16, color: selected ? Colors.white : Colors.grey),
                  const SizedBox(width: 8),
                  Text(h['label'], style: TextStyle(color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          );
        });
      }).toList(),
    );
  }
}
