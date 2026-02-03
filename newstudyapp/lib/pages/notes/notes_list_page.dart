import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'package:newstudyapp/routes/app_routes.dart';

/// 笔记列表页面
class NotesListPage extends StatelessWidget {
  const NotesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final secondaryColor = isDark ? Colors.grey[500]! : Colors.grey[600]!;

    // 使用首页的控制器，复用数据
    final HomeController controller = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: textColor,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          '我的笔记',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Obx(() {
          final isLoading = controller.isLoading.value;
          final notes = controller.notes.toList();

          if (isLoading && notes.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (notes.isEmpty) {
            return _buildEmptyNotes(isDark, textColor, secondaryColor, borderColor);
          }

          return RefreshIndicator(
            onRefresh: () async {
              await controller.loadNotes();
            },
            color: AppTheme.darkPrimary,
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildNoteCard(
                    isDark: isDark,
                    note: note,
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
    );
  }

  Widget _buildNoteCard({
    required bool isDark,
    required note,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryColor,
  }) {
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
          border: Border.all(color: borderColor, width: 1),
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
                      color: textColor,
                    ),
                  ),
                ),
                // 显示优先级最高的状态标签（未掌握 > 需改进 > 需巩固）
                if (note.notMasteredCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.statusNotMastered.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${note.notMasteredCount} 未掌握',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.statusNotMastered,
                      ),
                    ),
                  )
                else if (note.needsImproveCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.statusNeedsImprove.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${note.needsImproveCount} 需改进',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.statusNeedsImprove,
                      ),
                    ),
                  )
                else if (note.needsReviewCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.statusNeedsReview.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${note.needsReviewCount} 需巩固',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.statusNeedsReview,
                      ),
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
                              color: AppTheme.statusMastered,
                            ),
                          ),
                          Text(
                            '/${note.flashCardCount}',
                            style: TextStyle(
                              fontSize: 16,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '已掌握',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                        ),
                      ),
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
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.statusMastered,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
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

  Widget _buildEmptyNotes(
    bool isDark,
    Color textColor,
    Color secondaryColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
}
