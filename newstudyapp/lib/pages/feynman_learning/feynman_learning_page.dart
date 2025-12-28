import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_controller.dart';

class FeynmanLearningPage extends StatelessWidget {
  const FeynmanLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FeynmanLearningController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(controller),
      body: Obx(() {
        if (controller.state.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.state.errorMessage.value != null) {
          return _buildErrorView(controller);
        }

        final terms = controller.state.terms.value;
        if (terms == null || terms.isEmpty) {
          return _buildEmptyView(controller);
        }

        return Column(
          children: [
            // 进度显示
            _buildProgressBar(controller, terms.length),
            const SizedBox(height: 16),

            // 卡片区域
            Expanded(
              child: _buildCardSection(controller, terms),
            ),

            const SizedBox(height: 24),

            // 分页指示器
            _buildPageIndicator(controller, terms.length),
            const SizedBox(height: 32),
          ],
        );
      }),
    );
  }

  /// 构建AppBar
  PreferredSizeWidget _buildAppBar(FeynmanLearningController controller) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Get.back(),
      ),
      title: Obx(() => Text(
            controller.getCategoryDisplayName(),
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          )),
      centerTitle: true,
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(FeynmanLearningController controller, int total) {
    return Obx(() {
      final current = controller.state.currentCardIndex.value + 1;
      final progress = current / total;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '进度：$current/$total',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
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
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6366F1),
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
      FeynmanLearningController controller, List<String> terms) {
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
  ) {
    return GestureDetector(
      onTap: isCurrentCard
          ? () {
              // 点击当前卡片，显示学习选项
              _showLearningOptions(context, controller, term);
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
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF10B981), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFF59E0B), // Amber
    ];
    return colors[index % colors.length];
  }

  /// 构建分页指示器
  Widget _buildPageIndicator(FeynmanLearningController controller, int total) {
    return Obx(() {
      final currentIndex = controller.state.currentCardIndex.value;

      return Column(
        children: [
          // 圆点指示器
          SizedBox(
            height: 8,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: total.clamp(0, 10), // 最多显示10个点
              itemBuilder: (context, index) {
                final isActive = index == currentIndex;
                return GestureDetector(
                  onTap: () => controller.goToCard(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 32 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color:
                          isActive ? const Color(0xFF6366F1) : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // 数字显示
          Text(
            '${currentIndex + 1} / $total',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    });
  }

  /// 显示学习选项弹窗
  void _showLearningOptions(
    BuildContext context,
    FeynmanLearningController controller,
    String term,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '学习：$term',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // 开始学习
            _LearningOptionButton(
              icon: Icons.school,
              title: '开始学习',
              subtitle: '用费曼学习法解释这个词条',
              color: const Color(0xFF6366F1),
              onPressed: () {
                Get.back();
                controller.handleCardExplain(term);
              },
            ),
            const SizedBox(height: 12),

            // 查看提示
            _LearningOptionButton(
              icon: Icons.lightbulb_outline,
              title: '查看提示',
              subtitle: '获取词条的简单解释',
              color: const Color(0xFF10B981),
              onPressed: () {
                Get.back();
                _showHintDialog(context, controller, term);
              },
            ),
            const SizedBox(height: 12),

            // 标记已掌握
            _LearningOptionButton(
              icon: Icons.check_circle_outline,
              title: '标记已掌握',
              subtitle: '跳过这个词条',
              color: const Color(0xFF8B5CF6),
              onPressed: () {
                Get.back();
                Get.snackbar(
                  '已标记',
                  '词条「$term」已标记为已掌握',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF10B981),
                  colorText: Colors.white,
                );
                controller.nextCard();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 显示提示对话框
  void _showHintDialog(
    BuildContext context,
    FeynmanLearningController controller,
    String term,
  ) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb,
                    color: Color(0xFFFBBF24),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      term,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '提示功能开发中...\n请尝试用自己的话解释这个词条',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '我知道了',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
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

  /// 错误视图
  Widget _buildErrorView(FeynmanLearningController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              controller.state.errorMessage.value ?? '发生错误',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.loadTerms(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '重试',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 空视图
  Widget _buildEmptyView(FeynmanLearningController controller) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无卡片',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => controller.loadTerms(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              '刷新',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// 学习选项按钮
class _LearningOptionButton extends StatelessWidget {
  const _LearningOptionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
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
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
