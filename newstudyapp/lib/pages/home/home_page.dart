import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:newstudyapp/pages/create_note/create_note_page.dart';
import 'package:newstudyapp/pages/create_note/create_note_controller.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'package:newstudyapp/pages/note_creation/note_creation_controller.dart';
import 'package:newstudyapp/models/note_models.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // 大标题
                _buildHeader(isDark),
                const SizedBox(height: 40),

                // 今日复习卡片
                _buildTodayReviewCard(isDark),
                const SizedBox(height: 24),

                // 我的笔记区域
                _buildNotesSection(isDark),
                const SizedBox(height: 24),

                // 学习统计
                _buildStatsSection(isDark),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 将所有原来的方法改为实例方法
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '早上好';
    } else if (hour < 18) {
      return '下午好';
    } else {
      return '晚上好';
    }
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '准备好学习了吗？',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayReviewCard(bool isDark) {
    return Obx(() => _HomePageHelper.buildTodayReviewCard(
          isDark,
          statistics: controller.state.todayReviewStatistics.value,
          onTap: controller.navigateToReview,
        ));
  }

  Widget _buildNotesSection(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '我的笔记',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
            ),
            TextButton(
              onPressed: () {
                print('[HomePage] 点击查看全部按钮');
                try {
                  print('[HomePage] 准备跳转到: ${AppRoutes.notes}');
                  Get.toNamed(AppRoutes.notes);
                  print('[HomePage] 跳转完成');
                } catch (e, stackTrace) {
                  print('[HomePage] 跳转失败: $e');
                  print('[HomePage] 堆栈: $stackTrace');
                  Get.snackbar(
                    '错误',
                    '无法打开笔记列表：$e',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
              child: Text('查看全部',
                  style: TextStyle(color: secondaryColor, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          // 显示错误信息
          if (controller.state.errorMessage.value != null) {
            return Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.state.errorMessage.value ?? '未知错误',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => controller.loadNotes(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (controller.state.isLoading.value) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (controller.state.notes.isEmpty) {
            return _HomePageHelper.buildAddNoteButton(
                isDark, _showCreateNoteSheet);
          }

          // 显示笔记列表（最多显示前3个）
          final displayNotes = controller.state.notes.take(3).toList();
          final colors = [
            const Color(0xFF4ECDC4),
            const Color(0xFFFF6B6B),
            const Color(0xFFFFD93D),
          ];

          return Column(
            children: [
              ...displayNotes.asMap().entries.map((entry) {
                final index = entry.key;
                final note = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index < displayNotes.length - 1 ? 12 : 12),
                  child: _buildNoteCard(
                    isDark: isDark,
                    noteId: note.id,
                    title: note.title ?? '无标题',
                    progress: note.masteredCount,
                    total: note.termCount,
                    reviewCount: note.reviewCount,
                    color: colors[index % colors.length],
                  ),
                );
              }),
              _HomePageHelper.buildAddNoteButton(isDark, _showCreateNoteSheet),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildNoteCard({
    required bool isDark,
    required String noteId,
    required String title,
    required int progress,
    required int total,
    required int reviewCount,
    required Color color,
  }) {
    final percentage = total > 0 ? (progress / total * 100).toInt() : 0;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[600] : Colors.grey[600];

    return GestureDetector(
      onTap: () {
        controller.navigateToNoteDetail(noteId);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor),
                  ),
                ),
                if (reviewCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$reviewCount 待复习',
                      style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$progress',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: color),
                          ),
                          Text(
                            '/$total',
                            style:
                                TextStyle(fontSize: 16, color: secondaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('已掌握',
                          style:
                              TextStyle(fontSize: 12, color: secondaryColor)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: total > 0 ? progress / total : 0,
                            strokeWidth: 5,
                            backgroundColor:
                                isDark ? Colors.grey[800] : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isDark) {
    return Obx(() => _HomePageHelper.buildStatsSection(
          isDark,
          statistics: controller.state.statistics.value,
        ));
  }

  void _showCreateNoteSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateNoteBottomSheet(isDark: isDark),
    );
  }
}

// 辅助类，包含所有原来的方法实现（静态方法）
class _HomePageHelper {
  static Widget buildTodayReviewCard(
    bool isDark, {
    TodayReviewStatisticsResponse? statistics,
    VoidCallback? onTap,
  }) {
    // 使用统计数据，如果没有则显示默认值
    final total = statistics?.total ?? 0;
    final needsReview = statistics?.needsReview ?? 0;
    final needsImprove = statistics?.needsImprove ?? 0;

    return GestureDetector(
      onTap: onTap,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  child: const Icon(Icons.arrow_forward,
                      color: Colors.white, size: 20),
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
                            fontWeight: FontWeight.w400),
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
                _buildQuickStat('困难', '$needsReview', Colors.orange),
                const SizedBox(width: 12),
                _buildQuickStat('需改进', '$needsImprove', Colors.yellow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildQuickStat(String label, String value, Color color) {
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
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  static Widget buildAddNoteButton(
      bool isDark, Function(BuildContext, bool) showCreateNoteSheet) {
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final iconColor = isDark ? Colors.grey[600] : Colors.grey[500];

    return GestureDetector(
      onTap: () {
        final context = Get.context;
        if (context != null) {
          showCreateNoteSheet(context, isDark);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: borderColor!, width: 1, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              '创建新笔记',
              style: TextStyle(
                  color: iconColor, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildStatsSection(
    bool isDark, {
    TodayReviewStatisticsResponse? todayReviewStats,
    LearningStatisticsResponse? learningStats,
  }) {
    final textColor = isDark ? Colors.white : Colors.black;
    
    // 今日复习统计部分
    final totalToday = todayReviewStats?.total ?? 0;
    final needsReviewToday = todayReviewStats?.needsReview ?? 0;
    final needsImproveToday = todayReviewStats?.needsImprove ?? 0;

    // 全局学习统计部分
    final consecutiveDays = learningStats?.consecutiveDays ?? 0;
    final mastered = learningStats?.mastered ?? 0;
    final totalMinutes = learningStats?.totalMinutes ?? 0;
    final totalTerms = learningStats?.totalTerms ?? 0;

    // 格式化累计时长：分钟转换为小时
    String formatDuration(int minutes) {
      if (minutes < 60) {
        return '${minutes}分钟';
      }
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '${hours}h';
      }
      return '${hours}.${(mins / 60 * 10).toInt()}h';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 全局学习统计
        Text(
          '全局统计',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 16),
        
        // 全局学习统计
        Text(
          '全局统计',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                  isDark, Icons.local_fire_department_rounded,
                  '$consecutiveDays',
                  '连续天数',
                  const Color(0xFFFF6B6B))),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(isDark, Icons.psychology_rounded,
                  '$mastered', '已掌握', const Color(0xFF4ECDC4))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(isDark, Icons.timer_outlined,
                  formatDuration(totalMinutes), '累计时长', const Color(0xFFFFD93D))),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(isDark, Icons.library_books_outlined,
                  '$totalTerms', '累计学习', const Color(0xFF95E1D3))),
          ],
        ),
        
        // 今日复习统计
        if (totalToday > 0) ... [
          const SizedBox(height: 32),
          Text(
            '今日复习',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(isDark, Icons.notification_important_outlined,
                      '$needsReviewToday', '需复习', const Color(0xFFFF9C27B0))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildStatCard(isDark, Icons.build_circle_outlined,
                      '$needsImproveToday', '需改进', const Color(0xFFE67E22))),
            ],
          ),
        ],
      ],
    );
  }
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '${hours}h';
      }
      return '${hours}.${(mins / 60 * 10).toInt()}h';
    }
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '${hours}h';
      }
      return '${hours}.${(mins / 60 * 10).toInt()}h';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '学习统计',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    isDark,
                    Icons.local_fire_department_rounded,
                    '$consecutiveDays',
                    '连续天数',
                    const Color(0xFFFF6B6B))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(isDark, Icons.psychology_rounded,
                    '$mastered', '已掌握', const Color(0xFF4ECDC4))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    isDark,
                    Icons.timer_outlined,
                    formatDuration(totalMinutes),
                    '累计时长',
                    const Color(0xFFFFD93D))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(isDark, Icons.library_books_outlined,
                    '$totalTerms', '累计学习', const Color(0xFF95E1D3))),
          ],
        ),
      ],
    );
  }

  static Widget _buildStatCard(
      bool isDark, IconData icon, String value, String label, Color color) {
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: secondaryColor)),
        ],
      ),
    );
  }
}

// 创建笔记底部选择器
class _CreateNoteBottomSheet extends StatelessWidget {
  final bool isDark;

  const _CreateNoteBottomSheet({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final secondaryColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部指示条
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 标题
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '创建笔记',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '选择创建方式',
                style: TextStyle(fontSize: 14, color: secondaryColor),
              ),
              const SizedBox(height: 28),

              // 文档类
              _buildCategorySection(
                isDark: isDark,
                textColor: textColor,
                title: '文档',
                icon: Icons.description_outlined,
                iconColor: const Color(0xFF4ECDC4),
                items: [
                  _SourceItem(
                      icon: Icons.picture_as_pdf,
                      label: 'PDF文档',
                      color: const Color(0xFFE74C3C)),
                  _SourceItem(
                      icon: Icons.article_outlined,
                      label: 'Word文档',
                      color: const Color(0xFF2980B9)),
                  _SourceItem(
                      icon: Icons.insert_drive_file_outlined,
                      label: '其他文档',
                      color: const Color(0xFF95A5A6)),
                ],
              ),
              const SizedBox(height: 20),

              // 图片类
              _buildCategorySection(
                isDark: isDark,
                textColor: textColor,
                title: '图片',
                icon: Icons.image_outlined,
                iconColor: const Color(0xFFFFD93D),
                items: [
                  _SourceItem(
                      icon: Icons.camera_alt_outlined,
                      label: '拍照',
                      color: const Color(0xFF3498DB)),
                  _SourceItem(
                      icon: Icons.photo_library_outlined,
                      label: '上传图片',
                      color: const Color(0xFF9B59B6)),
                ],
              ),
              const SizedBox(height: 20),

              // 自定义文本
              _buildCategorySection(
                isDark: isDark,
                textColor: textColor,
                title: '自定义',
                icon: Icons.edit_outlined,
                iconColor: const Color(0xFF95E1D3),
                items: [
                  _SourceItem(
                      icon: Icons.text_fields,
                      label: '自定义文本',
                      color: const Color(0xFF1ABC9C)),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection({
    required bool isDark,
    required Color textColor,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<_SourceItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map((item) => _buildSourceButton(isDark, textColor, item))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSourceButton(bool isDark, Color textColor, _SourceItem item) {
    final cardColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5);

    return GestureDetector(
      onTap: () async {
        final label = item.label;

        // 1. 自定义文本 (BottomSheet)
        if (label == '自定义文本') {
          Get.put(CreateNoteController());
          final result = await Get.bottomSheet(
            const CreateNotePage(),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            enableDrag: true,
          );
          if (result != null) Get.back();
          return;
        }

        // 2. 文档、图片 (进入 NoteCreationPage 解析流程)
        if (['PDF文档', 'Word文档', '其他文档', '上传图片', '拍照'].contains(label)) {
          final creationController = Get.put(NoteCreationController());
          Get.back(); // 关闭当前源选择弹窗

          if (label == '上传图片') {
            creationController.pickImage(ImageSource.gallery);
          } else if (label == '拍照') {
            creationController.pickImage(ImageSource.camera);
          } else {
            // 文档类直接跳转，由用户在页面内点击选择
            Get.toNamed(AppRoutes.noteCreation);
          }
          return;
        }

        // 4. 其他未实现功能
        Get.back();
        Get.snackbar(
          '提示',
          '${item.label}功能正在开发中',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: item.color,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 创建源项数据类
class _SourceItem {
  final IconData icon;
  final String label;
  final Color color;

  const _SourceItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
