import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/register_controller.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final controller = Get.put(RegisterController());
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _bioCtrl   = TextEditingController();

  void _onRegister() {
    controller.register(
      name:     _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
      bio:      _bioCtrl.text.trim(),
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ────────────────────────────────────────────
                const SizedBox(height: 8),
                const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 44),
                const SizedBox(height: 12),
                const Text(
                  'Tạo tài khoản',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Hãy bắt đầu hành trình của bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 28),

                // ── Họ tên ────────────────────────────────────────────
                _field(_nameCtrl, 'Họ tên', Icons.person_outline),
                const SizedBox(height: 12),

                // ── Email ─────────────────────────────────────────────
                _field(_emailCtrl, 'Email', Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),

                // ── Mật khẩu ──────────────────────────────────────────
                Obx(() => _field(
                  _passCtrl, 'Mật khẩu', Icons.lock_outline,
                  obscure: controller.obscurePass.value,
                  suffix: IconButton(
                    icon: Icon(
                      controller.obscurePass.value
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white70,
                    ),
                    onPressed: controller.toggleObscure,
                  ),
                )),
                const SizedBox(height: 12),

                // ── Giới thiệu ────────────────────────────────────────
                _field(_bioCtrl, 'Giới thiệu bản thân',
                    Icons.info_outline,
                    maxLines: 2),
                const SizedBox(height: 16),

                // ── Giới tính ─────────────────────────────────────────
                _sectionLabel('Giới tính'),
                const SizedBox(height: 8),
                Obx(() => Row(
                  children: ['Nam', 'Nữ', 'Khác']
                      .map((g) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _genderBtn(g),
                    ),
                  ))
                      .toList(),
                )),
                const SizedBox(height: 16),

                // ── Tuổi ──────────────────────────────────────────────
                _sectionLabel('Tuổi'),
                const SizedBox(height: 8),
                _buildAgePicker(),
                const SizedBox(height: 16),

                // ── Thành phố ─────────────────────────────────────────
                _sectionLabel('Thành phố'),
                const SizedBox(height: 8),
                _buildCityPicker(context),
                const SizedBox(height: 28),

                // ── Nút đăng ký ───────────────────────────────────────
                Obx(() => SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: controller.isLoadingCities.value
                        ? null
                        : _onRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF4B6E),
                      disabledBackgroundColor: Colors.white54,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Đăng Ký',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
                const SizedBox(height: 16),

                // ── Quay lại ──────────────────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'Đã có tài khoản? Đăng nhập',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Age picker ─────────────────────────────────────────────────────────────
  Widget _buildAgePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white12,
        border: Border.all(color: Colors.white54),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cake_outlined, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Tuổi của bạn',
                style: TextStyle(color: Colors.white70, fontSize: 15)),
          ),
          _circleBtn(Icons.remove, controller.decrementAge),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Obx(() => Text(
              '${controller.age.value}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            )),
          ),
          _circleBtn(Icons.add, controller.incrementAge),
        ],
      ),
    );
  }

  // ── City picker trigger ────────────────────────────────────────────────────
  Widget _buildCityPicker(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isLoadingCities.value;
      final selected  = controller.selectedCity.value;

      return GestureDetector(
        onTap: isLoading ? null : () => _showCityPicker(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            // FIX: dùng white12 (trong suốt) thay vì Colors.white (đục trắng)
            color: Colors.white12,
            border: Border.all(
              color: selected.isNotEmpty ? Colors.white : Colors.white54,
              width: selected.isNotEmpty ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                selected.isNotEmpty
                    ? Icons.location_on
                    : Icons.location_city_outlined,
                // FIX: icon placeholder dùng white70, icon đã chọn dùng white
                color: selected.isNotEmpty ? Colors.white : Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLoading
                      ? 'Đang tải danh sách thành phố...'
                      : selected.isEmpty
                      ? 'Chọn thành phố'
                      : selected,
                  style: TextStyle(
                    // FIX: placeholder/loading dùng white70, đã chọn dùng white
                    color: (isLoading || selected.isEmpty)
                        ? Colors.white70
                        : Colors.white,
                    fontSize: 15,
                    fontWeight: selected.isNotEmpty
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white70, strokeWidth: 2),
                )
              else
                Icon(
                  selected.isNotEmpty
                      ? Icons.check_circle
                      : Icons.arrow_drop_down,
                  // FIX: arrow dùng white70, check dùng white
                  color: selected.isNotEmpty ? Colors.white : Colors.white70,
                ),
            ],
          ),
        ),
      );
    });
  }

  // ── Bottom sheet city list ─────────────────────────────────────────────────
  void _showCityPicker(BuildContext context) {
    if (controller.cities.isEmpty) {
      AppHelpers.showError(
          'Chưa có thành phố nào. Vui lòng liên hệ quản trị viên.');
      return;
    }

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.62,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Text(
              'Chọn thành phố',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Thành phố bạn đang sinh sống',
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),

            // List
            Expanded(
              child: Obx(() => ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: controller.cities.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 56),
                itemBuilder: (ctx, i) {
                  final city = controller.cities[i];
                  final isSelected =
                      controller.selectedCity.value == city;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isSelected
                          ? AppColors.primary.withOpacity(0.12)
                          : Colors.grey.shade100,
                      child: Text(
                        city.isNotEmpty
                            ? city[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(
                      city,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.black87,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                        color: AppColors.primary)
                        : null,
                    onTap: () {
                      controller.setCity(city);
                      Get.back();
                    },
                  );
                },
              )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Shared widgets ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3),
  );

  Widget _genderBtn(String g) {
    final isSelected = controller.gender.value == g;
    return GestureDetector(
      onTap: () => controller.updateGender(g),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white12,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white54),
        ),
        child: Center(
          child: Text(
            g,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFFF4B6E)
                  : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
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
        child: Icon(icon, color: Colors.white, size: 18),
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
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white12,
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white54),
            borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
            borderSide:
            const BorderSide(color: Colors.white, width: 1.5),
            borderRadius: BorderRadius.circular(12)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}