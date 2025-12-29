import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'note_detail_state.dart';

/// 笔记详情页控制器
class NoteDetailController extends GetxController {
  final NoteDetailState state = NoteDetailState();

  @override
  void onInit() {
    super.onInit();
    // 加载笔记数据（目前使用模拟数据）
    _loadNote();
  }

  /// 加载笔记数据
  Future<void> _loadNote() async {
    state.isLoading.value = true;

    try {
      // TODO: 从后端或本地数据库加载笔记
      // 目前使用模拟数据
      await Future.delayed(const Duration(milliseconds: 500));

      // 模拟笔记数据
      state.note.value = NoteModel(
        id: '1',
        title: '经济学基础概念',
        content: '''经济学是研究人类在稀缺资源条件下如何做出选择的学科。以下是一些核心概念：

1. 供需关系
供给是指生产者愿意在特定价格下出售的商品数量，需求是指消费者愿意在特定价格下购买的商品数量。当供给等于需求时，市场达到均衡状态。

2. 通货膨胀
通货膨胀是指货币购买力下降，物价普遍上涨的现象。适度的通胀有利于经济发展，但过高的通胀会损害经济稳定。

3. GDP（国内生产总值）
GDP是衡量一国经济活动的重要指标，代表一定时期内一国境内生产的所有最终商品和服务的市场价值总和。

4. 利率
利率是借贷资金的价格，由中央银行通过货币政策调控。利率影响储蓄、投资和消费行为。

5. 货币政策
货币政策是中央银行通过调节货币供应量和利率来影响经济的手段，包括公开市场操作、调整准备金率等。''',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
        termCount: 30, // 已生成30个闪词
      );

      // 模拟闪词学习进度
      state.progress.value = FlashCardProgress(
        total: 30,
        mastered: 12,
        needsReview: 8,
        needsImprove: 5,
        notStarted: 5,
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

    try {
      // TODO: 调用后端AI接口生成闪词
      await Future.delayed(const Duration(seconds: 2));

      // 模拟生成结果
      state.note.value = NoteModel(
        id: state.note.value!.id,
        title: state.note.value!.title,
        content: state.note.value!.content,
        createdAt: state.note.value!.createdAt,
        updatedAt: DateTime.now(),
        termCount: 25,
      );

      state.progress.value = FlashCardProgress(
        total: 25,
        mastered: 0,
        needsReview: 0,
        needsImprove: 0,
        notStarted: 25,
      );

      Get.snackbar(
        '成功',
        '已生成 25 个闪词卡片',
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

