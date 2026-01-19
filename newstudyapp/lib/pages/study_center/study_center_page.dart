import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:newstudyapp/pages/study_center/study_center_controller.dart';
import 'package:newstudyapp/pages/study_center/study_center_state.dart';
import 'package:newstudyapp/models/note_models.dart';

/// 学习中心页面
class StudyCenterPage extends StatelessWidget {
  const StudyCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StudyCenterController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Obx(() => _buildPage(context, controller, isDark)),
      ),
    );
  }

  Widget _buildPage(
      BuildContext context, StudyCenterController controller, bool isDark) {
    switch (controller.state.currentPage.value) {
      case StudyCenterPageType.main:
        return _buildMainPage(context, controller, isDark);
      case StudyCenterPageType.todayReview:
        return _buildTodayReviewPage(context, controller, isDark);
      case StudyCenterPageType.weakCards:
        return _buildWeakCardsPage(context, controller, isDark);
      case StudyCenterPageType.masteredCards:
        return _buildMasteredCardsPage(context, controller, isDark);
      case StudyCenterPageType.allCards:
        return _buildAllCardsPage(context, controller, isDark);
      case StudyCenterPageType.byNote:
        return _buildByNotePage(context, controller, isDark);
    }
  }

  /// 构建主页
  Widget _buildMainPage(
      BuildContext context, StudyCenterController controller, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // 标题
            Text(
              '学习中心',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 40),

            // 今日复习卡片（突出显示）
            _buildTodayReviewHighlightCard(
              context: context,
              controller: controller,
              isDark: isDark,
            ),
            const SizedBox(height: 40),

            // 分类切换按钮和内容
            Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 分类切换按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.state.showCardCategory.value
                              ? '闪词分类'
                              : '笔记分类',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller.toggleCategory(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  controller.state.showCardCategory.value
                                      ? Icons.view_list
                                      : Icons.grid_view,
                                  size: 16,
                                  color: textColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  controller.state.showCardCategory.value
                                      ? '切换到笔记'
                                      : '切换到闪词',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 根据状态显示不同内容
                    if (controller.state.showCardCategory.value) ...[
                      // 闪词分类（网格布局）
                      Obx(() => GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.5,
                            children: [
                              _buildHorizontalCard(
                                context: context,
                                title: '需巩固',
                                count: controller.state.needsReviewCount.value,
                                icon: Icons.schedule,
                                iconColor: AppTheme.statusNeedsReview,
                                onTap: () =>
                                    controller.navigateToFeynmanLearning(
                                        pageType: StudyCenterPageType.weakCards,
                                        statusFilter: 'NEEDS_REVIEW'),
                                isDark: isDark,
                                cardColor: cardColor,
                                borderColor: borderColor,
                              ),
                              _buildHorizontalCard(
                                context: context,
                                title: '需改进',
                                count: controller.state.needsImproveCount.value,
                                icon: Icons.trending_up,
                                iconColor: AppTheme.statusNeedsImprove,
                                onTap: () =>
                                    controller.navigateToFeynmanLearning(
                                        pageType: StudyCenterPageType.weakCards,
                                        statusFilter: 'NEEDS_IMPROVE'),
                                isDark: isDark,
                                cardColor: cardColor,
                                borderColor: borderColor,
                              ),
                              _buildHorizontalCard(
                                context: context,
                                title: '未掌握',
                                count: controller.state.notMasteredCount.value,
                                icon: Icons.error_outline,
                                iconColor: AppTheme.statusNotMastered,
                                onTap: () =>
                                    controller.navigateToFeynmanLearning(
                                        pageType: StudyCenterPageType.weakCards,
                                        statusFilter: 'NOT_MASTERED'),
                                isDark: isDark,
                                cardColor: cardColor,
                                borderColor: borderColor,
                              ),
                              _buildHorizontalCard(
                                context: context,
                                title: '全部词条',
                                count: controller.state.totalCardsCount.value,
                                icon: Icons.library_books,
                                iconColor: Colors.blue,
                                onTap: () =>
                                    controller.navigateToFeynmanLearning(
                                        pageType: StudyCenterPageType.allCards),
                                isDark: isDark,
                                cardColor: cardColor,
                                borderColor: borderColor,
                              ),
                            ],
                          )),
                    ] else ...[
                      // 笔记分类（列表）- 从API获取真实数据
                      Obx(() {
                        if (controller.state.cardsByNote.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.note_outlined,
                                    size: 48,
                                    color: isDark
                                        ? Colors.grey[600]
                                        : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '暂无笔记',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '创建笔记后，词条会按笔记分类显示',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.grey[600]
                                          : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            ...controller.state.cardsByNote.map((noteItem) =>
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildNoteCategoryCard(
                                    context: context,
                                    noteTitle: noteItem.noteTitle,
                                    totalCount: noteItem.totalCount,
                                    needsReviewCount: noteItem.needsReviewCount,
                                    masteredCount: noteItem.masteredCount,
                                    needsImproveCount:
                                        noteItem.needsImproveCount,
                                    notMasteredCount: noteItem.notMasteredCount,
                                    onTap: () {
                                      // 智能跳转：有词条直接学习，无词条进入详情页
                                      controller.handleNoteCardTap(
                                        noteItem.noteId,
                                        noteItem.noteTitle,
                                        noteItem.totalCount,
                                      );
                                    },
                                    isDark: isDark,
                                    cardColor: cardColor,
                                    borderColor: borderColor,
                                  ),
                                )),
                          ],
                        );
                      }),
                    ],
                  ],
                )),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  /// 构建今日复习突出显示卡片
  Widget _buildTodayReviewHighlightCard({
    required BuildContext context,
    required StudyCenterController controller,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => controller.navigateToFeynmanLearning(
          pageType: StudyCenterPageType.todayReview),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667EEA),
              Color(0xFF764BA2),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.local_fire_department,
                              color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            '今日需要复习',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _showTodayReviewExplanation(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Obx(() => Row(
                  children: [
                    Text(
                      '${controller.state.todayReviewCount.value}',
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '个词条',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w400),
                          ),
                          const Text(
                            '需要复习',
                            style:
                                TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 20),
            Obx(() => Row(
                  children: [
                    _buildQuickStat(
                        '需巩固',
                        '${controller.state.needsReviewCount.value}',
                        AppTheme.statusNeedsReview),
                    const SizedBox(width: 12),
                    _buildQuickStat(
                        '需改进',
                        '${controller.state.needsImproveCount.value}',
                        AppTheme.statusNeedsImprove),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  /// 构建网格卡片（用于闪词分类）
  Widget _buildHorizontalCard({
    required BuildContext context,
    required String title,
    String? subtitle,
    required int count,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
  }) {
    final textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$label $value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示今日复习说明
  void _showTodayReviewExplanation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.statusNeedsReview.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_fire_department,
                      color: AppTheme.statusNeedsReview,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '今日需要复习',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                '根据复习计划，今天应该复习的词条。',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '包含状态：',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatusItem(
                        '需巩固', '上次学习评分70-89分', AppTheme.statusNeedsReview),
                    const SizedBox(height: 6),
                    _buildStatusItem(
                        '需改进', '上次学习评分50-69分', AppTheme.statusNeedsImprove),
                    const SizedBox(height: 6),
                    _buildStatusItem(
                        '未掌握', '上次学习评分0-49分', AppTheme.statusNotMastered),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.statusNeedsReview,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '知道了',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(String status, String desc, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$status：$desc',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建功能入口卡片
  Widget _buildFunctionCard({
    required BuildContext context,
    required String title,
    String? subtitle,
    required int count,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
  }) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[600] : Colors.grey[600];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            // 图标
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            // 文字内容
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 数量
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 箭头
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: secondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建笔记分类卡片
  Widget _buildNoteCategoryCard({
    required BuildContext context,
    required String noteTitle,
    required int totalCount,
    required int needsReviewCount,
    required int masteredCount,
    int? needsImproveCount,
    int? notMasteredCount,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
  }) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[600] : Colors.grey[600];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noteTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (needsReviewCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.statusNeedsReview.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '需巩固：$needsReviewCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.statusNeedsReview,
                            ),
                          ),
                        ),
                      if (needsImproveCount != null && needsImproveCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.statusNeedsImprove.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '需改进：$needsImproveCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.statusNeedsImprove,
                            ),
                          ),
                        ),
                      if (notMasteredCount != null && notMasteredCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.statusNotMastered.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '未掌握：$notMasteredCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.statusNotMastered,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.statusMastered.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '已掌握：$masteredCount',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.statusMastered,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$totalCount个词条',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: secondaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建今日复习页面
  Widget _buildTodayReviewPage(
      BuildContext context, StudyCenterController controller, bool isDark) {
    return _buildCardListPage(
      context: context,
      controller: controller,
      isDark: isDark,
      title: '今日复习',
      cards: controller.state.todayReviewCards,
      total: controller.state.todayReviewCardsTotal,
      onRefresh: () async {
        await controller.refreshCurrentPage();
      },
    );
  }

  /// 构建薄弱词条页面（需巩固、需改进、未掌握共用此页面）
  Widget _buildWeakCardsPage(
      BuildContext context, StudyCenterController controller, bool isDark) {
    // 根据状态筛选显示不同的标题
    return Obx(() {
      String title = '薄弱词条';
      String? subtitle;

      final statusFilter = controller.state.weakCardsStatusFilter.value;
      if (statusFilter != null) {
        switch (statusFilter) {
          case 'NEEDS_REVIEW':
            title = '需巩固词条';
            subtitle = '需要巩固复习的词条（70-89分）';
            break;
          case 'NEEDS_IMPROVE':
            title = '需改进词条';
            subtitle = '需要改进的词条（60-69分）';
            break;
          case 'NOT_MASTERED':
            title = '未掌握词条';
            subtitle = '未掌握的词条（0-59分）';
            break;
          default:
            title = '薄弱词条';
            subtitle = '需改进和未掌握的词条';
        }
      } else {
        subtitle = '需改进和未掌握的词条';
      }

      return _buildCardListPage(
        context: context,
        controller: controller,
        isDark: isDark,
        title: title,
        subtitle: subtitle,
        cards: controller.state.weakCards,
        total: controller.state.weakCardsTotal,
        onRefresh: () async {
          await controller.refreshCurrentPage();
        },
      );
    });
  }

  /// 构建已掌握词条页面
  Widget _buildMasteredCardsPage(
      BuildContext context, StudyCenterController controller, bool isDark) {
    return _buildCardListPage(
      context: context,
      controller: controller,
      isDark: isDark,
      title: '已掌握词条',
      cards: controller.state.masteredCards,
      total: controller.state.masteredCardsTotal,
      onRefresh: () async {
        await controller.refreshCurrentPage();
      },
    );
  }

  /// 构建全部词条页面
  Widget _buildAllCardsPage(
      BuildContext context, StudyCenterController controller, bool isDark) {
    return _buildCardListPage(
      context: context,
      controller: controller,
      isDark: isDark,
      title: '全部词条',
      cards: controller.state.allCards,
      total: controller.state.allCardsTotal,
      onRefresh: () async {
        await controller.refreshCurrentPage();
      },
    );
  }

  /// 构建按笔记分类页面
  Widget _buildByNotePage(
      BuildContext context, StudyCenterController controller, bool isDark) {
    return _buildCardsByNotePage(
      context: context,
      controller: controller,
      isDark: isDark,
    );
  }

  /// 构建词条列表页面
  Widget _buildCardListPage({
    required BuildContext context,
    required StudyCenterController controller,
    required bool isDark,
    required String title,
    String? subtitle,
    required RxList cards,
    required RxInt total,
    required Future<void> Function() onRefresh,
  }) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Column(
      children: [
        // AppBar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => controller.backToMain(),
                color: textColor,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Obx(() => Text(
                    '${total.value}个词条',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryColor,
                    ),
                  )),
            ],
          ),
        ),
        // 内容区域
        Expanded(
          child: Obx(() {
            if (controller.state.isLoading.value && cards.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppTheme.darkPrimary,
                ),
              );
            }

            if (cards.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: secondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无词条',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index] as FlashCardListItem;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCardListItem(
                      controller: controller,
                      isDark: isDark,
                      card: card,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  /// 构建词条列表项
  Widget _buildCardListItem({
    required StudyCenterController controller,
    required bool isDark,
    required FlashCardListItem card,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryColor,
  }) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (card.status.toUpperCase()) {
      case 'MASTERED':
        statusColor = AppTheme.statusMastered;
        statusText = '已掌握';
        statusIcon = Icons.check_circle;
        break;
      case 'NEEDS_REVIEW':
        statusColor = AppTheme.statusNeedsReview;
        statusText = '需巩固';
        statusIcon = Icons.schedule;
        break;
      case 'NEEDS_IMPROVE':
        statusColor = AppTheme.statusNeedsImprove;
        statusText = '需改进';
        statusIcon = Icons.trending_up;
        break;
      case 'NOT_MASTERED':
        statusColor = AppTheme.statusNotMastered;
        statusText = '未掌握';
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusText = '未学习';
        statusIcon = Icons.help_outline;
    }

    return GestureDetector(
      onTap: () => controller.handleFlashCardTap(card),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.term,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        card.noteTitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (card.bestScore != null || card.attemptCount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (card.bestScore != null) ...[
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '最高分：${card.bestScore}',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                        if (card.attemptCount > 0) ...[
                          if (card.bestScore != null) const SizedBox(width: 12),
                          Icon(Icons.repeat, size: 14, color: secondaryColor),
                          const SizedBox(width: 4),
                          Text(
                            '学习${card.attemptCount}次',
                            style: TextStyle(
                              fontSize: 12,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: secondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建按笔记分类页面
  Widget _buildCardsByNotePage({
    required BuildContext context,
    required StudyCenterController controller,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[600]! : Colors.grey[400]!;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return Column(
      children: [
        // AppBar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => controller.backToMain(),
                color: textColor,
              ),
              Expanded(
                child: Text(
                  '按笔记分类',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Obx(() => Text(
                    '${controller.state.cardsByNoteTotal.value}个笔记',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryColor,
                    ),
                  )),
            ],
          ),
        ),
        // 内容区域
        Expanded(
          child: Obx(() {
            if (controller.state.isLoading.value &&
                controller.state.cardsByNote.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppTheme.darkPrimary,
                ),
              );
            }

            if (controller.state.cardsByNote.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 64,
                      color: secondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无笔记',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await controller.refreshCurrentPage();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: controller.state.cardsByNote.length,
                itemBuilder: (context, index) {
                  final noteItem = controller.state.cardsByNote[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildNoteCategoryCard(
                      context: context,
                      noteTitle: noteItem.noteTitle,
                      totalCount: noteItem.totalCount,
                      needsReviewCount: noteItem.needsReviewCount,
                      masteredCount: noteItem.masteredCount,
                      needsImproveCount: noteItem.needsImproveCount,
                      notMasteredCount: noteItem.notMasteredCount,
                      onTap: () => controller.handleNoteCardTap(
                        noteItem.noteId,
                        noteItem.noteTitle,
                        noteItem.totalCount,
                      ),
                      isDark: isDark,
                      cardColor: cardColor,
                      borderColor: borderColor,
                    ),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}
