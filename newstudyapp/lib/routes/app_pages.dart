import 'package:get/get.dart';
import 'package:newstudyapp/pages/home/home_page.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'package:newstudyapp/routes/app_routes.dart';

/// GetX 页面路由配置
class AppPages {
  AppPages._();

  /// 初始路由
  static const INITIAL = AppRoutes.HOME;

  /// 所有路由页面配置
  static final routes = [
    GetPage(
      name: AppRoutes.HOME,
      page: () => const HomePage(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
    ),
  ];
}
