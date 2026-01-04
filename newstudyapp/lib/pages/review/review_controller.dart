import 'package:get/get.dart';
import 'package:newstudyapp/pages/review/review_state.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/models/note_models.dart';

class ReviewController extends GetxController {
  final state = ReviewState();
  final httpService = HttpService();

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  /// 加载数据
  Future<void> loadData() async {
    await Future.wait([
      loadTodayReviewStatistics(),
      loadReviewCards(),
    ]);
  }

  /// 加载今日复习统计
  Future<void> loadTodayReviewStatistics() async {
    try {
      state.isLoading.value = true;
      state.errorMessage.value = null;
      final statistics = await httpService.getTodayReviewStatistics();
      state.todayReviewStatistics.value = statistics;
    } catch (e) {
      state.errorMessage.value = '加载今日复习统计失败：$e';
    } finally {
      state.isLoading.value = false;
    }
  }

  /// 加载复习卡片列表
  Future<void> loadReviewCards() async {
    try {
      state.isLoading.value = true;
      state.errorMessage.value = null;
      // 根据当前筛选类型决定是否获取所有词条
      final includeAll = state.currentFilter.value == ReviewFilterType.all || 
                         state.currentFilter.value == ReviewFilterType.mastered;
      final response = await httpService.getReviewFlashCards(includeAll: includeAll);
      state.reviewCards.value = response.cards;
      state.groupCardsByNote();
    } catch (e) {
      state.errorMessage.value = '加载复习卡片失败：$e';
    } finally {
      state.isLoading.value = false;
    }
  }

  /// 切换筛选类型
  void setFilter(ReviewFilterType filter) {
    state.currentFilter.value = filter;
    // 切换筛选时重新加载数据（如果需要所有数据）
    if (filter == ReviewFilterType.all || filter == ReviewFilterType.mastered) {
      loadReviewCards();
    } else {
      state.groupCardsByNote();
    }
  }

  /// 开始学习指定词条
  void startLearning(String noteId, String term) {
    Get.toNamed(
      AppRoutes.feynmanLearning,
      arguments: {
        'terms': [term],
        'topic': '复习学习',
        'noteId': noteId,
      },
    );
  }

  /// 刷新数据
  Future<void> refresh() async {
    await loadData();
  }
}
