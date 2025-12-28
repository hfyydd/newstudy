import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_controller.dart';
import 'package:newstudyapp/config/app_theme.dart';

class FeynmanLearningPage extends StatelessWidget {
  const FeynmanLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FeynmanLearningController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(controller, isDark),
      body: Obx(() {
        if (controller.state.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.darkPrimary,
            ),
          );
        }

        if (controller.state.errorMessage.value != null) {
          return _buildErrorView(controller, isDark);
        }

        final terms = controller.state.terms.value;
        if (terms == null || terms.isEmpty) {
          return _buildEmptyView(controller, isDark);
        }

        return Column(
          children: [
            // 进度显示
            _buildProgressBar(controller, terms.length, isDark),
            const SizedBox(height: 16),

            // 卡片区域
            Expanded(
              child: _buildCardSection(controller, terms, isDark),
            ),

            const SizedBox(height: 24),

            // 分页指示器
            _buildPageIndicator(controller, terms.length, isDark),
            const SizedBox(height: 32),
          ],
        );
      }),
    );
  }

  /// 构建AppBar
  PreferredSizeWidget _buildAppBar(
      FeynmanLearningController controller, bool isDark) {
    final iconColor = isDark ? Colors.white : Colors.black87;
    final textColor = isDark ? Colors.white : Colors.black87;

    return AppBar(
      backgroundColor: Theme.of(Get.context!).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: iconColor),
        onPressed: () => Get.back(),
      ),
      title: Obx(() => Text(
            controller.getCategoryDisplayName(),
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          )),
      centerTitle: true,
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(
      FeynmanLearningController controller, int total, bool isDark) {
    return Obx(() {
      final current = controller.state.currentCardIndex.value + 1;
      final progress = current / total;
      final textColor = isDark ? Colors.grey[400] : Colors.black54;
      final bgColor = isDark ? Colors.grey[800] : Colors.grey[200];

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '进度：$current/$total',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: bgColor,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.darkPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 构建卡片区域（支持滑动）
  Widget _buildCardSection(
      FeynmanLearningController controller, List<String> terms, bool isDark) {
    return PageView.builder(
      controller: PageController(
        initialPage: controller.state.currentCardIndex.value,
        viewportFraction: 0.85,
      ),
      onPageChanged: (index) {
        controller.goToCard(index);
      },
      itemCount: terms.length,
      itemBuilder: (context, index) {
        return Obx(() {
          final currentIndex = controller.state.currentCardIndex.value;
          final isCurrentCard = index == currentIndex;

          return AnimatedScale(
            duration: const Duration(milliseconds: 300),
            scale: isCurrentCard ? 1.0 : 0.9,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isCurrentCard ? 1.0 : 0.6,
              child: _buildCard(
                context,
                controller,
                terms[index],
                index,
                isCurrentCard,
                isDark,
              ),
            ),
          );
        });
      },
    );
  }

  /// 构建单个卡片
  Widget _buildCard(
    BuildContext context,
    FeynmanLearningController controller,
    String term,
    int index,
    bool isCurrentCard,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: isCurrentCard
          ? () {
              _showLearningOptions(context, controller, term, isDark);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCardColor(index).withOpacity(0.9),
              _getCardColor(index),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _getCardColor(index).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 装饰圆圈
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

            // 卡片内容
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 词条类型标签
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      controller.getCategoryDisplayName(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 词条名称
                  Text(
                    term,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),

                  // 提示
                  if (isCurrentCard)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            color: Colors.white.withOpacity(0.9),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '点击开始学习',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据索引返回卡片颜色
  Color _getCardColor(int index) {
    final colors = [
      const Color(0xFF6366F1), // 紫色
      const Color(0xFFEC4899), // 粉色
      const Color(0xFF10B981), // 绿色
      const Color(0xFFF59E0B), // 橙色
      const Color(0xFF3B82F6), // 蓝色
      const Color(0xFF8B5CF6), // 深紫色
    ];
    return colors[index % colors.length];
  }

  /// 构建分页指示器
  Widget _buildPageIndicator(
      FeynmanLearningController controller, int total, bool isDark) {
    return Obx(() {
      final current = controller.state.currentCardIndex.value;
      final dotColor = isDark ? Colors.grey[700] : Colors.grey[300];
      final activeDotColor = AppTheme.darkPrimary;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total > 8 ? 8 : total, (index) {
          if (total > 8) {
            // 显示前3个、当前、后3个和省略号
            if (index < 3) {
              return _buildDot(index == current, dotColor, activeDotColor);
            } else if (index == 3) {
              if (current > 3 && current < total - 4) {
                return _buildDot(true, dotColor, activeDotColor);
              } else if (current <= 3) {
                return _buildDot(index == current, dotColor, activeDotColor);
              } else {
                return _buildEllipsis(dotColor);
              }
            } else if (index >= 4 && index < 7) {
              final actualIndex = total - (8 - index);
              return _buildDot(
                  actualIndex == current, dotColor, activeDotColor);
            } else {
              return _buildDot(
                  (total - 1) == current, dotColor, activeDotColor);
            }
          } else {
            return _buildDot(index == current, dotColor, activeDotColor);
          }
        }),
      );
    });
  }

  Widget _buildDot(bool isActive, Color? inactiveColor, Color activeColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildEllipsis(Color? color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '...',
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 显示学习选项
  void _showLearningOptions(
    BuildContext context,
    FeynmanLearningController controller,
    String term,
    bool isDark,
  ) {
    final bgColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final dividerColor = isDark ? Colors.grey[800] : Colors.grey[200];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖动指示器
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // 词条名称
            Text(
              term,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '选择学习方式',
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: 32),

            // 学习选项按钮
            _LearningOptionButton(
              icon: Icons.record_voice_over,
              title: '开始解释',
              subtitle: '用自己的话解释这个词条',
              color: const Color(0xFF6366F1),
              onTap: () {
                Get.back();
                controller.handleCardExplain(term);
              },
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _LearningOptionButton(
              icon: Icons.lightbulb_outline,
              title: '查看提示',
              subtitle: '获取学习提示和引导',
              color: const Color(0xFFF59E0B),
              onTap: () {
                Get.back();
                // TODO: 实现查看提示功能
                Get.snackbar(
                  '提示',
                  '功能开发中...',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: bgColor,
                  colorText: textColor,
                );
              },
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _LearningOptionButton(
              icon: Icons.check_circle_outline,
              title: '标记已掌握',
              subtitle: '跳过这个词条',
              color: const Color(0xFF10B981),
              onTap: () {
                Get.back();
                // TODO: 实现标记已掌握功能
                Get.snackbar(
                  '成功',
                  '已标记为掌握',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: bgColor,
                  colorText: textColor,
                );
                controller.nextCard();
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView(FeynmanLearningController controller, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              '加载失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
                  controller.state.errorMessage.value ?? '未知错误',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryColor,
                  ),
                  textAlign: TextAlign.center,
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空视图
  Widget _buildEmptyView(FeynmanLearningController controller, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请先选择学习主题',
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 学习选项按钮组件
class _LearningOptionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _LearningOptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? Colors.grey[850] : Colors.grey[50];
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: secondaryColor,
                      ),
                    ),
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
      ),
    );
  }
}
