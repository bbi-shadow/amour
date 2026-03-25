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
  // Controller để lấy dữ liệu từ các ô nhập liệu
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  // Giới tính mặc định
  String _gender = 'Nam';

  // Trạng thái đang loading hay không
  bool _loading = false;

  // Hàm đăng ký tài khoản
  Future<void> _register() async {
    // Kiểm tra các ô không được để trống
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _ageCtrl.text.isEmpty ||
        _cityCtrl.text.isEmpty) {
      Get.snackbar(
        'Lỗi',
        'Vui lòng điền đầy đủ thông tin!',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Bật loading
    setState(() => _loading = true);

    try {
      // Bước 1: Tạo tài khoản trên Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      // Bước 2: Lấy uid vừa tạo
      final uid = credential.user!.uid;

      // Bước 3: Tạo object UserModel
      final newUser = UserModel(
        uid: uid,
        name: _nameCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        gender: _gender,
        bio: _bioCtrl.text.trim(),
        photoUrl: '', // Chưa có ảnh, để trống
        city: _cityCtrl.text.trim(),
      );

      // Bước 4: Lưu thông tin user vào Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(newUser.toMap());

      // Bước 5: Chuyển sang màn hình Home
      Get.offAll(() => HomeScreen());

    } catch (e) {
      // Hiện thông báo lỗi nếu đăng ký thất bại
      Get.snackbar(
        'Đăng ký thất bại',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    // Tắt loading
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Nền gradient màu hồng
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF4B6E), Color(0xFFFF8E9B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            // Cho phép cuộn khi bàn phím hiện lên
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                SizedBox(height: 20),

                // Tiêu đề
                Text(
                  '💕 Tạo tài khoản',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tìm kiếm tình yêu của bạn',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 32),

                // Ô nhập Tên
                _buildTextField(
                  controller: _nameCtrl,
                  label: 'Họ và tên',
                  icon: Icons.person,
                ),
                SizedBox(height: 16),

                // Ô nhập Email
                _buildTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),

                // Ô nhập Mật khẩu
                _buildTextField(
                  controller: _passCtrl,
                  label: 'Mật khẩu',
                  icon: Icons.lock,
                  isPassword: true,
                ),
                SizedBox(height: 16),

                // Ô nhập Tuổi
                _buildTextField(
                  controller: _ageCtrl,
                  label: 'Tuổi',
                  icon: Icons.cake,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),

                // Ô nhập Thành phố
                _buildTextField(
                  controller: _cityCtrl,
                  label: 'Thành phố',
                  icon: Icons.location_city,
                ),
                SizedBox(height: 16),

                // Ô nhập Bio
                _buildTextField(
                  controller: _bioCtrl,
                  label: 'Giới thiệu bản thân',
                  icon: Icons.info,
                  maxLines: 3,
                ),
                SizedBox(height: 16),

                // Chọn giới tính
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people, color: Colors.white70),
                      SizedBox(width: 12),
                      Text('Giới tính:', style: TextStyle(color: Colors.white)),
                      SizedBox(width: 16),

                      // Radio button Nam
                      Row(
                        children: [
                          Radio<String>(
                            value: 'Nam',
                            groupValue: _gender,
                            onChanged: (val) => setState(() => _gender = val!),
                            fillColor: MaterialStateProperty.all(Colors.white),
                          ),
                          Text('Nam', style: TextStyle(color: Colors.white)),
                        ],
                      ),

                      // Radio button Nữ
                      Row(
                        children: [
                          Radio<String>(
                            value: 'Nữ',
                            groupValue: _gender,
                            onChanged: (val) => setState(() => _gender = val!),
                            fillColor: MaterialStateProperty.all(Colors.white),
                          ),
                          Text('Nữ', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 28),

                // Nút đăng ký
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFFFF4B6E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _loading
                        ? CircularProgressIndicator(color: Color(0xFFFF4B6E))
                        : Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Chuyển về màn hình đăng nhập
                TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    'Đã có tài khoản? Đăng nhập',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget tái sử dụng cho các ô nhập liệu
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
      obscureText: isPassword,         // Ẩn mật khẩu nếu isPassword = true
      keyboardType: keyboardType,      // Loại bàn phím (số, email, text...)
      maxLines: maxLines,              // Số dòng tối đa
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  // Giải phóng bộ nhớ khi widget bị xóa
  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _ageCtrl.dispose();
    _bioCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }
}