import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'note_detail_state.dart';

/// 笔记详情页控制器
class NoteDetailController extends GetxController {
  final NoteDetailState state = NoteDetailState();
  final HttpService _httpService = HttpService();

  @override
  void onInit() {
    super.onInit();
    // 获取从创建笔记页面传入的用户输入
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      final userInput = args['userInput'] as String?;
      if (userInput != null && userInput.isNotEmpty) {
        state.userInput.value = userInput;
        // 调用AI生成智能笔记
        _generateSmartNote(userInput);
      } else {
        // 如果没有传入内容，显示空状态
        state.isLoading.value = false;
      }
    } else {
      // 加载已有笔记（从笔记列表进入的情况）
      _loadNote();
    }
  }

  /// 调用AI生成智能笔记
  Future<void> _generateSmartNote(String userInput) async {
    state.isLoading.value = true;
    state.isGenerating.value = true;
    state.generatingStatus.value = 'AI 正在分析内容...';

    try {
      // 调用后端API生成智能笔记
      final response = await _httpService.generateSmartNote(
        userInput: userInput,
        maxTerms: 30,
      );

      // 从内容中提取标题（取第一行或前20个字符）
      String title = '智能笔记';
      final lines = response.noteContent.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty) {
          // 移除Markdown标题符号
          title = trimmed.replaceAll(RegExp(r'^#+\s*'), '');
          if (title.length > 20) {
            title = '${title.substring(0, 20)}...';
          }
          break;
        }
      }

      // 创建笔记模型
      state.note.value = NoteModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        content: userInput,
        markdownContent: response.noteContent,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        termCount: response.terms.length,
        terms: response.terms,
      );

      // 初始化学习进度
      state.progress.value = FlashCardProgress(
        total: response.terms.length,
        mastered: 0,
        needsReview: 0,
        needsImprove: 0,
        notStarted: response.terms.length,
      );

    } catch (e) {
      Get.snackbar(
        '生成失败',
        '智能笔记生成失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF6B6B),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } finally {
      state.isLoading.value = false;
      state.isGenerating.value = false;
      state.generatingStatus.value = '';
    }
  }

  /// 加载已有笔记数据（模拟）
  Future<void> _loadNote() async {
    state.isLoading.value = true;

    try {
      // TODO: 从后端或本地数据库加载笔记
      await Future.delayed(const Duration(milliseconds: 500));

      // 模拟笔记数据
      state.note.value = NoteModel(
        id: '1',
        title: '经济学基础概念',
        content: '经济学是研究人类在稀缺资源条件下如何做出选择的学科。',
        markdownContent: '''# 经济学基础概念

经济学是研究人类在稀缺资源条件下如何做出选择的学科。以下是一些核心概念：

## 供需关系

供给是指生产者愿意在特定价格下出售的商品数量，需求是指消费者愿意在特定价格下购买的商品数量。当供给等于需求时，市场达到均衡状态。

## 通货膨胀

通货膨胀是指货币购买力下降，物价普遍上涨的现象。适度的通胀有利于经济发展，但过高的通胀会损害经济稳定。

## GDP（国内生产总值）

GDP是衡量一国经济活动的重要指标，代表一定时期内一国境内生产的所有最终商品和服务的市场价值总和。
''',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
        termCount: 10,
        terms: ['通货膨胀', '货币政策', 'GDP', '供需关系', '市场均衡'],
      );

      // 模拟闪词学习进度
      state.progress.value = FlashCardProgress(
        total: 10,
        mastered: 4,
        needsReview: 3,
        needsImprove: 2,
        notStarted: 1,
      );
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
    state.isGenerating.value = true;
    state.generatingStatus.value = '正在提取核心概念...';

    try {
      // 重新调用AI生成
      if (state.userInput.value.isNotEmpty) {
        await _generateSmartNote(state.userInput.value);
      } else if (state.note.value != null) {
        await _generateSmartNote(state.note.value!.content);
      }

      Get.snackbar(
        '成功',
        '已生成 ${state.terms.length} 个闪词卡片',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF4ECDC4),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.snackbar(
        '错误',
        '生成闪词失败：$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      state.isGenerating.value = false;
      state.generatingStatus.value = '';
    }
  }

  /// 继续学习（跳转到费曼学习页面）
  void continueLearning() {
    if (state.terms.isEmpty) {
      Get.snackbar(
        '提示',
        '暂无闪词可学习',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    // 跳转到费曼学习页面，传递闪词列表
    Get.toNamed(
      AppRoutes.feynmanLearning,
      arguments: {
        'terms': state.terms,
        'noteId': state.note.value?.id,
        'noteTitle': state.note.value?.title,
      },
    );
  }
  
  /// Ask AI（与AI对话）
  void askAI() {
    Get.snackbar(
      '提示',
      'Ask AI 功能开发中',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF5B8DEF),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }
  
  /// 费曼学习
  void startFeynmanLearning() {
    continueLearning();
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
