import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'note_detail_state.dart';

/// 笔记详情页控制器
class NoteDetailController extends GetxController {
  final NoteDetailState state = NoteDetailState();
  final HttpService httpService = HttpService();
  
  String? _noteId;

  @override
  void onInit() {
    super.onInit();
    // 从路由参数获取笔记ID
    final arguments = Get.arguments as Map<String, dynamic>?;
    _noteId = arguments?['noteId'] as String?;
    
    if (_noteId != null) {
      _loadNote();
    } else {
      // 如果没有传递笔记ID，显示错误
      state.isLoading.value = false;
      Get.snackbar(
        '错误',
        '缺少笔记ID参数',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 加载笔记数据
  Future<void> _loadNote() async {
    if (_noteId == null) return;
    
    state.isLoading.value = true;

    try {
      // 从后端加载笔记详情
      final noteResponse = await httpService.getNote(_noteId!);
      state.note.value = noteResponse.toNoteModel();

      // 加载闪词学习进度
      try {
        final progress = await httpService.getFlashCardProgress(_noteId!);
        state.progress.value = progress;
      } catch (e) {
        // 如果没有闪词数据，进度为0
        state.progress.value = FlashCardProgress(
          total: 0,
          mastered: 0,
          needsReview: 0,
          needsImprove: 0,
          notStarted: 0,
        );
      }
    } catch (e) {
      Get.snackbar(
        '错误',
        '加载笔记失败：$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      state.isLoading.value = false;
    }
  }

  /// 生成闪词卡片
  Future<void> generateFlashCards() async {
    if (_noteId == null) return;
    
    state.isGenerating.value = true;

    try {
      // 调用后端AI接口生成闪词
      final response = await httpService.generateFlashCards(
        noteId: _noteId!,
        maxTerms: 30,
      );

      // 重新加载笔记详情（更新 termCount）
      final noteResponse = await httpService.getNote(_noteId!);
      state.note.value = noteResponse.toNoteModel();

      // 加载闪词学习进度
      final progress = await httpService.getFlashCardProgress(_noteId!);
      state.progress.value = progress;

      Get.snackbar(
        '成功',
        '已生成 ${response.total} 个闪词卡片',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '生成闪词失败：$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      state.isGenerating.value = false;
    }
  }

  /// 继续学习
  Future<void> continueLearning() async {
    if (_noteId == null) return;

    // 检查是否有闪词卡片
    if (!state.hasFlashCards) {
      Get.snackbar(
        '提示',
        '请先生成闪词卡片',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      // 获取闪词卡片列表
      final flashCardsResponse = await httpService.getFlashCards(_noteId!);
      
      if (flashCardsResponse.terms.isEmpty) {
        Get.snackbar(
          '提示',
          '暂无闪词卡片，请先生成',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // 跳转到费曼学习页面，传递词条列表和笔记信息
      Get.toNamed(
        AppRoutes.feynmanLearning,
        arguments: {
          'terms': flashCardsResponse.terms,
          'topic': state.noteTitle.isNotEmpty ? state.noteTitle : '我的笔记',
          'noteId': _noteId,
        },
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '获取闪词卡片失败：$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 重新生成闪词
  Future<void> regenerateFlashCards() async {
    final confirmed = await Get.dialog<bool>(
      _buildConfirmDialog(),
    );

    if (confirmed == true) {
      await generateFlashCards();
    }
  }

  /// 构建确认对话框
  Widget _buildConfirmDialog() {
    return AlertDialog(
      title: const Text('⚠️ 重新生成闪词卡片'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('将会：'),
          SizedBox(height: 8),
          Text('✓ 保留所有已有词条的学习记录'),
          Text('✓ 添加新提取的词条到学习列表'),
          Text('✓ 新旧词条自动去重合并'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('确认重新生成'),
        ),
      ],
    );
  }

  /// 查看学习记录
  void viewLearningRecords() {
    // TODO: 跳转到学习记录页面
    Get.snackbar(
      '提示',
      '学习记录功能开发中',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// 格式化日期
  String formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} 分钟前';
      }
      return '${diff.inHours} 小时前';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// 编辑笔记
  Future<void> editNote() async {
    if (_noteId == null) return;

    final note = state.note.value;
    if (note == null) return;

    // 跳转到编辑页面，传递笔记信息
    final result = await Get.toNamed(
      AppRoutes.createNote,
      arguments: {
        'noteId': _noteId,
        'title': note.title,
        'content': note.content,
        'isEdit': true,
      },
    );

    // 如果编辑成功，重新加载笔记
    if (result == true) {
      await _loadNote();
    }
  }

  /// 删除笔记
  Future<void> deleteNote() async {
    if (_noteId == null) {
      debugPrint('[NoteDetailController] 删除失败：noteId 为空');
      Get.snackbar(
        '错误',
        '无法获取笔记ID',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }
    
    debugPrint('[NoteDetailController] 准备删除笔记，noteId: $_noteId');

    // 显示确认对话框
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('⚠️ 删除笔记'),
        content: const Text(
          '确定要删除这条笔记吗？\n\n删除后将无法恢复，关联的闪词卡片也会一并删除。',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 显示加载提示
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // 调用删除接口
      debugPrint('[NoteDetailController] 开始删除笔记: $_noteId');
      try {
        await httpService.deleteNote(_noteId!);
        debugPrint('[NoteDetailController] 删除笔记API调用成功: $_noteId');
      } catch (apiError) {
        debugPrint('[NoteDetailController] 删除笔记API调用失败: $apiError');
        // 关闭加载提示
        Get.back();
        // 重新抛出错误，让外层 catch 处理
        rethrow;
      }

      // 关闭加载提示
      Get.back();

      // 直接通知 HomeController 刷新列表（因为 Get.back 的返回值可能无法正确传递）
      // 使用更安全的方式查找 HomeController
      if (Get.isRegistered<HomeController>()) {
        try {
          final homeController = Get.find<HomeController>();
          debugPrint('[NoteDetailController] 找到 HomeController，准备刷新列表');
          await homeController.loadNotes();
          debugPrint('[NoteDetailController] 列表刷新完成，当前笔记数: ${homeController.state.notes.length}');
        } catch (e) {
          debugPrint('[NoteDetailController] 刷新列表时出错: $e');
        }
      } else {
        debugPrint('[NoteDetailController] HomeController 未注册，无法刷新列表');
      }

      // 先返回笔记列表，再显示成功提示（这样提示会在列表页显示）
      debugPrint('[NoteDetailController] 准备返回列表页');
      Get.back();
      debugPrint('[NoteDetailController] 已返回列表页');

      // 返回后再显示成功提示（这样提示会在列表页显示）
      await Future.delayed(const Duration(milliseconds: 300));
      Get.snackbar(
        '成功',
        '笔记已删除',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    } catch (e, stackTrace) {
      // 关闭加载提示（如果还在显示）
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      debugPrint('[NoteDetailController] 删除笔记异常: $e');
      debugPrint('[NoteDetailController] 异常堆栈: $stackTrace');

      // 显示详细的错误信息
      String errorMessage = '删除笔记失败';
      final errorStr = e.toString();
      if (errorStr.contains('404') || errorStr.contains('不存在')) {
        errorMessage = '笔记不存在或已被删除';
      } else if (errorStr.contains('500') || errorStr.contains('服务器')) {
        errorMessage = '服务器错误，请稍后重试';
      } else if (errorStr.contains('网络') || errorStr.contains('连接') || errorStr.contains('timeout')) {
        errorMessage = '网络连接失败，请检查网络';
      } else {
        errorMessage = '删除失败：${errorStr.length > 50 ? errorStr.substring(0, 50) + "..." : errorStr}';
      }

      Get.snackbar(
        '错误',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}

