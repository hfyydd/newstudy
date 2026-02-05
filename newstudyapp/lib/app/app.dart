import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/config/app_config.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:newstudyapp/config/theme_controller.dart';
import 'package:newstudyapp/config/language_controller.dart';
import 'package:newstudyapp/config/auth_controller.dart';
import 'package:newstudyapp/routes/app_pages.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化主题控制器
    final themeController = Get.put(ThemeController());
    // 初始化语言控制器
    final languageController = Get.put(LanguageController());
    // 初始化认证控制器
    final authController = Get.put(AuthController());
    
    return Obx(() => GetMaterialApp(
      title: AppConfig.appTitle,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.login, // 固定从登录页开始
      getPages: AppPages.routes,
      
      // 路由守卫
      routingCallback: (routing) {
        _handleRouting(routing, authController);
      },
      
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

  /// 处理路由守卫
  static void _handleRouting(Routing? routing, AuthController authController) {
    if (routing == null) return;

    final currentRoute = routing.current;
    final isAuthenticated = authController.isAuthenticated.value;

    // 登录页不需要认证
    if (currentRoute == AppRoutes.login) {
      // 如果已登录，跳转到主页
      if (isAuthenticated) {
        Get.offAllNamed(AppRoutes.main);
      }
      return;
    }

    // 其他页面需要认证
    if (!isAuthenticated) {
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
