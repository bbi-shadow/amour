import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '/models/user_model.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  String _gender = 'Nam';
  String? _selectedCity;
  List<String> _cities = [];
  bool _loading = false;
  bool _loadingCities = true;
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final snap = await FirebaseFirestore.instance
        .collection('cities')
        .orderBy('name')
        .get();

    setState(() {
      _cities = snap.docs
          .map((d) => d.data()['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
      _loadingCities = false;
    });
  }

  Future<void> _register() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _ageCtrl.text.isEmpty ||
        _selectedCity == null) {
      Get.snackbar('Lỗi', 'Vui lòng điền đầy đủ thông tin!',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // ✅ FIX: validate tuổi >= 18
    final age = int.tryParse(_ageCtrl.text.trim());
    if (age == null) {
      Get.snackbar('Lỗi', 'Tuổi không hợp lệ',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (age < 18) {
      Get.snackbar('Không đủ tuổi', 'Bạn phải đủ 18 tuổi để đăng ký',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    if (age > 99) {
      Get.snackbar('Tuổi không hợp lệ', 'Vui lòng nhập tuổi hợp lệ',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // Validate password
    final pass = _passCtrl.text;
    if (pass != pass.trim()) {
      Get.snackbar('Lỗi', 'Mật khẩu không được có khoảng trắng đầu/cuối',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (pass.length < 6) {
      Get.snackbar('Lỗi', 'Mật khẩu tối thiểu 6 ký tự',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (!pass.contains(RegExp(r'[A-Z]'))) {
      Get.snackbar('Lỗi', 'Mật khẩu phải có ít nhất 1 chữ hoa',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (!pass.contains(RegExp(r'[0-9]'))) {
      Get.snackbar('Lỗi', 'Mật khẩu phải có ít nhất 1 chữ số',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      final uid = credential.user!.uid;

      final newUser = UserModel(
        uid: uid,
        name: _nameCtrl.text.trim(),
        age: age, // ✅ dùng biến đã validate
        gender: _gender,
        bio: _bioCtrl.text.trim(),
        photoUrl: '',
        city: _selectedCity!,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(newUser.toMap());

      Get.offAll(() => HomeScreen());
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('email-already-in-use'))
        msg = 'Email này đã được đăng ký';
      if (msg.contains('invalid-email')) msg = 'Email không hợp lệ';
      Get.snackbar('Đăng ký thất bại', msg,
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
                    child: const Icon(Icons.close, color: Colors.white),
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
                      textAlign: TextAlign.center,
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
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF4B6E)
                            .withOpacity(0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF4B6E), Color(0xFFFF8E9B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text('💕 Tạo tài khoản',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                const Text('Tìm kiếm tình yêu của bạn',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 32),

                _buildTextField(
                    controller: _nameCtrl, label: 'Họ và tên', icon: Icons.person),
                const SizedBox(height: 16),

                _buildTextField(
                    controller: _emailCtrl,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),

                // ✅ Thêm toggle show/hide password
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Tối thiểu 6 ký tự, 1 chữ hoa, 1 số',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePass ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white54)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: Colors.white, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ FIX: Hint về tuổi tối thiểu 18
                _buildTextField(
                    controller: _ageCtrl,
                    label: 'Tuổi (tối thiểu 18)',
                    icon: Icons.cake,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),

                _buildTextField(
                    controller: _bioCtrl,
                    label: 'Giới thiệu bản thân',
                    icon: Icons.info,
                    maxLines: 3),
                const SizedBox(height: 16),

                // Chọn thành phố
                GestureDetector(
                  onTap: _showCityPicker,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedCity != null
                            ? Colors.white
                            : Colors.white54,
                        width: _selectedCity != null ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_city,
                            color: _selectedCity != null
                                ? Colors.white
                                : Colors.white70),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedCity ?? 'Chọn thành phố',
                            style: TextStyle(
                                color: _selectedCity != null
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 16),
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            color: _selectedCity != null
                                ? Colors.white
                                : Colors.white70),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Chọn giới tính
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.people, color: Colors.white70),
                    const SizedBox(width: 12),
                    const Text('Giới tính:',
                        style: TextStyle(color: Colors.white)),
                    const SizedBox(width: 16),
                    _genderOption('👨 Nam', 'Nam'),
                    const SizedBox(width: 8),
                    _genderOption('👩 Nữ', 'Nữ'),
                  ]),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFFFF4B6E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(
                        color: Color(0xFFFF4B6E))
                        : const Text('Đăng ký',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Đã có tài khoản? Đăng nhập',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white54),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFF4B6E) : Colors.white,
              fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
            )),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _ageCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }
}