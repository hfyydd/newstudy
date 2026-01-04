import 'package:get/get.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/models/note_models.dart';

/// 首页控制器
class HomeController extends GetxController {
  final HttpService _httpService = HttpService();
  
  // 笔记列表
  final RxList<NoteListItem> notes = <NoteListItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt totalNotes = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotes();
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

  /// 刷新笔记列表
  Future<void> refreshNotes() async {
    await loadNotes();
  }
}
