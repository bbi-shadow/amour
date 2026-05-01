import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ══════════════════════════════════════════════════════════════
/// ThemeController — Quản lý Dark/Light Mode toàn app
/// Dùng GetX Reactive + SharedPreferences để lưu lựa chọn
/// ══════════════════════════════════════════════════════════════
class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  static const _key = 'isDarkMode';

  // Trạng thái reactive
  final _isDark = false.obs;

  bool get isDark => _isDark.value;
  ThemeMode get themeMode => _isDark.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _loadFromPrefs();
  }

  /// Tải từ SharedPreferences khi khởi động
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark.value = prefs.getBool(_key) ?? false;
    _applyTheme();
  }

  /// Toggle dark/light — gọi từ Settings hoặc bất kỳ widget nào
  Future<void> toggleTheme() async {
    _isDark.value = !_isDark.value;
    _applyTheme();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark.value);
  }

  /// Set trực tiếp (dùng cho Switch)
  Future<void> setDark(bool value) async {
    if (_isDark.value == value) return;
    _isDark.value = value;
    _applyTheme();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  void _applyTheme() {
    Get.changeThemeMode(_isDark.value ? ThemeMode.dark : ThemeMode.light);
  }
}