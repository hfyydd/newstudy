import 'package:get/get.dart';
import 'package:newstudyapp/pages/study_center/study_center_controller.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';

class MainController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) {
    if (currentIndex.value != index) {
      currentIndex.value = index;
      // 切换到对应 tab 时刷新数据
      _refreshTabData(index);
    }
  }

  /// 刷新对应 tab 的数据
  void _refreshTabData(int index) {
    switch (index) {
      case 0:
        // 首页 - 刷新首页数据
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().refreshData();
        }
        break;
      case 1:
        // 学习中心 - 刷新统计数据
        if (Get.isRegistered<StudyCenterController>()) {
          Get.find<StudyCenterController>().refreshStatistics();
        }
        break;
      // 其他 tab 可以在此添加刷新逻辑
    }
  }
}
