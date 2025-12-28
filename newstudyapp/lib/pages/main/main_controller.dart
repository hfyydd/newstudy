import 'package:get/get.dart';

class MainController extends GetxController {
  final currentIndex = 0.obs;

  void changeTab(int index) {
    if (currentIndex.value != index) {
      currentIndex.value = index;
    }
  }
}

