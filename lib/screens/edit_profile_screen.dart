import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '/services/database_helper.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _user = FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;
  final _picker = ImagePicker();

  final _nameController = TextEditingController();
  final _bioController = TextEditingController();

  File? _selectedImage;
  String? _savedPhotoPath;
  int _age = 25;                   // ← stepper, không còn TextController
  String _gender = 'Nam';
  String? _selectedCity;
  List<String> _cities = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _loadingCities = true;
  bool _longPressing = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.07).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadProfile();
    _loadCities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Load cities ──────────────────────────────────────────
  Future<void> _loadCities() async {
    try {
      final snap =
      await _firestore.collection('cities').orderBy('name').get();
      setState(() {
        _cities = snap.docs
            .map((d) => d.data()['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
        _loadingCities = false;
      });
    } catch (_) {
      setState(() => _loadingCities = false);
    }
  }

  // ── Load profile ─────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final local = await DatabaseHelper.getProfile(_user!.uid);
      if (local != null) {
        _nameController.text = local['name'] ?? '';
        _bioController.text = local['bio'] ?? '';
        setState(() {
          _age = (local['age'] as int?) ?? 25;
          _savedPhotoPath = local['photo_path'];
          _gender = local['gender'] ?? 'Nam';
          _selectedCity = (local['city'] as String?)?.isNotEmpty == true
              ? local['city']
              : null;
        });
      } else {
        final doc =
        await _firestore.collection('users').doc(_user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _nameController.text = data['name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          setState(() {
            _age = (data['age'] as int?) ?? 25;
            _gender = data['gender'] ?? 'Nam';
            final city = data['city']?.toString() ?? '';
            _selectedCity = city.isNotEmpty ? city : null;
          });
        }
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tải hồ sơ: $e',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Image picker ─────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
          source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
        _pulseCtrl
            .forward()
            .then((_) => _pulseCtrl.reverse());
      }
    } catch (_) {
      Get.snackbar('Lỗi', 'Không thể chọn ảnh',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Cập nhật ảnh đại diện',
                style:
                TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _sourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Thư viện',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _sourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── City picker ──────────────────────────────────────────
  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFFFF4B6E), Color(0xFFFF8E9B)]),
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_city, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Chọn thành phố',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child:
                    const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loadingCities
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFFF4B6E)))
                  : _cities.isEmpty
                  ? const Center(
                  child: Text('Chưa có thành phố nào!',
                      style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _cities.length,
                itemBuilder: (context, index) {
                  final city = _cities[index];
                  final isSelected = _selectedCity == city;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCity = city);
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin:
                      const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF4B6E)
                            .withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF4B6E)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF4B6E)
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.location_on,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Text(city,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFFFF4B6E)
                                    : Colors.black87,
                              )),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: Color(0xFFFF4B6E)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Age stepper logic ────────────────────────────────────
  void _changeAge(int delta) {
    final next = _age + delta;
    if (next < 18 || next > 99) return;
    HapticFeedback.lightImpact();
    setState(() => _age = next);
  }

  void _startLongPress(int delta) {
    _longPressing = true;
    _runLongPress(delta);
  }

  void _stopLongPress() => _longPressing = false;

  Future<void> _runLongPress(int delta) async {
    await Future.delayed(const Duration(milliseconds: 300));
    while (_longPressing) {
      _changeAge(delta);
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  // ── Save ─────────────────────────────────────────────────
  Future<String> _saveImageLocally(File imageFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dest = p.join(appDir.path, 'avatar_${_user!.uid}.jpg');
    await imageFile.copy(dest);
    return dest;
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      Get.snackbar('Thiếu thông tin', 'Vui lòng nhập tên hiển thị',
          backgroundColor: Colors.orange.withOpacity(0.9),
          colorText: Colors.white);
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? finalPhotoPath = _savedPhotoPath;
      if (_selectedImage != null) {
        finalPhotoPath = await _saveImageLocally(_selectedImage!);
      }

      await DatabaseHelper.saveProfile(
        uid: _user!.uid,
        name: name,
        age: _age,
        bio: bio,
        city: _selectedCity ?? '',
        gender: _gender,
        photoPath: finalPhotoPath,
      );

      await _firestore.collection('users').doc(_user.uid).set({
        'name': name,
        'age': _age,
        'bio': bio,
        'city': _selectedCity ?? '',
        'gender': _gender,
        'email': _user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Get.back();
      Get.snackbar('Đã lưu 🎉', 'Hồ sơ đã được cập nhật!',
          backgroundColor: const Color(0xFFFF4B6E).withOpacity(0.9),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể lưu hồ sơ: $e',
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          _isSaving
              ? const Padding(
            padding:
            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFFF4B6E)),
            ),
          )
              : TextButton(
            onPressed: _saveProfile,
            child: const Text('Lưu',
                style: TextStyle(
                    color: Color(0xFFFF4B6E),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF4B6E)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ─────────────────────────────
            _buildAvatarSection(),
            const SizedBox(height: 28),

            _buildSectionLabel('THÔNG TIN CÁ NHÂN'),
            const SizedBox(height: 8),

            _buildTextField(
                controller: _nameController,
                label: 'Tên hiển thị',
                hint: 'Nhập tên của bạn',
                icon: Icons.person_outline,
                maxLength: 30),
            const SizedBox(height: 12),

            _buildTextField(
                controller: _bioController,
                label: 'Giới thiệu bản thân',
                hint: 'Hãy chia sẻ một chút về bạn...',
                icon: Icons.edit_note_outlined,
                maxLines: 4,
                maxLength: 200),
            const SizedBox(height: 20),

            // ── Age stepper ────────────────────────
            _buildSectionLabel('TUỔI'),
            const SizedBox(height: 8),
            _buildAgeStepper(),
            const SizedBox(height: 20),

            // ── Gender ─────────────────────────────
            _buildSectionLabel('GIỚI TÍNH'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline,
                      color: Color(0xFFFF4B6E)),
                  const SizedBox(width: 12),
                  _genderOption('👨 Nam', 'Nam'),
                  const SizedBox(width: 8),
                  _genderOption('👩 Nữ', 'Nữ'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── City ───────────────────────────────
            _buildSectionLabel('THÀNH PHỐ'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showCityPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_city_outlined,
                        color: Color(0xFFFF4B6E)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCity ?? 'Chọn thành phố',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedCity != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4B6E),
                  disabledBackgroundColor:
                  const Color(0xFFFF4B6E).withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white),
                    ),
                    SizedBox(width: 12),
                    Text('Đang lưu...',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16)),
                  ],
                )
                    : const Text('Lưu hồ sơ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Avatar section ────────────────────────────────────────
  Widget _buildAvatarSection() {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _showImageSourceSheet,
            child: ScaleTransition(
              scale: _pulseAnim,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 130, height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4B6E), Color(0xFFFF8E53)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          const Color(0xFFFF4B6E).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(child: _buildAvatarImage()),
                  ),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFF4B6E), Color(0xFFFF8E53)]),
                      shape: BoxShape.circle,
                      border:
                      Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4B6E).withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFFF4B6E).withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded,
                      size: 13, color: Color(0xFFFF4B6E)),
                  SizedBox(width: 5),
                  Text('Thay đổi ảnh',
                      style: TextStyle(
                          color: Color(0xFFFF4B6E),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
        if (_selectedImage != null) ...[
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF4CAF50), size: 13),
              SizedBox(width: 4),
              Text('Ảnh mới đã chọn',
                  style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAvatarImage() {
    if (_selectedImage != null) {
      return Image.file(_selectedImage!, fit: BoxFit.cover,
          width: 124, height: 124);
    }
    if (_savedPhotoPath != null && _savedPhotoPath!.isNotEmpty) {
      final f = File(_savedPhotoPath!);
      if (f.existsSync()) {
        return Image.file(f, fit: BoxFit.cover, width: 124, height: 124);
      }
    }
    return Container(
      color: const Color(0xFFFF4B6E).withOpacity(0.1),
      child: const Icon(Icons.person_rounded,
          size: 64, color: Color(0xFFFF4B6E)),
    );
  }

  // ── Age stepper widget ────────────────────────────────────
  Widget _buildAgeStepper() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Nút − với long press
              _stepBtn(
                icon: Icons.remove_rounded,
                onTap: () => _changeAge(-1),
                onLongPress: () => _startLongPress(-1),
                onLongPressEnd: _stopLongPress,
                enabled: _age > 18,
              ),
              const SizedBox(width: 24),

              // Số tuổi animated
              SizedBox(
                width: 100,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Column(
                    key: ValueKey(_age),
                    children: [
                      Text(
                        '$_age',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFF4B6E),
                          height: 1,
                        ),
                      ),
                      const Text('tuổi',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 24),
              // Nút +
              _stepBtn(
                icon: Icons.add_rounded,
                onTap: () => _changeAge(1),
                onLongPress: () => _startLongPress(1),
                onLongPressEnd: _stopLongPress,
                enabled: _age < 99,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFF4B6E),
              inactiveTrackColor:
              const Color(0xFFFF4B6E).withOpacity(0.15),
              thumbColor: const Color(0xFFFF4B6E),
              overlayColor:
              const Color(0xFFFF4B6E).withOpacity(0.12),
              thumbShape:
              const RoundSliderThumbShape(enabledThumbRadius: 9),
              trackHeight: 3,
            ),
            child: Slider(
              value: _age.toDouble(),
              min: 18,
              max: 99,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _age = v.round());
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('18',
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 11)),
                Text('99',
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn({
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    required VoidCallback onLongPressEnd,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      onLongPressEnd: (_) => onLongPressEnd(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFFFF4B6E).withOpacity(0.1)
              : Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? const Color(0xFFFF4B6E).withOpacity(0.35)
                : Colors.grey[200]!,
          ),
        ),
        child: Icon(icon,
            color: enabled
                ? const Color(0xFFFF4B6E)
                : Colors.grey[300],
            size: 26),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  Widget _sourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4B6E).withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFFF4B6E).withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 50, height: 50,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF4B6E), Color(0xFFFF8E53)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _genderOption(String label, String value) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF4B6E).withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF4B6E)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFFF4B6E)
                  : Colors.black54,
              fontWeight: isSelected
                  ? FontWeight.bold
                  : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _buildSectionLabel(String label) => Text(label,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 1.2));

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFFF4B6E)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Colors.grey[600]),
          counterStyle:
          TextStyle(color: Colors.grey[400], fontSize: 11),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}