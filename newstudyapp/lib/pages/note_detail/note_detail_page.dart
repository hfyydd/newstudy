import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'note_detail_controller.dart';
import 'note_detail_state.dart';

/// 笔记详情页面
class NoteDetailPage extends GetView<NoteDetailController> {
  const NoteDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(
          controller.state.noteTitle,
          style: TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: textColor),
            onPressed: () => _showMoreOptions(context, isDark),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.state.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // 主要内容区域
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 闪词学习区域（放在顶部）
                    _buildFlashCardSection(isDark, textColor, secondaryColor, cardColor, borderColor),
                    const SizedBox(height: 24),

                    // 分割线
                    Divider(color: borderColor, height: 1),
                    const SizedBox(height: 20),

                    // 笔记元信息
                    _buildMetaInfo(secondaryColor),
                    const SizedBox(height: 16),

                    // 笔记内容
                    _buildNoteContent(textColor, secondaryColor),
                  ],
                ),
              ),
            ),

            // 底部操作按钮
            _buildBottomActions(isDark, bgColor, borderColor),
          ],
        );
      }),
    );
  }

  /// 构建笔记元信息
  Widget _buildMetaInfo(Color? secondaryColor) {
    return Obx(() {
      final note = controller.state.note.value;
      if (note == null) return const SizedBox.shrink();

      return Row(
        children: [
          Icon(Icons.access_time, size: 14, color: secondaryColor),
          const SizedBox(width: 4),
          Text(
            '创建于 ${controller.formatDate(note.createdAt)}',
            style: TextStyle(fontSize: 12, color: secondaryColor),
          ),
          const SizedBox(width: 16),
          Icon(Icons.edit_outlined, size: 14, color: secondaryColor),
          const SizedBox(width: 4),
          Text(
            '更新于 ${controller.formatDate(note.updatedAt)}',
            style: TextStyle(fontSize: 12, color: secondaryColor),
          ),
        ],
      );
    });
  }

  /// 构建笔记内容
  Widget _buildNoteContent(Color textColor, Color? secondaryColor) {
    return Obx(() {
      final content = controller.state.noteContent;
      if (content.isEmpty) {
        return Center(
          child: Text(
            '暂无内容',
            style: TextStyle(color: secondaryColor, fontSize: 14),
          ),
        );
      }

      return Text(
        content,
        style: TextStyle(
          fontSize: 15,
          color: textColor,
          height: 1.8,
        ),
      );
    });
  }

  /// 构建闪词学习区域
  Widget _buildFlashCardSection(
    bool isDark,
    Color textColor,
    Color? secondaryColor,
    Color cardColor,
    Color borderColor,
  ) {
    return Obx(() {
      final hasFlashCards = controller.state.hasFlashCards;
      final progress = controller.state.progress.value;
      final isGenerating = controller.state.isGenerating.value;

      if (isGenerating) {
        return _buildGeneratingCard(isDark, cardColor, borderColor);
      }

      if (!hasFlashCards) {
        return _buildNoFlashCardsCard(isDark, textColor, secondaryColor, cardColor, borderColor);
      }

      return _buildProgressCard(isDark, textColor, secondaryColor, cardColor, borderColor, progress!);
    });
  }

  /// 构建"正在生成"卡片
  Widget _buildGeneratingCard(bool isDark, Color cardColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            'AI 正在分析笔记内容...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '正在提取核心概念和关键词',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建"尚未生成闪词"卡片
  Widget _buildNoFlashCardsCard(
    bool isDark,
    Color textColor,
    Color? secondaryColor,
    Color cardColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 32,
              color: AppTheme.darkPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '此笔记尚未生成闪词卡片',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI 将从笔记中提取核心概念，帮助你更好地记忆',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: controller.generateFlashCards,
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text(
                '生成闪词卡片',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建学习进度卡片
  Widget _buildProgressCard(
    bool isDark,
    Color textColor,
    Color? secondaryColor,
    Color cardColor,
    Color borderColor,
    FlashCardProgress progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(Icons.school_outlined, size: 20, color: AppTheme.darkPrimary),
              const SizedBox(width: 8),
              Text(
                '闪词学习进度',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 进度条
          _buildProgressBar(progress, isDark),
          const SizedBox(height: 20),

          // 统计数据
          _buildProgressStats(progress, isDark, textColor, secondaryColor),
          const SizedBox(height: 20),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.regenerateFlashCards,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: secondaryColor,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('重新生成'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.viewLearningRecords,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: secondaryColor,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('学习记录'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(FlashCardProgress progress, bool isDark) {
    final masteredPercent = progress.masteredPercent;
    final reviewPercent = progress.needsReview / progress.total;
    final improvePercent = progress.needsImprove / progress.total;

    return Column(
      children: [
        // 进度条
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                // 已掌握（绿色）
                Expanded(
                  flex: (masteredPercent * 100).round(),
                  child: Container(color: const Color(0xFF4ECDC4)),
                ),
                // 待复习（蓝色）
                Expanded(
                  flex: (reviewPercent * 100).round(),
                  child: Container(color: const Color(0xFF5B8DEF)),
                ),
                // 需改进（橙色）
                Expanded(
                  flex: (improvePercent * 100).round(),
                  child: Container(color: const Color(0xFFFFAA33)),
                ),
                // 未学习（灰色）
                Expanded(
                  flex: ((1 - masteredPercent - reviewPercent - improvePercent) * 100).round(),
                  child: Container(
                    color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 百分比
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress.progressPercent * 100).round()}% 已学习',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              '${progress.mastered}/${progress.total} 已掌握',
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF4ECDC4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建进度统计
  Widget _buildProgressStats(
    FlashCardProgress progress,
    bool isDark,
    Color textColor,
    Color? secondaryColor,
  ) {
    return Row(
      children: [
        _buildStatItem('已掌握', progress.mastered, const Color(0xFF4ECDC4), isDark),
        _buildStatItem('待复习', progress.needsReview, const Color(0xFF5B8DEF), isDark),
        _buildStatItem('需改进', progress.needsImprove, const Color(0xFFFFAA33), isDark),
        _buildStatItem('未学习', progress.notStarted, isDark ? Colors.grey[600]! : Colors.grey[400]!, isDark),
      ],
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, int count, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部操作按钮
  Widget _buildBottomActions(bool isDark, Color bgColor, Color borderColor) {
    return Obx(() {
      final hasFlashCards = controller.state.hasFlashCards;
      if (!hasFlashCards) return const SizedBox.shrink();

      return Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(Get.context!).padding.bottom),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: controller.continueLearning,
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: const Text(
              '继续学习',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ),
      );
    });
  }

  /// 显示更多选项
  void _showMoreOptions(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              _buildOptionItem(Icons.edit_outlined, '编辑笔记', isDark, () {
                Get.back();
                controller.editNote();
              }),
              _buildOptionItem(Icons.share_outlined, '分享笔记', isDark, () {
                Get.back();
                Get.snackbar('提示', '分享功能开发中', snackPosition: SnackPosition.BOTTOM);
              }),
              _buildOptionItem(Icons.delete_outline, '删除笔记', isDark, () {
                Get.back();
                controller.deleteNote();
              }, isDestructive: true),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建选项项
  Widget _buildOptionItem(
    IconData icon,
    String label,
    bool isDark,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? const Color(0xFFFF6B6B)
        : (isDark ? Colors.white : Colors.black);

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}

