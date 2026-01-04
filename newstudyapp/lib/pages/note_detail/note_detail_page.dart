import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
          return _buildLoadingState(isDark, textColor, secondaryColor);
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

                    // 笔记内容（Markdown渲染）
                    _buildNoteContent(isDark, textColor, secondaryColor),
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

  /// 构建加载状态
  Widget _buildLoadingState(bool isDark, Color textColor, Color? secondaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.darkPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.darkPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Obx(() => Text(
            controller.state.generatingStatus.value.isNotEmpty
                ? controller.state.generatingStatus.value
                : 'AI 正在生成笔记...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          )),
          const SizedBox(height: 8),
          Text(
            '正在分析内容并提取核心概念',
            style: TextStyle(
              fontSize: 14,
              color: secondaryColor,
            ),
          ),
        ],
      ),
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

  /// 构建笔记内容（Markdown渲染）
  Widget _buildNoteContent(bool isDark, Color textColor, Color? secondaryColor) {
    return Obx(() {
      final markdownContent = controller.state.markdownContent;
      final content = controller.state.noteContent;
      
      // 优先使用Markdown内容
      if (markdownContent.isNotEmpty) {
        return MarkdownBody(
          data: markdownContent,
          selectable: true,
          styleSheet: _buildMarkdownStyleSheet(isDark, textColor),
        );
      }
      
      // 回退到普通文本
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

  /// 构建Markdown样式表
  MarkdownStyleSheet _buildMarkdownStyleSheet(bool isDark, Color textColor) {
    final codeBackground = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5);
    final blockquoteColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE8E8E8);
    // 标题使用主题紫色
    const headingColor = Color(0xFF667EEA);
    // 二级标题使用稍浅的紫色
    final h2Color = isDark ? const Color(0xFF8B9EF0) : const Color(0xFF5A6FD1);
    // 三级标题使用青色
    const h3Color = Color(0xFF4ECDC4);
    
    return MarkdownStyleSheet(
      p: TextStyle(fontSize: 15, color: textColor, height: 1.8),
      h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: headingColor, height: 1.5),
      h2: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: h2Color, height: 1.5),
      h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: h3Color, height: 1.5),
      h4: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor, height: 1.5),
      listBullet: TextStyle(fontSize: 15, color: textColor),
      code: TextStyle(fontSize: 14, color: AppTheme.darkPrimary, backgroundColor: codeBackground),
      codeblockDecoration: BoxDecoration(color: codeBackground, borderRadius: BorderRadius.circular(8)),
      codeblockPadding: const EdgeInsets.all(12),
      blockquote: TextStyle(fontSize: 15, color: isDark ? Colors.grey[400] : Colors.grey[700], fontStyle: FontStyle.italic, height: 1.6),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppTheme.darkPrimary, width: 3)),
        color: blockquoteColor,
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      tableHead: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
      tableBody: TextStyle(fontSize: 14, color: textColor),
      tableBorder: TableBorder.all(color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5), width: 1),
      tableCellsPadding: const EdgeInsets.all(8),
      strong: TextStyle(fontWeight: FontWeight.bold, color: textColor),
      em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
      a: TextStyle(color: AppTheme.darkPrimary, decoration: TextDecoration.underline),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5), width: 1)),
      ),
    );
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
        // 与首页今日复习卡片一致的紫色渐变背景
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'AI 正在分析笔记内容...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '正在提取核心概念和关键词',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
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
        // 与首页今日复习卡片一致的紫色渐变背景
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '此笔记尚未生成闪词卡片',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI 将从笔记中提取核心概念，帮助你更好地记忆',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
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
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF667EEA),
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
        // 与首页今日复习卡片一致的紫色渐变背景
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                '闪词学习进度',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
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
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.5)),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                  flex: (masteredPercent * 100).round(),
                  child: Container(color: const Color(0xFF4ECDC4)),
                ),
                Expanded(
                  flex: (reviewPercent * 100).round(),
                  child: Container(color: const Color(0xFF87CEEB)),
                ),
                Expanded(
                  flex: (improvePercent * 100).round(),
                  child: Container(color: const Color(0xFFFFD700)),
                ),
                Expanded(
                  flex: ((1 - masteredPercent - reviewPercent - improvePercent) * 100).round(),
                  child: Container(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress.progressPercent * 100).round()}% 已学习',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            Text(
              '${progress.mastered}/${progress.total} 已掌握',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4ECDC4),
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
        _buildStatItem('已掌握', progress.mastered, const Color(0xFF4ECDC4)),
        _buildStatItem('待复习', progress.needsReview, const Color(0xFF87CEEB)),
        _buildStatItem('需改进', progress.needsImprove, const Color(0xFFFFD700)),
        _buildStatItem('未学习', progress.notStarted, Colors.white.withOpacity(0.5)),
      ],
    );
  }

  /// 构建统计项
  Widget _buildStatItem(String label, int count, Color color) {
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部操作按钮
  Widget _buildBottomActions(bool isDark, Color bgColor, Color borderColor) {
    return Obx(() {
      final hasContent = controller.state.note.value != null;
      if (!hasContent) return const SizedBox.shrink();

      return Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(Get.context!).padding.bottom),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            // Ask AI 按钮
            Expanded(
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: controller.askAI,
                  icon: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B7DFF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('🦝', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  label: const Text(
                    'Ask AI',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black,
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Feynman 按钮
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: controller.startFeynmanLearning,
                  icon: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('🐷', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  label: const Text(
                    'Feynman',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
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
              _buildOptionItem(Icons.refresh, '重新生成', isDark, () {
                Get.back();
                controller.regenerateFlashCards();
              }),
              _buildOptionItem(Icons.edit_outlined, '编辑笔记', isDark, () {
                Get.back();
                Get.snackbar('提示', '编辑功能开发中', snackPosition: SnackPosition.BOTTOM);
              }),
              _buildOptionItem(Icons.share_outlined, '分享笔记', isDark, () {
                Get.back();
                Get.snackbar('提示', '分享功能开发中', snackPosition: SnackPosition.BOTTOM);
              }),
              _buildOptionItem(Icons.delete_outline, '删除笔记', isDark, () {
                Get.back();
                Get.snackbar('提示', '删除功能开发中', snackPosition: SnackPosition.BOTTOM);
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
