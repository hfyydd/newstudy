import 'package:get/get.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'home_state.dart';

class HomeController extends GetxController {
  final HttpService httpService = HttpService();
  final HomeState state = HomeState();

  @override
  void onInit() {
    super.onInit();
    // 加载笔记列表
    loadNotes();
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
  void navigateToNoteDetail(String noteId) {
    Get.toNamed(
      AppRoutes.noteDetail,
      arguments: {'noteId': noteId},
    );
  }
}
