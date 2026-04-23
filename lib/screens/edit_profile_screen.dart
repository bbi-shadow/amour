import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../services/firestore_service.dart';
import '../../services/upload_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  
  List<String?> _photoUrls = List.filled(6, null);
  List<File?> _newFiles = List.filled(6, null);
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _shareToFeed = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await FirestoreService.getUser(_uid);
      if (user != null) {
        _nameCtrl.text = user.name;
        _bioCtrl.text = user.bio;
        List<String> userPhotos = List.from(user.photos);
        for (int i = 0; i < 6; i++) {
          if (i < userPhotos.length) _photoUrls[i] = userPhotos[i];
        }
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  // ✅ Sửa lại hàm để có thể chọn Máy ảnh
  Future<void> _pickPhoto(int index) async {
    final picker = ImagePicker();
    
    // Hiện lựa chọn nguồn ảnh
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Text("Chọn nguồn ảnh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text("Chụp ảnh ngay"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text("Chọn từ thư viện"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (source != null) {
      final picked = await picker.pickImage(source: source, imageQuality: 70);
      if (picked != null) {
        setState(() => _newFiles[index] = File(picked.path));
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photoUrls[index] = null;
      _newFiles[index] = null;
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      Get.snackbar("Lỗi", "Vui lòng nhập tên", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _isSaving = true);
    try {
      List<String> finalUrls = [];
      for (int i = 0; i < 6; i++) {
        if (_newFiles[i] != null) {
          String? url = await UploadService.uploadImage(_newFiles[i]!);
          if (url != null) finalUrls.add(url);
        } else if (_photoUrls[i] != null) {
          finalUrls.add(_photoUrls[i]!);
        }
      }

      final mainPhoto = finalUrls.isNotEmpty ? finalUrls.first : "";

      await FirestoreService.updateProfile(_uid, {
        'name': _nameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'photoUrl': mainPhoto,
        'photos': finalUrls,
      });

      if (_shareToFeed && mainPhoto.isNotEmpty) {
        await FirestoreService.createPost(
          content: "Mình vừa cập nhật ảnh hồ sơ mới! ✨",
          imageUrl: mainPhoto,
        );
      }

      AppHelpers.showSuccess("Đã cập nhật hồ sơ!");
      Navigator.pop(context);
    } catch (e) {
      AppHelpers.showError("Lỗi khi lưu dữ liệu");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          _isSaving 
            ? const Center(child: Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
            : TextButton(onPressed: _save, child: const Text('Xong', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16))),
        ],
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ảnh hồ sơ (Tối đa 6 ảnh)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildPhotoGrid(),
            const SizedBox(height: 30),
            _buildTextField("Tên hiển thị", _nameCtrl, "Nhập tên của bạn"),
            const SizedBox(height: 20),
            _buildTextField("Tiểu sử", _bioCtrl, "Kể gì đó thú vị về bạn...", maxLines: 4),
            const SizedBox(height: 30),
            _buildShareOption(),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          const Icon(Icons.rss_feed, color: Colors.blue),
          const SizedBox(width: 12),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Chia sẻ lên Threads", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Thông báo cập nhật cho mọi người", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )),
          Switch(
            value: _shareToFeed, 
            onChanged: (v) => setState(() => _shareToFeed = v),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.8),
      itemCount: 6,
      itemBuilder: (context, i) {
        final hasLocal = _newFiles[i] != null;
        final hasRemote = _photoUrls[i] != null;
        return GestureDetector(
          onTap: () => _pickPhoto(i),
          child: Stack(children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100], borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
                image: hasLocal 
                  ? DecorationImage(image: FileImage(_newFiles[i]!), fit: BoxFit.cover)
                  : (hasRemote ? DecorationImage(image: NetworkImage(_photoUrls[i]!), fit: BoxFit.cover) : null),
              ),
              child: (!hasLocal && !hasRemote) ? const Center(child: Icon(Icons.add_a_photo, color: Colors.grey)) : null,
            ),
            if (hasLocal || hasRemote)
              Positioned(top: 5, right: 5, child: GestureDetector(
                onTap: () => _removePhoto(i), 
                child: const CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)))),
          ]),
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
        TextField(
          controller: ctrl, maxLines: maxLines,
          decoration: InputDecoration(hintText: hint, border: const UnderlineInputBorder()),
        ),
      ],
    );
  }
}
