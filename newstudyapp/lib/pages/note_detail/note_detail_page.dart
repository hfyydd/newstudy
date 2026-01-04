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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 闪词学习区域（突出显示，使用渐变背景）
                    _buildFlashCardSection(isDark, textColor, secondaryColor),
                    
                    // 笔记内容区域
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 笔记内容标题
                          Row(
                            children: [
                              Icon(Icons.article_outlined, size: 18, color: secondaryColor),
                              const SizedBox(width: 8),
                              Text(
                                '笔记内容',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryColor,
                                ),
                              ),
                              const Spacer(),
                              // 笔记元信息
                              _buildMetaInfo(secondaryColor),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 笔记内容（Markdown 渲染）
                          _buildNoteContent(isDark, textColor, secondaryColor),
                        ],
                      ),
                    ),
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

      return Text(
        controller.formatDate(note.updatedAt),
        style: TextStyle(fontSize: 12, color: secondaryColor),
      );
    });
  }

  /// 构建笔记内容（Markdown 渲染）
  Widget _buildNoteContent(bool isDark, Color textColor, Color? secondaryColor) {
    return Obx(() {
      final content = controller.state.noteContent;
      if (content.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              '暂无内容',
              style: TextStyle(color: secondaryColor, fontSize: 14),
            ),
          ),
        );
      }

      return MarkdownBody(
        data: content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            fontSize: 15,
            color: textColor,
            height: 1.8,
          ),
          h1: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 2,
          ),
          h2: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.8,
          ),
          h3: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1.8,
          ),
          h4: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1.6,
          ),
          strong: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          em: TextStyle(
            fontStyle: FontStyle.italic,
            color: textColor,
          ),
          code: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF4ECDC4) : const Color(0xFF007ACC),
            backgroundColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5),
          ),
          codeblockDecoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5),
            ),
          ),
          blockquote: TextStyle(
            fontSize: 15,
            color: secondaryColor,
            fontStyle: FontStyle.italic,
            height: 1.6,
          ),
          blockquoteDecoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppTheme.darkPrimary.withOpacity(0.5),
                width: 4,
              ),
            ),
          ),
          listBullet: TextStyle(
            fontSize: 15,
            color: textColor,
          ),
          tableHead: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          tableBody: TextStyle(
            color: textColor,
          ),
          tableBorder: TableBorder.all(
            color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5),
          ),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5),
              ),
            ),
          ),
        ),
      );
    });
  }

  /// 构建闪词学习区域
  Widget _buildFlashCardSection(
    bool isDark,
    Color textColor,
    Color? secondaryColor,
  ) {
    return Obx(() {
      final hasFlashCards = controller.state.hasFlashCards;
      final progress = controller.state.progress.value;
      final isGenerating = controller.state.isGenerating.value;

      // 整个闪词区域的包装容器，添加明显的背景区分
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // 使用渐变背景，与页面背景形成对比
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A2A3A), // 深蓝色调
                    const Color(0xFF1C2433), // 深色渐变
                    const Color(0xFF1A1F2E),
                  ]
                : [
                    const Color(0xFFF0F7FF), // 浅蓝色调
                    const Color(0xFFF5F0FF), // 紫色调
                    const Color(0xFFFFF5F5), // 粉色调
                  ],
          ),
          // 底部圆角
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          // 添加微妙的内阴影效果
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : AppTheme.darkPrimary.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 装饰性背景元素
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.statusMastered.withOpacity(isDark ? 0.15 : 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.statusNeedsReview.withOpacity(isDark ? 0.12 : 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // 主要内容
            if (isGenerating)
              _buildGeneratingCard(isDark)
            else if (!hasFlashCards)
              _buildNoFlashCardsCard(isDark, textColor, secondaryColor)
            else
              _buildProgressCard(isDark, textColor, secondaryColor, progress!),
          ],
        ),
      );
    });
  }

  /// 构建"正在生成"卡片
  Widget _buildGeneratingCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        // 使用半透明背景，与渐变背景融合
        color: isDark 
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : AppTheme.darkPrimary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkPrimary.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkPrimary.withOpacity(0.2),
                  AppTheme.darkSecondary.withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.darkPrimary),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'AI 正在分析笔记内容...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
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
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        // 使用半透明背景，与渐变背景融合
        color: isDark 
            ? Colors.white.withOpacity(0.05)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : AppTheme.darkPrimary.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkPrimary.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkPrimary.withOpacity(0.25),
                  AppTheme.darkSecondary.withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.darkPrimary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '开启 AI 闪词学习',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'AI 将从笔记中提取核心概念\n通过费曼学习法帮助你深度记忆',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: controller.generateFlashCards,
              icon: const Icon(Icons.auto_awesome, size: 22),
              label: const Text(
                '生成闪词卡片',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: AppTheme.darkPrimary.withOpacity(0.5),
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
    FlashCardProgress progress,
  ) {
    final total = progress.total;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: BoxDecoration(
        // 使用半透明背景，与渐变背景融合
        color: isDark 
            ? Colors.white.withOpacity(0.06)
            : Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1)
              : AppTheme.statusMastered.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.statusMastered.withOpacity(isDark ? 0.15 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 顶部标题栏
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.statusMastered.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 20,
                    color: AppTheme.statusMastered,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '闪词学习进度',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '共 $total 个闪词',
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // 掌握百分比
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.statusMastered.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(progress.masteredPercent * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.statusMastered,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 进度条
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSegmentedProgressBar(progress, isDark),
          ),
          const SizedBox(height: 20),

          // 统计网格
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildStatCard('已掌握', progress.mastered, AppTheme.statusMastered, isDark),
                _buildStatCard('待复习', progress.needsReview, AppTheme.statusNeedsReview, isDark),
                _buildStatCard('需改进', progress.needsImprove, AppTheme.statusNeedsImprove, isDark),
                _buildStatCard('未学习', progress.notStarted, AppTheme.statusNotStarted, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 分割线
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E5),
          ),

          // 底部操作按钮
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: controller.regenerateFlashCards,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: secondaryColor,
                    ),
                    label: Text(
                      '重新生成',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E5),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: controller.viewLearningRecords,
                    icon: Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: secondaryColor,
                    ),
                    label: Text(
                      '学习记录',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分段进度条
  Widget _buildSegmentedProgressBar(FlashCardProgress progress, bool isDark) {
    final total = progress.total;
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            // 已掌握
            if (progress.mastered > 0)
              Expanded(
                flex: progress.mastered,
                child: Container(color: AppTheme.statusMastered),
              ),
            // 待复习
            if (progress.needsReview > 0)
              Expanded(
                flex: progress.needsReview,
                child: Container(color: AppTheme.statusNeedsReview),
              ),
            // 需改进
            if (progress.needsImprove > 0)
              Expanded(
                flex: progress.needsImprove,
                child: Container(color: AppTheme.statusNeedsImprove),
              ),
            // 未学习
            if (progress.notStarted > 0)
              Expanded(
                flex: progress.notStarted,
                child: Container(
                  color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5E5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard(String label, int count, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
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
          height: 52,
          child: ElevatedButton.icon(
            onPressed: controller.continueLearning,
            icon: const Icon(Icons.play_arrow_rounded, size: 26),
            label: const Text(
              '继续学习',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              shadowColor: AppTheme.darkPrimary.withOpacity(0.4),
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
