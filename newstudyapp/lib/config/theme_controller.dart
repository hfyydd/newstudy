import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 主题控制器
/// 使用内存存储，应用重启后会重置为默认主题
class ThemeController extends GetxController {
  final _isDarkMode = true.obs;
  // 内存存储，应用重启后会丢失
  static bool? _memoryThemeMode;
  
  bool get isDarkMode => _isDarkMode.value;
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  
  @override
  void onInit() {
    super.onInit();
    _loadThemeMode();
  }
  
  /// 加载主题模式
  void _loadThemeMode() {
    // 使用内存存储的主题模式，如果为空则使用默认值（暗色主题）
    _isDarkMode.value = _memoryThemeMode ?? true;
  }
  
  /// 切换主题
  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeThemeMode(themeMode);
    _saveThemeMode();
  }
  
  /// 设置主题
  void setTheme(bool isDark) {
    if (_isDarkMode.value != isDark) {
      _isDarkMode.value = isDark;
      Get.changeThemeMode(themeMode);
      _saveThemeMode();
    }
  }
  
  /// 保存主题模式到内存
  void _saveThemeMode() {
    _memoryThemeMode = _isDarkMode.value;
  }
}

