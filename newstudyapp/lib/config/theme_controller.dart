import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题控制器
class ThemeController extends GetxController {
  static const String _themeKey = 'app_theme_mode';
  
  final _isDarkMode = true.obs;
  
  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  
  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }
  
  /// 加载主题模式
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? true; // 默认暗色主题
      _isDarkMode.value = isDark;
    } catch (e) {
      print('加载主题模式失败: $e');
    }
  }
  
  /// 切换主题
  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeThemeMode(themeMode);
    await _saveThemeMode();
  }
  
  /// 设置主题
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode.value != isDark) {
      _isDarkMode.value = isDark;
      Get.changeThemeMode(themeMode);
      await _saveThemeMode();
    }
  }
  
  /// 保存主题模式
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode.value);
    } catch (e) {
      print('保存主题模式失败: $e');
    }
  }
}

