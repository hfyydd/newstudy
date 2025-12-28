import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/config/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
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
                const SizedBox(height: 24),
                
                // 测试按钮
                _buildTestButton(isDark),
                const SizedBox(height: 100),
              ],
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
                // TODO: 跳转到创建笔记页面
                Get.snackbar(
                  '提示',
                  '创建笔记功能即将推出',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF667EEA),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.all(16),
                  borderRadius: 12,
                );
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
      onTap: () {},
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
            const Row(
              children: [
                Text(
                  '8',
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '个词条',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w400),
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
                _buildQuickStat('困难', '3', Colors.orange),
                const SizedBox(width: 12),
                _buildQuickStat('需改进', '5', Colors.yellow),
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
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
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
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
            ),
            TextButton(
              onPressed: () {},
              child: Text('查看全部', style: TextStyle(color: secondaryColor, fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildNoteCard(
          isDark: isDark,
          title: '经济学基础',
          progress: 12,
          total: 30,
          reviewCount: 5,
          color: const Color(0xFF4ECDC4),
        ),
        const SizedBox(height: 12),
        _buildNoteCard(
          isDark: isDark,
          title: '机器学习笔记',
          progress: 5,
          total: 15,
          reviewCount: 3,
          color: const Color(0xFFFF6B6B),
        ),
        const SizedBox(height: 12),
        _buildAddNoteButton(isDark),
      ],
    );
  }

  Widget _buildNoteCard({
    required bool isDark,
    required String title,
    required int progress,
    required int total,
    required int reviewCount,
    required Color color,
  }) {
    final percentage = (progress / total * 100).toInt();
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[600] : Colors.grey[600];
    
    return GestureDetector(
      onTap: () {},
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
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                  ),
                ),
                if (reviewCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$reviewCount 待复习',
                      style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600),
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
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
                          ),
                          Text(
                            '/$total',
                            style: TextStyle(fontSize: 16, color: secondaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('已掌握', style: TextStyle(fontSize: 12, color: secondaryColor)),
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
                            value: progress / total,
                            strokeWidth: 5,
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$percentage%',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
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

  Widget _buildAddNoteButton(bool isDark) {
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final iconColor = isDark ? Colors.grey[600] : Colors.grey[500];
    
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor!, width: 1, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              '创建新笔记',
              style: TextStyle(color: iconColor, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '学习统计',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildStatCard(isDark, Icons.local_fire_department_rounded, '7', '连续天数', const Color(0xFFFF6B6B))),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(isDark, Icons.psychology_rounded, '25', '已掌握', const Color(0xFF4ECDC4))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(isDark, Icons.timer_outlined, '2.5h', '累计时长', const Color(0xFFFFD93D))),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(isDark, Icons.library_books_outlined, '50', '累计学习', const Color(0xFF95E1D3))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(bool isDark, IconData icon, String value, String label, Color color) {
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
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor, height: 1),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: secondaryColor)),
        ],
      ),
    );
  }

  Widget _buildTestButton(bool isDark) {
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800] : Colors.grey[300];
    final iconColor = isDark ? Colors.grey[500] : Colors.grey[600];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor!, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '测试功能',
                style: TextStyle(fontSize: 14, color: iconColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Get.toNamed(AppRoutes.feynmanLearning);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                '跳转到闪词学习页面',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
