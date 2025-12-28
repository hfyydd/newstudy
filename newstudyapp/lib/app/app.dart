import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/config/app_config.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:newstudyapp/config/theme_controller.dart';
import 'package:newstudyapp/routes/app_pages.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化主题控制器
    final themeController = Get.put(ThemeController());
    
    return Obx(() => GetMaterialApp(
      title: AppConfig.appTitle,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    ));
  }
}
