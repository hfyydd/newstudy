import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:newstudyapp/pages/create_note/create_note_page.dart';
import 'package:newstudyapp/pages/create_note/create_note_controller.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'package:newstudyapp/pages/note_creation/note_creation_controller.dart';
import 'package:newstudyapp/models/note_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  late HomeController _homeController;

  @override
  void initState() {
    super.initState();
    _homeController = Get.put(HomeController());

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _homeController.refreshNotes(),
          color: AppTheme.darkPrimary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // 确保即使内容少也能下拉
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
                  // 学习统计
                  _buildStatsSection(isDark),
                  const SizedBox(height: 24),
                  // 我的笔记区域（放在学习统计之后，降低权重）
                  _buildNotesSection(isDark),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: _buildAnimatedFAB(isDark),
    );
  }

  Widget _buildAnimatedFAB(bool isDark) {
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667EEA),
                  Color(0xFF764BA2),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () {
                _showCreateNoteSheet(context, isDark);
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                Icons.add,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCreateNoteSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CreateNoteBottomSheet(isDark: isDark),
    );
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

  Widget _buildTodayReviewCard(bool isDark) {
    return GestureDetector(
      onTap: () {
        // 直接跳转到费曼学习页面
        _homeController.navigateToTodayReviewFeynmanLearning();
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
                      '${_homeController.todayReviewCount.value}',
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
                        '${_homeController.needsReviewCount.value}',
                        AppTheme.statusNeedsReview),
                    const SizedBox(width: 12),
                    _buildQuickStat(
                        '需改进',
                        '${_homeController.needsImproveCount.value}',
                        AppTheme.statusNeedsImprove),
                  ],
                )),
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
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// 显示今日复习说明（与学习中心保持一致）
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

  Widget _buildNotesSection(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;

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
            Obx(() => Text(
                  '共 ${_homeController.totalNotes.value} 条',
                  style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[600]),
                )),
          ],
        ),
        const SizedBox(height: 16),
        Obx(() {
          final isLoading = _homeController.isLoading.value;
          final notes = _homeController.notes.toList();

          if (isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (notes.isEmpty) {
            return _buildEmptyNotes(isDark);
          }

          return Column(
            children: [
              ...notes.map((note) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: Key(note.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        // 调用控制器的删除方法，它会处理确认对话框
                        await _homeController.deleteNote(note.id, note.title);
                        // 返回 false 因为我们在 deleteNote 中已经手动从列表移除了
                        return false;
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      child: _buildNoteCard(
                        isDark: isDark,
                        note: note,
                      ),
                    ),
                  )),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildEmptyNotes(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor!, width: 1),
      ),
      child: Column(
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 48,
            color: secondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有笔记',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建你的第一条笔记开始学习吧',
            style: TextStyle(
              fontSize: 14,
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard({
    required bool isDark,
    required note,
  }) {
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[600] : Colors.grey[600];
    final percentage = note.flashCardCount > 0
        ? (note.masteredCount / note.flashCardCount * 100).toInt()
        : 0;

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.noteDetail,
          arguments: {
            'noteId': note.id,
          },
        );
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
                Expanded(
                  child: Text(
                    note.title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor),
                  ),
                ),
                // 显示优先级最高的状态标签（未掌握 > 需改进 > 需巩固）
                if (note.notMasteredCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.statusNotMastered.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${note.notMasteredCount} 未掌握',
                      style: TextStyle(
                          color: AppTheme.statusNotMastered,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  )
                else if (note.needsImproveCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.statusNeedsImprove.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${note.needsImproveCount} 需改进',
                      style: TextStyle(
                          color: AppTheme.statusNeedsImprove,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  )
                else if (note.needsReviewCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.statusNeedsReview.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${note.needsReviewCount} 需巩固',
                      style: TextStyle(
                          color: AppTheme.statusNeedsReview,
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
                            '${note.masteredCount}',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.statusMastered),
                          ),
                          Text(
                            '/${note.flashCardCount}',
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
                            value: note.flashCardCount > 0
                                ? note.masteredCount / note.flashCardCount
                                : 0,
                            strokeWidth: 5,
                            backgroundColor:
                                isDark ? Colors.grey[800] : Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.statusMastered),
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
    final textColor = isDark ? Colors.white : Colors.black;

    return Obx(() {
      final streak = _homeController.streakDays.value;
      final active7d = _homeController.activeDays7d.value;
      final trend = _homeController.trend7d.toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '学习统计',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          // 只保留节奏相关指标，拆分为两个卡片：连续学习 & 近7天活跃
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  isDark: isDark,
                  icon: Icons.local_fire_department_rounded,
                  title: '连续学习',
                  value: '${streak}天',
                  subtitle: '保持学习习惯',
                  color: const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  isDark: isDark,
                  icon: Icons.event_available_outlined,
                  title: '近7天活跃',
                  value: '$active7d天',
                  subtitle: '最近一周学习天数',
                  color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrendCard(isDark: isDark, trend: trend),
        ],
      );
    });
  }

  Widget _buildMetricCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    double? progress,
  }) {
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (progress != null)
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(fontSize: 13, color: secondaryColor),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: secondaryColor),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            _buildProgressBar(isDark: isDark, progress: progress, color: color),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressMetricCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required double progress,
  }) {
    return _buildMetricCard(
      isDark: isDark,
      icon: icon,
      title: title,
      value: value,
      subtitle: subtitle,
      color: color,
      progress: progress,
    );
  }

  Widget _buildProgressBar({
    required bool isDark,
    required double progress,
    required Color color,
  }) {
    final bgColor = isDark ? Colors.grey[800] : Colors.grey[200];
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendCard({
    required bool isDark,
    required List<DailyStudyCount> trend,
  }) {
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final maxCount = trend.isNotEmpty
        ? trend.map((e) => e.count).reduce((a, b) => a > b ? a : b)
        : 0;
    final safeMax = maxCount == 0 ? 1 : maxCount;
    const double chartHeight = 96;
    const double barMaxHeight = 60;

    // 计算纵轴刻度值（显示3-4个刻度点）
    List<int> yAxisTicks = [];
    if (safeMax > 0) {
      // 向上取整到合适的值
      int roundedMax = safeMax;
      if (safeMax <= 5) {
        roundedMax = 5;
        yAxisTicks = [0, 2, 4, 5];
      } else if (safeMax <= 10) {
        roundedMax = 10;
        yAxisTicks = [0, 5, 10];
      } else if (safeMax <= 20) {
        roundedMax = 20;
        yAxisTicks = [0, 10, 20];
      } else if (safeMax <= 50) {
        roundedMax = ((safeMax / 10).ceil() * 10);
        int step = roundedMax ~/ 4;
        yAxisTicks = [0, step, step * 2, step * 3, roundedMax];
      } else {
        roundedMax = ((safeMax / 20).ceil() * 20);
        int step = roundedMax ~/ 4;
        yAxisTicks = [0, step, step * 2, step * 3, roundedMax];
      }
    } else {
      yAxisTicks = [0, 1];
    }

    // 获取用于计算柱状图高度的最大值（使用纵轴刻度的最大值）
    final chartMax =
        yAxisTicks.isNotEmpty ? yAxisTicks.last.toDouble() : safeMax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '近7天学习趋势',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                '学习次数',
                style: TextStyle(fontSize: 12, color: secondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: chartHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 纵轴刻度标签
                SizedBox(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: yAxisTicks.reversed.map((tick) {
                      return Text(
                        '$tick',
                        style: TextStyle(
                          fontSize: 10,
                          color: secondaryColor,
                          height: 1.0,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                // 图表区域（带参考线）
                Expanded(
                  child: Stack(
                    children: [
                      // 参考线
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: yAxisTicks.reversed.map((tick) {
                          return Container(
                            height: 1,
                            color: (secondaryColor ?? Colors.grey)
                                .withOpacity(0.2),
                          );
                        }).toList(),
                      ),
                      // 柱状图
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: trend.map((item) {
                          final barHeight =
                              (item.count / chartMax) * barMaxHeight;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: barHeight.clamp(0, barMaxHeight),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                              ? AppTheme.darkPrimary
                                              : AppTheme.lightPrimary)
                                          .withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.date.substring(5),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                iconColor: AppTheme.statusMastered,
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

              // 音频类
              _buildCategorySection(
                isDark: isDark,
                textColor: textColor,
                title: '音频',
                icon: Icons.mic_outlined,
                iconColor: const Color(0xFFFF6B6B),
                items: [
                  _SourceItem(
                      icon: Icons.fiber_manual_record,
                      label: '录制音频',
                      color: const Color(0xFFE74C3C)),
                  _SourceItem(
                      icon: Icons.audiotrack,
                      label: '上传音频',
                      color: const Color(0xFFF39C12)),
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

              // 视频类
              _buildCategorySection(
                isDark: isDark,
                textColor: textColor,
                title: '视频',
                icon: Icons.video_library_outlined,
                iconColor: const Color(0xFFE67E22),
                items: [
                  _SourceItem(
                      icon: Icons.link,
                      label: 'YouTube链接',
                      color: const Color(0xFFFF0000)),
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
        // 如果是自定义文本，从底部弹出创建笔记页面
        if (item.label == '自定义文本') {
          // 在打开 BottomSheet 前注入控制器
          Get.put(CreateNoteController());

          final result = await Get.bottomSheet(
            const CreateNotePage(),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            enableDrag: true,
          );

          // 结束后可以根据需要移除控制器（如果不需要保持状态）
          // Get.delete<CreateNoteController>();

          // 如果创建成功，关闭创建源选择弹窗
          if (result != null) {
            Get.back();
          }
        } else if (item.label == 'PDF文档' ||
            item.label == 'Word文档' ||
            item.label == '其他文档') {
          // 文档类功能：跳转到笔记创建页面，并自动触发文件选择
          Get.back(); // 先关闭弹窗
          await Get.toNamed(AppRoutes.noteCreation);
          // 等待页面加载后自动触发文件选择
          Future.delayed(const Duration(milliseconds: 300), () {
            try {
              final controller = Get.find<NoteCreationController>();
              controller.pickFile();
            } catch (e) {
              // 如果控制器还未初始化，忽略错误
              debugPrint('NoteCreationController not found: $e');
            }
          });
        } else if (item.label == '拍照' || item.label == '上传图片') {
          // 图片类功能：跳转到笔记创建页面，并自动触发图片选择
          Get.back(); // 先关闭弹窗
          await Get.toNamed(AppRoutes.noteCreation);
          // 等待页面加载后自动触发图片选择
          Future.delayed(const Duration(milliseconds: 300), () {
            try {
              final controller = Get.find<NoteCreationController>();
              final imageSource = item.label == '拍照'
                  ? ImageSource.camera
                  : ImageSource.gallery;
              controller.pickImage(imageSource);
            } catch (e) {
              // 如果控制器还未初始化，忽略错误
              debugPrint('NoteCreationController not found: $e');
            }
          });
        } else {
          // 其他功能先关闭弹窗，再显示提示
          Get.back();
          Get.snackbar(
            '提示',
            '${item.label}功能开发中',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: item.color,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
          );
        }
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
