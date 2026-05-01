import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/register_controller.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final controller = Get.put(RegisterController());
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  void _onRegister() {
    controller.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      bio: _bioCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF4B6E), Color(0xFFFF8E9B), Color(0xFFFFC1CC)],
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
                  "Tao tai khoan",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 30),

                _field(_nameCtrl, "Ho ten", Icons.person_outline),
                const SizedBox(height: 12),
                _field(_emailCtrl, "Email", Icons.email_outlined),
                const SizedBox(height: 12),
                
                Obx(() => _field(
                  _passCtrl, "Mat khau", Icons.lock_outline,
                  obscure: controller.obscurePass.value,
                  suffix: IconButton(
                    icon: Icon(
                      controller.obscurePass.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white70,
                    ),
                    onPressed: controller.toggleObscure,
                  ),
                )),
                const SizedBox(height: 12),

                // Gender Selection
                _buildOptionTile(
                  icon: Icons.people_outline,
                  label: "Gioi tinh",
                  trailing: Obx(() => Row(
                    children: [
                      _genderBtn("Nam"),
                      const SizedBox(width: 8),
                      _genderBtn("Nu"),
                    ],
                  )),
                ),
                const SizedBox(height: 12),

                // Age Selection
                _buildOptionTile(
                  icon: Icons.cake_outlined,
                  label: "Tuoi",
                  trailing: Row(
                    children: [
                      _circleBtn(Icons.remove, controller.decrementAge),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Obx(() => Text(
                          "${controller.age.value}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        )),
                      ),
                      _circleBtn(Icons.add, controller.incrementAge),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                _field(_bioCtrl, "Gioi thieu", Icons.info_outline, maxLines: 2),
                const SizedBox(height: 12),

                // City Picker
                GestureDetector(
                  onTap: () => _showCityPicker(context),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white54),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_city_outlined, color: Colors.white70),
                        const SizedBox(width: 10),
                        Obx(() => Text(
                          controller.selectedCity.value.isEmpty ? "Chon thanh pho" : controller.selectedCity.value,
                          style: const TextStyle(color: Colors.white),
                        )),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _onRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF4B6E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Dang ky", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text("Da co tai khoan? Dang nhap", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _genderBtn(String g) {
    final isSelected = controller.gender.value == g;
    return GestureDetector(
      onTap: () => controller.updateGender(g),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          g,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF4B6E) : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white24,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildOptionTile({required IconData icon, required String label, required Widget trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.white)),
          const Spacer(),
          trailing,
        ],
      ),
    );
  }

  void _showCityPicker(BuildContext context) {
    if (controller.cities.isEmpty) {
      AppHelpers.showError("Khong co du lieu thanh pho");
      return;
    }
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Chon thanh pho", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: controller.cities.length,
                itemBuilder: (ctx, i) => ListTile(
                  title: Text(controller.cities[i]),
                  onTap: () {
                    controller.setCity(controller.cities[i]);
                    Get.back();
                  },
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {bool obscure = false, Widget? suffix, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white54), borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
