import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 支持的语言列表
class SupportedLanguage {
  final String code;
  final String name;
  final String nativeName;
  final Locale locale;

  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.locale,
  });
}

/// 语言控制器 - 管理应用的多语言设置
class LanguageController extends GetxController {
  static const String _languageKey = 'app_language';

  /// 支持的语言列表
  static const List<SupportedLanguage> supportedLanguages = [
    SupportedLanguage(
      code: 'zh',
      name: 'Chinese (Simplified)',
      nativeName: '简体中文',
      locale: Locale('zh'),
    ),
    SupportedLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      locale: Locale('en'),
    ),
    SupportedLanguage(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      locale: Locale('es'),
    ),
  ];

  /// 当前语言代码
  final RxString currentLanguageCode = 'zh'.obs;

  /// 当前 Locale
  Rx<Locale> get currentLocale => Rx<Locale>(
        supportedLanguages
            .firstWhere(
              (lang) => lang.code == currentLanguageCode.value,
              orElse: () => supportedLanguages.first,
            )
            .locale,
      );

  /// 获取当前语言信息
  SupportedLanguage get currentLanguage => supportedLanguages.firstWhere(
        (lang) => lang.code == currentLanguageCode.value,
        orElse: () => supportedLanguages.first,
      );

  @override
  void onInit() {
    super.onInit();
    _loadLanguage();
  }

  /// 从本地存储加载语言设置
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);

      if (savedLanguage != null &&
          supportedLanguages.any((lang) => lang.code == savedLanguage)) {
        // 用户在app内设置过语言，使用用户设置的语言
        currentLanguageCode.value = savedLanguage;
      } else {
        // 没有保存的语言设置，根据系统语言决定
        final systemLocale = Get.deviceLocale;
        if (systemLocale != null) {
          // 检查系统语言是否在支持的语言列表中（中文、英语、西班牙语）
          final matchedLanguage = supportedLanguages.firstWhere(
            (lang) =>
                lang.locale.languageCode == systemLocale.languageCode,
            orElse: () => supportedLanguages[1], // 不支持的语言默认使用英语（index 1）
          );
          currentLanguageCode.value = matchedLanguage.code;
        } else {
          // 无法获取系统语言，默认使用英语
          currentLanguageCode.value = 'en';
        }
      }

      // 更新应用语言
      _updateLocale();
    } catch (e) {
      debugPrint('加载语言设置失败: $e');
      // 出错时默认使用英语
      currentLanguageCode.value = 'en';
    }
  }

  /// 切换语言
  Future<void> changeLanguage(String languageCode) async {
    if (!supportedLanguages.any((lang) => lang.code == languageCode)) {
      debugPrint('不支持的语言代码: $languageCode');
      return;
    }

    currentLanguageCode.value = languageCode;

    // 保存到本地
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
    } catch (e) {
      debugPrint('保存语言设置失败: $e');
    }

    // 更新应用语言
    _updateLocale();
  }

  /// 更新应用 Locale
  void _updateLocale() {
    final language = currentLanguage;
    Get.updateLocale(language.locale);
  }

  /// 获取当前语言代码（用于 API 请求）
  String getLanguageCodeForApi() {
    return currentLanguageCode.value;
  }
}
