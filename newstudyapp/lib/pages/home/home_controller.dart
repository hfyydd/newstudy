import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/models/note_models.dart';
import 'package:newstudyapp/pages/study_center/study_center_state.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_page.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_controller.dart';

/// 首页控制器
class HomeController extends GetxController {
  final HttpService _httpService = HttpService();

  // 笔记列表
  final RxList<NoteListItem> notes = <NoteListItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt totalNotes = 0.obs;
  final RxInt todayReviewCount = 0.obs;
  final RxInt needsReviewCount = 0.obs;
  final RxInt needsImproveCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotes();
    loadReviewSummary();
  }

  @override
  void onReady() {
    super.onReady();
    // 当页面准备好时，如果列表为空则加载
    if (notes.isEmpty && !isLoading.value) {
      loadNotes();
    }
  }

  /// 加载笔记列表
  Future<void> loadNotes() async {
    isLoading.value = true;
    try {
      final response = await _httpService.listNotes(skip: 0, limit: 100);
      notes.value = response.notes;
      totalNotes.value = response.total;
    } catch (e) {
      Get.snackbar(
        '错误',
        '加载笔记列表失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载今日复习概要
  Future<void> loadReviewSummary() async {
    try {
      final statistics = await _httpService.getStudyCenterStatistics();
      todayReviewCount.value = statistics.todayReviewCount;
      needsReviewCount.value = statistics.needsReviewCount;
      needsImproveCount.value = statistics.needsImproveCount;
    } catch (e) {
      // 如果API调用失败，使用假数据作为降级方案
      todayReviewCount.value = 0;
      needsReviewCount.value = 0;
      needsImproveCount.value = 0;
      debugPrint('加载今日复习概要失败: $e');
    }
  }

  /// 刷新笔记列表
  Future<void> refreshNotes() async {
    await loadNotes();
  }

  /// 直接跳转到费曼学习页面（今日需要复习）
  Future<void> navigateToTodayReviewFeynmanLearning({
    int initialLimit = 30, // 初始加载30条
  }) async {
    try {
      // 加载今日需要复习的第一页数据
      final response = await _httpService.getTodayReviewCards(
        skip: 0,
        limit: initialLimit,
      );

      // 转换为费曼学习页面需要的格式
      final flashCards = response.cards
          .map((card) => {
                'id': card.id,
                'term': card.term,
                'status': card.status,
                'review_count': card.reviewCount,
                'last_reviewed_at': null,
                'mastered_at': null,
              })
          .toList();

      if (flashCards.isEmpty) {
        Get.snackbar(
          '提示',
          '暂无词条可学习',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
        return;
      }

      // 跳转到费曼学习页面，传递分页信息
      Get.to(
        () {
          // 确保控制器被注册
          if (!Get.isRegistered<FeynmanLearningController>()) {
            Get.lazyPut<FeynmanLearningController>(() => FeynmanLearningController());
          }
          return const FeynmanLearningPage();
        },
        arguments: {
          'flashCards': flashCards,
          'topic': '今日需要复习',
          'pageType': StudyCenterPageType.todayReview.name, // 保存页面类型，用于后续加载更多
          'statusFilter': null, // 今日复习不需要状态筛选
          'currentSkip': initialLimit, // 当前已加载的数量
          'total': response.total, // 总数
        },
        transition: Transition.noTransition, // 无动画跳转
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '加载词条失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
