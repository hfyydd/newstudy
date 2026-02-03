import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 全局 Toast 服务（单例模式）
/// 
/// 用于在应用任何位置显示统一风格的 Toast 提示
class ToastService {
  factory ToastService() => _instance;
  static final ToastService _instance = ToastService._internal();
  ToastService._internal();

  /// 显示错误提示
  static void showError(String message, {String? title}) {
    Get.snackbar(
      title ?? '请求失败',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFFF6B6B),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: Icon(Icons.error_outline, color: Colors.white, size: 24),
      ),
      shouldIconPulse: false,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  /// 显示成功提示
  static void showSuccess(String message, {String? title}) {
    Get.snackbar(
      title ?? '成功',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF4ECDC4),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: Icon(Icons.check_circle_outline, color: Colors.white, size: 24),
      ),
      shouldIconPulse: false,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  /// 显示警告提示
  static void showWarning(String message, {String? title}) {
    Get.snackbar(
      title ?? '提示',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFFFFB347),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: Icon(Icons.warning_amber_outlined, color: Colors.white, size: 24),
      ),
      shouldIconPulse: false,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  /// 显示普通信息提示
  static void showInfo(String message, {String? title}) {
    Get.snackbar(
      title ?? '提示',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF667EEA),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: Icon(Icons.info_outline, color: Colors.white, size: 24),
      ),
      shouldIconPulse: false,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  /// 显示网络错误提示
  static void showNetworkError({String? message}) {
    showError(
      message ?? '网络连接失败，请检查网络设置',
      title: '网络错误',
    );
  }

  /// 显示服务器错误提示
  static void showServerError({int? statusCode, String? message}) {
    final errorMessage = message ?? '服务器繁忙，请稍后再试';
    showError(
      statusCode != null ? '[$statusCode] $errorMessage' : errorMessage,
      title: '服务器错误',
    );
  }

  /// 显示超时错误提示
  static void showTimeoutError({String? message}) {
    showError(
      message ?? '请求超时，请检查网络连接后重试',
      title: '请求超时',
    );
  }
}
