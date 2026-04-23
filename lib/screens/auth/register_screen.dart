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
  final _bioCtrl = TextEditingController();

  String _gender = 'Nam';
  String? _selectedCity;
  List<String> _cities = [];

  bool _loading = false;
  bool _loadingCities = true;
  bool _obscurePass = true;

  int _age = 18;

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
        _selectedCity == null) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng điền đầy đủ thông tin!',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_age < 18) {
      Get.snackbar(
        'Không đủ tuổi',
        'Bạn phải đủ 18 tuổi',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final pass = _passCtrl.text;

    if (pass.length < 6 ||
        !pass.contains(RegExp(r'[A-Z]')) ||
        !pass.contains(RegExp(r'[0-9]'))) {
      Get.snackbar(
        'Lỗi',
        'Mật khẩu phải có ít nhất 6 ký tự, 1 chữ hoa và 1 số',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final credential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: pass,
      );

      final uid = credential.user!.uid;

      final newUser = UserModel(
        uid: uid,
        name: _nameCtrl.text.trim(),
        age: _age,
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
      Get.snackbar(
        'Lỗi',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          children: _cities.map((city) {
            return ListTile(
              title: Text(city),
              onTap: () {
                setState(() => _selectedCity = city);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFF4B6E),
              Color(0xFFFF8E9B),
              Color(0xFFFFC1CC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  "💕 Tạo tài khoản",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

                _field(_nameCtrl, "Họ tên", Icons.person),
                const SizedBox(height: 12),

                _field(_emailCtrl, "Email", Icons.email),
                const SizedBox(height: 12),

                _field(
                  _passCtrl,
                  "Mật khẩu",
                  Icons.lock,
                  obscure: _obscurePass,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white70,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePass = !_obscurePass;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.white70),
                      const SizedBox(width: 10),
                      const Text(
                        "Giới tính",
                        style: TextStyle(color: Colors.white),
                      ),
                      const Spacer(),

                      GestureDetector(
                        onTap: () => setState(() => _gender = 'Nam'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _gender == 'Nam'
                                ? Colors.white
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Nam",
                            style: TextStyle(
                              color: _gender == 'Nam'
                                  ? const Color(0xFFFF4B6E)
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      GestureDetector(
                        onTap: () => setState(() => _gender = 'Nữ'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _gender == 'Nữ'
                                ? Colors.white
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Nữ",
                            style: TextStyle(
                              color: _gender == 'Nữ'
                                  ? const Color(0xFFFF4B6E)
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                   padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake, color: Colors.white70),
                      const SizedBox(width: 10),
                      const Text(
                        "Tuổi",
                        style: TextStyle(color: Colors.white),
                      ),
                      const Spacer(),

                      GestureDetector(
                        onTap: () {
                          if (_age > 18) {
                            setState(() => _age--);
                          }
                        },
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.remove, color: Colors.white),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "$_age",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          if (_age < 99) {
                            setState(() => _age++);
                          }
                        },
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _field(_bioCtrl, "Giới thiệu", Icons.info, maxLines: 3),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: _showCityPicker,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_city,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _selectedCity ?? "Chọn thành phố",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF4B6E),
                      elevation: 4,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFFFF4B6E),
                      ),
                    )
                        : const Text(
                      "Đăng ký",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text(
                    "Đã có tài khoản?",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        bool obscure = false,
        Widget? suffix,
        int maxLines = 1,
      }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffix,
        labelStyle: const TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }
}