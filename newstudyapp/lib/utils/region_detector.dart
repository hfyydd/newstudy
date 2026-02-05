import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// 区域检测工具
/// 用于判断用户所在地区，决定显示哪些登录方式
class RegionDetector {
  /// 中国区域代码列表
  static const List<String> chinaRegionCodes = [
    'CN', // 中国大陆
    'HK', // 香港（可选，Google 可用但用户习惯不同）
    'MO', // 澳门
    'TW', // 台湾（可选，Google 可用）
  ];

  /// 是否为中国区域（严格模式，仅中国大陆）
  static bool get isChinaStrict {
    return _getRegionCode() == 'CN';
  }

  /// 是否为中国区域（宽松模式，包括港澳台）
  static bool get isChinaLoose {
    final regionCode = _getRegionCode();
    return chinaRegionCodes.contains(regionCode);
  }

  /// 是否应该隐藏 Google Sign-In
  /// 默认使用严格模式（仅中国大陆）
  static bool get shouldHideGoogleSignIn {
    return isChinaStrict;
  }

  /// 是否应该显示微信登录
  static bool get shouldShowWeChatLogin {
    return isChinaStrict;
  }

  /// 是否应该显示手机号登录
  static bool get shouldShowPhoneLogin {
    // 中国、印度、东南亚等地区
    final regionCode = _getRegionCode();
    return ['CN', 'IN', 'SG', 'MY', 'TH', 'VN', 'ID', 'PH'].contains(regionCode);
  }

  /// 获取系统区域代码
  static String _getRegionCode() {
    try {
      // 方法1: 从系统 Locale 获取（最可靠）
      final locale = Get.deviceLocale;
      if (locale != null) {
        // 尝试从 Locale 获取国家代码
        final countryCode = locale.countryCode;
        if (countryCode != null && countryCode.isNotEmpty) {
          return countryCode.toUpperCase();
        }
      }

      // 方法2: 从系统语言代码推断（备用）
      if (locale != null) {
        final languageCode = locale.languageCode.toLowerCase();
        // 如果语言是中文，且没有明确的区域代码，可能是中国
        if (languageCode == 'zh') {
          // 检查是否是简体中文（zh_CN）
          final localeString = locale.toString();
          if (localeString.contains('CN') || localeString == 'zh') {
            return 'CN';
          }
        }
      }

      // 方法3: 从平台特定方法获取（需要平台通道）
      return _getRegionCodeFromPlatform();
    } catch (e) {
      debugPrint('获取区域代码失败: $e');
      return 'UNKNOWN';
    }
  }

  /// 从平台特定方法获取区域代码
  static String _getRegionCodeFromPlatform() {
    try {
      if (Platform.isAndroid) {
        // Android: 可以通过 Java 代码获取
        // 需要在 Android 端实现 MethodChannel
        return 'UNKNOWN';
      } else if (Platform.isIOS) {
        // iOS: 可以通过 Swift 代码获取
        // 需要在 iOS 端实现 MethodChannel
        return 'UNKNOWN';
      }
    } catch (e) {
      debugPrint('平台特定区域检测失败: $e');
    }
    return 'UNKNOWN';
  }

  /// 获取当前区域代码（公开方法）
  static String getCurrentRegionCode() {
    return _getRegionCode();
  }

  /// 调试：打印区域信息
  static void debugPrintRegionInfo() {
    final regionCode = _getRegionCode();
    final locale = Get.deviceLocale;
    debugPrint('=== 区域检测信息 ===');
    debugPrint('区域代码: $regionCode');
    debugPrint('系统 Locale: $locale');
    debugPrint('是否为中国（严格）: $isChinaStrict');
    debugPrint('是否为中国（宽松）: $isChinaLoose');
    debugPrint('隐藏 Google Sign-In: $shouldHideGoogleSignIn');
    debugPrint('显示微信登录: $shouldShowWeChatLogin');
    debugPrint('显示手机号登录: $shouldShowPhoneLogin');
    debugPrint('==================');
  }
}
