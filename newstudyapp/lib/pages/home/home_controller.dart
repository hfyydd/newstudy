import 'package:get/get.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/pages/main/main_controller.dart';
import 'home_state.dart';

class HomeController extends GetxController {
  final HttpService httpService = HttpService();
  final HomeState state = HomeState();

  @override
  void onInit() {
    super.onInit();
    // 加载笔记列表、统计数据和今日复习数据
    loadNotes();
    loadStatistics();
    loadTodayReviewStatistics();
  }

  /// 加载笔记列表
  Future<void> loadNotes() async {
    state.isLoading.value = true;
    state.errorMessage.value = null;

    try {
      print('[HomeController] 开始加载笔记列表...');
      final response = await httpService.listNotes();
      print('[HomeController] 获取到 ${response.notes.length} 个笔记');
      state.notes.value = response.notes;
      print('[HomeController] 笔记列表已更新: ${state.notes.length}');
    } catch (e, stackTrace) {
      print('[HomeController] 加载笔记列表失败: $e');
      print('[HomeController] 错误堆栈: $stackTrace');
      state.errorMessage.value = '加载笔记列表失败：$e';
      // 显示错误提示
      Get.snackbar(
        '错误',
        '加载笔记列表失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      state.isLoading.value = false;
    }
  }

  /// 刷新笔记列表
  Future<void> refreshNotes() async {
    await loadNotes();
  }

  /// 跳转到笔记详情页
  Future<void> navigateToNoteDetail(String noteId) async {
    print('[HomeController] 跳转到笔记详情页: $noteId');
    final result = await Get.toNamed(
      AppRoutes.noteDetail,
      arguments: {'noteId': noteId},
    );
    
    print('[HomeController] 从笔记详情页返回，result: $result, type: ${result.runtimeType}');
    
    // 如果返回 true，说明笔记被删除或更新了，需要刷新列表
    if (result == true) {
      print('[HomeController] 检测到笔记被删除/更新，刷新列表...');
      await loadNotes();
      print('[HomeController] 列表刷新完成，当前笔记数: ${state.notes.length}');
    } else {
      print('[HomeController] 未检测到删除/更新操作，不刷新列表');
    }
  }

  /// 加载学习统计数据
  Future<void> loadStatistics() async {
    state.isLoadingStatistics.value = true;

    try {
      print('[HomeController] 开始加载学习统计...');
      final stats = await httpService.getLearningStatistics();
      print('[HomeController] 获取到统计数据: mastered=${stats.mastered}, totalTerms=${stats.totalTerms}');
      state.statistics.value = stats;
    } catch (e) {
      print('[HomeController] 加载学习统计失败: $e');
      // 统计数据加载失败不影响主功能，只记录错误
    } finally {
      state.isLoadingStatistics.value = false;
    }
  }

  /// 刷新统计数据
  Future<void> refreshStatistics() async {
    await loadStatistics();
  }

  /// 加载今日复习统计数据
  Future<void> loadTodayReviewStatistics() async {
    state.isLoadingTodayReview.value = true;

    try {
      print('[HomeController] 开始加载今日复习统计...');
      final stats = await httpService.getTodayReviewStatistics();
      print('[HomeController] 获取到今日复习统计: total=${stats.total}, needsReview=${stats.needsReview}, needsImprove=${stats.needsImprove}');
      state.todayReviewStatistics.value = stats;
    } catch (e) {
      print('[HomeController] 加载今日复习统计失败: $e');
      // 统计数据加载失败不影响主功能，只记录错误
    } finally {
      state.isLoadingTodayReview.value = false;
    }
  }

  /// 刷新今日复习统计数据
  Future<void> refreshTodayReviewStatistics() async {
    await loadTodayReviewStatistics();
  }

  /// 跳转到复习页面
  void navigateToReview() {
    try {
      // 通过 Get.find 获取 MainController 并切换到复习页面（index 1）
      final mainController = Get.find<MainController>();
      mainController.changeTab(1);
    } catch (e) {
      print('[HomeController] 跳转到复习页面失败: $e');
    }
  }
}
