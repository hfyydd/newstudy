import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/models/note_models.dart';
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
  void continueLearning() {
    // TODO: 跳转到费曼学习页面
    Get.snackbar(
      '提示',
      '即将进入费曼学习页面',
      snackPosition: SnackPosition.BOTTOM,
    );
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
}

