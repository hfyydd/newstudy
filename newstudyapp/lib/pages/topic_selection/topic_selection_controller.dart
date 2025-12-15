import 'package:get/get.dart';
import 'package:newstudyapp/pages/topic_selection/topic_selection_state.dart';
import 'package:newstudyapp/routes/app_routes.dart';

class TopicSelectionController extends GetxController {
  late final TopicSelectionState state;

  @override
  void onInit() {
    super.onInit();
    state = TopicSelectionState();
  }

  @override
  void onClose() {
    state.dispose();
    super.onClose();
  }

  /// 当自定义主题输入改变时
  void onCustomTopicChanged(String value) {
    // 如果用户输入了自定义主题，清除预设主题的选择
    if (value.trim().isNotEmpty) {
      state.selectedTopic.value = null;
    }
  }

  /// 选择预设主题
  void selectPresetTopic(String topicId) {
    // 如果选择了预设主题，清除自定义输入
    if (state.selectedTopic.value == topicId) {
      // 如果点击的是已选中的主题，取消选择
      state.selectedTopic.value = null;
    } else {
      state.selectedTopic.value = topicId;
      state.customTopicController.clear();
    }
  }

  /// 开始学习
  Future<void> startLearning() async {
    final topicName = state.getFinalTopic();
    final topicId = state.getFinalTopicId();

    if (topicName == null || topicId == null) {
      Get.snackbar(
        '提示',
        '请选择一个主题或输入自定义主题',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    state.isLoading.value = true;

    try {
      // 导航到费曼学习页面，传递主题信息
      Get.toNamed(
        AppRoutes.feynmanLearning,
        arguments: {
          'topic': topicName,
          'topicId': topicId,
        },
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '启动学习失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      state.isLoading.value = false;
    }
  }
}

