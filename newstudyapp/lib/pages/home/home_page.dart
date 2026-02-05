import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:newstudyapp/pages/create_note/create_note_page.dart';
import 'package:newstudyapp/pages/create_note/create_note_controller.dart';
import 'package:newstudyapp/pages/create_note_from_url/create_note_from_url_page.dart';
import 'package:newstudyapp/pages/create_note_from_url/create_note_from_url_controller.dart';
import 'package:newstudyapp/pages/create_note_from_image/create_note_from_image_controller.dart';
import 'package:newstudyapp/pages/create_note_from_youtube/create_note_from_youtube_page.dart';
import 'package:newstudyapp/pages/create_note_from_youtube/create_note_from_youtube_controller.dart';
import 'package:newstudyapp/pages/create_note_from_bilibili/create_note_from_bilibili_page.dart';
import 'package:newstudyapp/pages/create_note_from_bilibili/create_note_from_bilibili_controller.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'package:newstudyapp/models/note_models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:newstudyapp/services/toast_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
          onRefresh: () async {
            await _homeController.refreshData();
          },
          color: AppTheme.darkPrimary,
        child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(l10n),
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.readyToStudy,
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

  String _getGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return l10n.goodMorning;
    } else if (hour < 18) {
      return l10n.goodAfternoon;
    } else {
      return l10n.goodEvening;
    }
  }

  Widget _buildTodayReviewCard(bool isDark) {
    final l10n = AppLocalizations.of(context)!;
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
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            l10n.todayReview,
                            style: const TextStyle(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.flashCards,
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w400),
                          ),
                          Text(
                            l10n.needReview,
                            style:
                                const TextStyle(fontSize: 14, color: Colors.white70),
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
                        l10n.needsConsolidation,
                        '${_homeController.needsReviewCount.value}',
                        AppTheme.statusNeedsReview),
                    const SizedBox(width: 12),
                    _buildQuickStat(
                        l10n.needsImprovement,
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
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            Flexible(
              child: Text(
                '$label $value',
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示今日复习说明（与学习中心保持一致）
  void _showTodayReviewExplanation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final l10n = AppLocalizations.of(context)!;

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
                      l10n.todayReview,
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
              const SizedBox(height: 16),
              Text(
                l10n.todayReviewExplanation,
                style: TextStyle(
                  fontSize: 14,
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
                      l10n.spacedReviewRules,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildIntervalItem(
                      status: l10n.notMasteredRule,
                      score: l10n.notMasteredScore,
                      interval: l10n.notMasteredInterval,
                      reason: l10n.notMasteredReason,
                      color: AppTheme.statusNotMastered,
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                    const SizedBox(height: 10),
                    _buildIntervalItem(
                      status: l10n.needsImproveRule,
                      score: l10n.needsImproveScore,
                      interval: l10n.needsImproveInterval,
                      reason: l10n.needsImproveReason,
                      color: AppTheme.statusNeedsImprove,
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                    const SizedBox(height: 10),
                    _buildIntervalItem(
                      status: l10n.needsConsolidationRule,
                      score: l10n.needsConsolidationScore,
                      interval: l10n.needsConsolidationInterval,
                      reason: l10n.needsConsolidationReason,
                      color: AppTheme.statusNeedsReview,
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                    const SizedBox(height: 10),
                    _buildIntervalItem(
                      status: l10n.masteredRule,
                      score: l10n.masteredScore,
                      interval: l10n.masteredInterval,
                      reason: l10n.masteredReason,
                      color: AppTheme.statusMastered,
                      textColor: textColor,
                      secondaryColor: secondaryColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.reviewTip,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.gotIt,
                    style: const TextStyle(
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

  /// 构建间隔规则项
  Widget _buildIntervalItem({
    required String status,
    required String score,
    required String interval,
    required String reason,
    required Color color,
    required Color textColor,
    required Color? secondaryColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    '（$score）',
            style: TextStyle(
              fontSize: 12,
                      color: secondaryColor,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      interval,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
            ),
              const SizedBox(height: 2),
              Text(
                reason,
                style: TextStyle(
                  fontSize: 11,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.myNotes,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
            ),
            Obx(() => Text(
                  l10n.totalNotes(_homeController.totalNotes.value),
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

          // 首页只显示前3条笔记
          final displayNotes = notes.take(3).toList();
          final hasMore = notes.length > 3;

          return Column(
            children: [
              ...displayNotes.map((note) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildNoteCard(
                      isDark: isDark,
                      note: note,
                    ),
                  )),
              // 如果超过3条，显示"查看更多"按钮
              if (hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildViewMoreButton(isDark),
                ),
            ],
          );
        }),
      ],
    );
  }

  /// 构建"查看更多"按钮
  Widget _buildViewMoreButton(bool isDark) {
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.notesList);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor!, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.viewMore,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: AppTheme.darkPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyNotes(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final l10n = AppLocalizations.of(context)!;

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
            l10n.noNotesYet,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createFirstNote,
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
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    if (note.notMasteredCount > 0) {
                      return Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.statusNotMastered.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${note.notMasteredCount} ${l10n.notMastered}',
                          style: TextStyle(
                              color: AppTheme.statusNotMastered,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      );
                    } else if (note.needsImproveCount > 0) {
                      return Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.statusNeedsImprove.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${note.needsImproveCount} ${l10n.needsImprovement}',
                          style: TextStyle(
                              color: AppTheme.statusNeedsImprove,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      );
                    } else if (note.needsReviewCount > 0) {
                      return Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.statusNeedsReview.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${note.needsReviewCount} ${l10n.needsConsolidation}',
                          style: TextStyle(
                              color: AppTheme.statusNeedsReview,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
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
                      Builder(builder: (context) {
                        final l10n = AppLocalizations.of(context)!;
                        return Text(l10n.mastered,
                            style:
                                TextStyle(fontSize: 12, color: secondaryColor));
                      }),
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
    final l10n = AppLocalizations.of(context)!;

    return Obx(() {
      final streak = _homeController.streakDays.value;
      final active7d = _homeController.activeDays7d.value;
      final trend = _homeController.trend7d.toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.learningStats,
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
                  title: l10n.consecutiveLearning,
                  value: l10n.consecutiveDays(streak),
                  subtitle: l10n.keepLearningHabit,
                  color: const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  isDark: isDark,
                  icon: Icons.event_available_outlined,
                  title: l10n.last7DaysActive,
                  value: l10n.consecutiveDays(active7d),
                  subtitle: l10n.recentWeekLearningDays,
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
    final l10n = AppLocalizations.of(context)!;

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
                l10n.last7DaysTrend,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                l10n.studyTimes,
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
    final l10n = AppLocalizations.of(context)!;

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
                    l10n.createNote,
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
                l10n.selectCreationMethod,
                style: TextStyle(fontSize: 14, color: secondaryColor),
              ),
              const SizedBox(height: 28),

              // 创建源选项网格
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: [
                  _SourceItem(
                      icon: Icons.picture_as_pdf,
                    label: l10n.pdf,
                    color: const Color(0xFFE74C3C),
                    type: _SourceType.pdf,
                  ),
                  _SourceItem(
                      icon: Icons.audiotrack,
                    label: l10n.audio,
                    color: const Color(0xFFF39C12),
                    type: _SourceType.audio,
              ),
                  _SourceItem(
                icon: Icons.image_outlined,
                    label: l10n.image,
                    color: const Color(0xFF9B59B6),
                    type: _SourceType.image,
                  ),
                  _SourceItem(
                    icon: Icons.language,
                    label: l10n.website,
                    color: const Color(0xFF3498DB),
                    type: _SourceType.website,
              ),
                  _SourceItem(
                    icon: Icons.play_circle_outline,
                    label: l10n.youtube,
                    color: const Color(0xFFFF0000),
                    type: _SourceType.youtube,
              ),
                  _SourceItem(
                    icon: Icons.play_circle_filled,
                    label: l10n.bilibili,
                    color: const Color(0xFFFF6699),
                    type: _SourceType.bilibili,
              ),
                  _SourceItem(
                      icon: Icons.text_fields,
                      label: l10n.customText,
                    color: const Color(0xFF1ABC9C),
                    type: _SourceType.customText,
                  ),
                ]
                    .map((item) => _buildSourceButton(isDark, textColor, item, context))
                    .toList(),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSourceButton(bool isDark, Color textColor, _SourceItem item, BuildContext context) {
    final cardColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF5F5F5);
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () async {
        // 关闭创建源选择弹窗
        Get.back();

        // 根据不同的创建源打开对应的页面
        switch (item.type) {
          case _SourceType.customText:
            // 在打开 BottomSheet 前注入控制器
            Get.put(CreateNoteController());

            await Get.bottomSheet(
              const CreateNotePage(),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              enableDrag: true,
            );
            break;

          case _SourceType.website:
            // 删除旧的控制器（如果存在），确保每次打开都是新实例
            if (Get.isRegistered<CreateNoteFromUrlController>()) {
              Get.delete<CreateNoteFromUrlController>();
            }
            
            // 在打开 BottomSheet 前注入新的控制器
            Get.put(CreateNoteFromUrlController());

            await Get.bottomSheet(
              const CreateNoteFromUrlPage(),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              enableDrag: true,
            );

            // BottomSheet 关闭后，延迟删除控制器
            Future.delayed(const Duration(milliseconds: 300), () {
              if (Get.isRegistered<CreateNoteFromUrlController>()) {
                Get.delete<CreateNoteFromUrlController>();
              }
            });
            break;

          case _SourceType.image:
            // 直接弹出拍照/相册选择框
            _showImageSourceBottomSheet(context, isDark);
            break;

          case _SourceType.youtube:
            // 删除旧的控制器（如果存在），确保每次打开都是新实例
            if (Get.isRegistered<CreateNoteFromYoutubeController>()) {
              Get.delete<CreateNoteFromYoutubeController>();
            }
            
            // 在打开 BottomSheet 前注入新的控制器
            Get.put(CreateNoteFromYoutubeController());

            await Get.bottomSheet(
              const CreateNoteFromYoutubePage(),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              enableDrag: true,
            );

            // BottomSheet 关闭后，延迟删除控制器
            Future.delayed(const Duration(milliseconds: 300), () {
              if (Get.isRegistered<CreateNoteFromYoutubeController>()) {
                Get.delete<CreateNoteFromYoutubeController>();
              }
            });
            break;

          case _SourceType.bilibili:
            // 删除旧的控制器（如果存在），确保每次打开都是新实例
            if (Get.isRegistered<CreateNoteFromBilibiliController>()) {
              Get.delete<CreateNoteFromBilibiliController>();
            }
            
            // 在打开 BottomSheet 前注入新的控制器
            Get.put(CreateNoteFromBilibiliController());

            await Get.bottomSheet(
              const CreateNoteFromBilibiliPage(),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              enableDrag: true,
            );

            // BottomSheet 关闭后，延迟删除控制器
            Future.delayed(const Duration(milliseconds: 300), () {
              if (Get.isRegistered<CreateNoteFromBilibiliController>()) {
                Get.delete<CreateNoteFromBilibiliController>();
              }
            });
            break;

          case _SourceType.pdf:
            // 直接打开文件选择器
            _pickPdfFileAndCreateNote();
            break;

          case _SourceType.audio:
            // 其他功能显示提示
            Get.snackbar(
              l10n.hint,
              l10n.featureInDevelopment(item.label),
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: item.color,
              colorText: Colors.white,
              duration: const Duration(seconds: 2),
              margin: const EdgeInsets.all(16),
              borderRadius: 12,
            );
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
              item.label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示图片源选择底部弹框（拍照/相册）
  void _showImageSourceBottomSheet(
    BuildContext context,
    bool isDark,
  ) {
    final textColor =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
    final borderColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E5);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final l10n = AppLocalizations.of(context)!;

    // 创建控制器（临时使用，选择后立即创建笔记）
    final controller = CreateNoteFromImageController();
    Get.put(controller);

    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部拖拽指示器
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                l10n.selectImage,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // 选择按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildImageSourceOption(
                      isDark: isDark,
                      textColor: textColor,
                      borderColor: borderColor,
                      icon: Icons.camera_alt,
                      label: l10n.takePhoto,
                      onTap: () async {
                        Get.back(); // 关闭选择框
                        await controller.pickImageFromCamera();
                        if (controller.selectedImage.value != null) {
                          // 跳转到详情页，由详情页负责创建笔记并显示 Loading
                          await controller.createNote();
                        }
                        // 延迟删除控制器
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (Get.isRegistered<CreateNoteFromImageController>()) {
                            Get.delete<CreateNoteFromImageController>();
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildImageSourceOption(
                      isDark: isDark,
                      textColor: textColor,
                      borderColor: borderColor,
                      icon: Icons.photo_library,
                      label: l10n.chooseFromAlbum,
                      onTap: () async {
                        Get.back(); // 关闭选择框
                        await controller.pickImageFromGallery();
                        if (controller.selectedImage.value != null) {
                          // 跳转到详情页，由详情页负责创建笔记并显示 Loading
                          await controller.createNote();
                        }
                        // 延迟删除控制器
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (Get.isRegistered<CreateNoteFromImageController>()) {
                            Get.delete<CreateNoteFromImageController>();
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 取消按钮
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Get.back();
                    // 延迟删除控制器
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (Get.isRegistered<CreateNoteFromImageController>()) {
                        Get.delete<CreateNoteFromImageController>();
                      }
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // 底部安全区域
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
  }

  /// 构建图片源选择选项
  Widget _buildImageSourceOption({
    required bool isDark,
    required Color textColor,
    required Color borderColor,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.darkPrimary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 直接选择PDF文件并创建笔记
  Future<void> _pickPdfFileAndCreateNote() async {
    final l10n = AppLocalizations.of(Get.context!)!;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );

      if (result == null || result.files.isEmpty) {
        // 用户取消了选择
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        ToastService.showError(l10n.unknownError);
        return;
      }

      // 检查文件大小（限制为 50MB）
      if (file.size > 50 * 1024 * 1024) {
        ToastService.showError(l10n.fileTooLarge(50));
        return;
      }

      // 延迟一小段时间，确保 BottomSheet 完全关闭后再跳转
      await Future.delayed(const Duration(milliseconds: 200));

      // 跳转到笔记详情页，传递 pdfFilePath，让详情页负责创建笔记并显示 Loading
      Get.toNamed(
        AppRoutes.noteDetail,
        arguments: {
          'pdfFilePath': file.path!,
        },
      );
    } catch (e) {
      ToastService.showError('${l10n.failed}: $e');
      debugPrint('选择PDF文件失败: $e');
    }
  }

}

// 创建源类型枚举
enum _SourceType {
  pdf,
  audio,
  image,
  website,
  youtube,
  bilibili,
  customText,
}

// 创建源项数据类
class _SourceItem {
  final IconData icon;
  final String label;
  final Color color;
  final _SourceType type;

  const _SourceItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.type,
  });
}
