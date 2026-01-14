import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'package:newstudyapp/pages/note_detail/note_detail_controller.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/config/app_theme.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = (isDark ? Colors.grey[500]! : Colors.grey[600]!);
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final borderColor = (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    // 使用HomeController来获取笔记列表
    // 如果HomeController不存在，则创建一个
    HomeController controller;
    if (Get.isRegistered<HomeController>()) {
      controller = Get.find<HomeController>();
    } else {
      controller = Get.put(HomeController());
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          '我的笔记',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: () => controller.loadNotes(),
            tooltip: '刷新',
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          // 显示加载状态
          if (controller.state.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 显示错误信息
          if (controller.state.errorMessage.value != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: secondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.state.errorMessage.value ?? '加载失败',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => controller.loadNotes(),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 显示空状态
          if (controller.state.notes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_add_outlined,
                      size: 64,
                      color: secondaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '还没有笔记',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '创建第一条笔记开始学习吧',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 显示笔记列表
          return RefreshIndicator(
            onRefresh: () => controller.loadNotes(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.state.notes.length,
              itemBuilder: (context, index) {
                final note = controller.state.notes[index];
                final colors = [
                  const Color(0xFF4ECDC4),
                  const Color(0xFFFF6B6B),
                  const Color(0xFFFFD93D),
                  const Color(0xFF95E1D3),
                  const Color(0xFFF38181),
                ];
                final color = colors[index % colors.length];

                return _buildNoteCard(
                  isDark: isDark,
                  noteId: note.id,
                  title: note.title ?? '无标题',
                  progress: note.masteredCount,
                  total: note.termCount,
                  reviewCount: note.reviewCount,
                  color: color,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
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
    required String noteId,
    required String title,
    required int progress,
    required int total,
    required int reviewCount,
    required Color color,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryColor,
  }) {
    final percentage = total > 0 ? (progress / total * 100).toInt() : 0;

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          AppRoutes.noteDetail,
          arguments: {'noteId': noteId},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
                      Text(
                        '学习进度',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: total > 0 ? progress / total : 0,
                                backgroundColor: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$percentage%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(
                  icon: Icons.check_circle_outline,
                  label: '已掌握',
                  value: '$progress',
                  color: color,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  icon: Icons.schedule_outlined,
                  label: '待复习',
                  value: '$reviewCount',
                  color: color,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                ),
                const Spacer(),
                _buildStatItem(
                  icon: Icons.library_books_outlined,
                  label: '总词条',
                  value: '$total',
                  color: color,
                  textColor: textColor,
                  secondaryColor: secondaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    required Color secondaryColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: secondaryColor),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
