import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/review/review_controller.dart';
import 'package:newstudyapp/pages/review/review_state.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:newstudyapp/models/note_models.dart';

class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReviewController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final Color secondaryColor = (isDark ? Colors.grey[500] : Colors.grey[600])!;
    final Color cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final Color borderColor = (isDark ? Colors.grey[800] : Colors.grey[300])!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                  const SizedBox(height: 32),

                  // 今日复习统计卡片
                  Obx(() => _buildTodayReviewCard(
                        controller,
                        isDark,
                        controller.state.todayReviewStatistics.value,
                      )),
                  const SizedBox(height: 24),

                  // 筛选标签
                  _buildFilterTabs(controller, isDark),
                  const SizedBox(height: 24),

                  // 卡片列表
                  Obx(() {
                    if (controller.state.isLoading.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (controller.state.errorMessage.value != null) {
                      return _buildErrorView(
                        controller,
                        isDark,
                        controller.state.errorMessage.value!,
                      );
                    }

                    final filteredCards = controller.state.filteredCards;
                    if (filteredCards.isEmpty) {
                      return _buildEmptyView(isDark, controller.state.currentFilter.value);
                    }

                    // 按笔记分组显示
                    if (controller.state.currentFilter.value == ReviewFilterType.all) {
                      return _buildGroupedByNoteView(
                        controller,
                        isDark,
                        controller.state.cardsByNote,
                      );
                    }

                    // 列表显示
                    return _buildCardsList(controller, isDark, filteredCards);
                  }),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建今日复习统计卡片
  Widget _buildTodayReviewCard(
    ReviewController controller,
    bool isDark,
    TodayReviewStatisticsResponse? statistics,
  ) {
    final total = statistics?.total ?? 0;
    final needsReview = statistics?.needsReview ?? 0;
    final needsImprove = statistics?.needsImprove ?? 0;

    return GestureDetector(
      onTap: () {
        controller.setFilter(ReviewFilterType.today);
      },
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '今日复习',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '个词条',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        '等待复习',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildQuickStat('待复习', '$needsReview', Colors.orange),
                const SizedBox(width: 12),
                _buildQuickStat('需改进', '$needsImprove', Colors.yellow),
              ],
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
            '$value $label',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建筛选标签
  Widget _buildFilterTabs(ReviewController controller, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final selectedColor = AppTheme.darkPrimary;
    final Color unselectedColor = (isDark ? Colors.grey[700] : Colors.grey[300])!;
    final selectedTextColor = Colors.white;
    final Color unselectedTextColor = (isDark ? Colors.grey[400] : Colors.grey[600])!;

    return Obx(() {
      final currentFilter = controller.state.currentFilter.value;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(
              '今日复习',
              ReviewFilterType.today,
              currentFilter,
              selectedColor,
              unselectedColor,
              selectedTextColor,
              unselectedTextColor,
              () => controller.setFilter(ReviewFilterType.today),
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              '困难词条',
              ReviewFilterType.difficult,
              currentFilter,
              selectedColor,
              unselectedColor,
              selectedTextColor,
              unselectedTextColor,
              () => controller.setFilter(ReviewFilterType.difficult),
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              '已掌握',
              ReviewFilterType.mastered,
              currentFilter,
              selectedColor,
              unselectedColor,
              selectedTextColor,
              unselectedTextColor,
              () => controller.setFilter(ReviewFilterType.mastered),
            ),
            const SizedBox(width: 12),
            _buildFilterChip(
              '全部',
              ReviewFilterType.all,
              currentFilter,
              selectedColor,
              unselectedColor,
              selectedTextColor,
              unselectedTextColor,
              () => controller.setFilter(ReviewFilterType.all),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip(
    String label,
    ReviewFilterType filter,
    ReviewFilterType currentFilter,
    Color selectedColor,
    Color unselectedColor,
    Color selectedTextColor,
    Color unselectedTextColor,
    VoidCallback onTap,
  ) {
    final isSelected = filter == currentFilter;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? selectedTextColor : unselectedTextColor,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 构建卡片列表
  Widget _buildCardsList(
    ReviewController controller,
    bool isDark,
    List<ReviewFlashCardResponse> cards,
  ) {
    final textColor = isDark ? Colors.white : Colors.black;
    final Color secondaryColor = (isDark ? Colors.grey[500] : Colors.grey[600])!;
    final Color cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final Color borderColor = (isDark ? Colors.grey[800] : Colors.grey[300])!;

    return Column(
      children: cards.map((card) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCardItem(
            controller,
            isDark,
            card,
            textColor,
            secondaryColor,
            cardColor,
            borderColor,
          ),
        );
      }).toList(),
    );
  }

  /// 构建单个卡片项
  Widget _buildCardItem(
    ReviewController controller,
    bool isDark,
    ReviewFlashCardResponse card,
    Color textColor,
    Color secondaryColor,
    Color cardColor,
    Color borderColor,
  ) {
    final statusColor = _getStatusColor(card.status);
    final statusText = _getStatusText(card.status);

    return GestureDetector(
      onTap: () => controller.startLearning(card.noteId, card.term),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.term,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (card.noteTitle != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.note_outlined, size: 14, color: secondaryColor),
                  const SizedBox(width: 6),
                  Text(
                    card.noteTitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            ],
            if (card.lastReviewedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: secondaryColor),
                  const SizedBox(width: 6),
                  Text(
                    '上次学习：${_formatTime(card.lastReviewedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.startLearning(card.noteId, card.term),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '开始学习',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建按笔记分组的视图
  Widget _buildGroupedByNoteView(
    ReviewController controller,
    bool isDark,
    Map<String, List<ReviewFlashCardResponse>> cardsByNote,
  ) {
    final textColor = isDark ? Colors.white : Colors.black;
    final Color secondaryColor = (isDark ? Colors.grey[500] : Colors.grey[600])!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cardsByNote.entries.map((entry) {
        final noteId = entry.key;
        final cards = entry.value;
        final firstCard = cards.first;
        final noteTitle = firstCard.noteTitle ?? '未命名笔记';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.note, size: 18, color: AppTheme.darkPrimary),
                  const SizedBox(width: 8),
                  Text(
                    noteTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.darkPrimary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cards.length}个词条',
                      style: TextStyle(
                        color: AppTheme.darkPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...cards.map((card) {
              final Color cardColorForItem = isDark ? Colors.grey[900]! : Colors.white;
              final Color borderColorForItem = (isDark ? Colors.grey[800] : Colors.grey[300])!;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 20),
                child: _buildCardItem(
                  controller,
                  isDark,
                  card,
                  textColor,
                  secondaryColor,
                  cardColorForItem,
                  borderColorForItem,
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }

  /// 构建空状态视图
  Widget _buildEmptyView(bool isDark, ReviewFilterType filter) {
    final textColor = isDark ? Colors.white : Colors.black;
    final Color secondaryColor = (isDark ? Colors.grey[500] : Colors.grey[600])!;

    String message;
    IconData icon;
    switch (filter) {
      case ReviewFilterType.today:
        message = '今日没有需要复习的词条\n继续保持！';
        icon = Icons.check_circle_outline;
        break;
      case ReviewFilterType.difficult:
        message = '没有困难词条\n太棒了！';
        icon = Icons.celebration_outlined;
        break;
      case ReviewFilterType.mastered:
        message = '还没有已掌握的词条\n开始学习吧！';
        icon = Icons.school_outlined;
        break;
      case ReviewFilterType.all:
        message = '还没有学习记录\n创建笔记开始学习吧！';
        icon = Icons.note_add_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            Icon(icon, size: 64, color: secondaryColor),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView(ReviewController controller, bool isDark, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: controller.refresh,
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取状态颜色
  Color _getStatusColor(String status) {
    switch (status) {
      case 'mastered':
        return Colors.green;
      case 'needsReview':
        return Colors.orange;
      case 'needsImprove':
        return Colors.yellow;
      case 'notStarted':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// 获取状态文本
  String _getStatusText(String status) {
    switch (status) {
      case 'mastered':
        return '已掌握';
      case 'needsReview':
        return '待复习';
      case 'needsImprove':
        return '需改进';
      case 'notStarted':
        return '未开始';
      default:
        return status;
    }
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}

