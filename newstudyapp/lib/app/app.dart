import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/config/app_config.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:newstudyapp/config/theme_controller.dart';
import 'package:newstudyapp/config/language_controller.dart';
import 'package:newstudyapp/routes/app_pages.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化主题控制器
    final themeController = Get.put(ThemeController());
    // 初始化语言控制器
    final languageController = Get.put(LanguageController());
    
    return Obx(() => GetMaterialApp(
      title: AppConfig.appTitle,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      
      // 国际化配置
      locale: languageController.currentLanguage.locale,
      fallbackLocale: const Locale('en'),
      supportedLocales: const [
        Locale('zh'),  // 简体中文
        Locale('en'),  // 英语
        Locale('es'),  // 西班牙语
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ));
  }
}
