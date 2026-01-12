import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_controller.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_state.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:newstudyapp/routes/app_routes.dart';

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
            child: CircularProgressIndicator(color: AppTheme.darkPrimary),
          );
        }

        if (controller.state.errorMessage.value != null) {
          return _buildErrorView(controller, isDark);
        }

        final terms = controller.state.terms.value;
        if (terms == null || terms.isEmpty) {
          return _buildEmptyView(controller, isDark);
        }

        // 根据学习阶段显示不同视图
        if (controller.state.isExplanationViewVisible.value ||
            controller.state.learningPhase.value == LearningPhase.explaining ||
            controller.state.learningPhase.value == LearningPhase.reviewing ||
            controller.state.learningPhase.value == LearningPhase.success) {
          return _buildExplanationView(controller, isDark);
        }

        return Column(
          children: [
            // 进度显示
            _buildProgressBar(controller, terms.length, isDark),
            const SizedBox(height: 16),

            // 卡片区域
            Expanded(child: _buildCardSection(controller, terms, isDark)),

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
    FeynmanLearningController controller,
    bool isDark,
  ) {
    final iconColor = isDark ? Colors.white : Colors.black87;
    final textColor = isDark ? Colors.white : Colors.black87;

    return AppBar(
      backgroundColor: Theme.of(Get.context!).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.close, color: iconColor),
        onPressed: () => Get.offAllNamed(AppRoutes.main),
      ),
      actions: [
        // 返回首页按钮
        TextButton(
          onPressed: () => Get.offAllNamed(AppRoutes.main),
          child: Text(
            '返回首页',
            style: TextStyle(
              color: iconColor,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      title: Obx(
        () => Text(
          controller.getCategoryDisplayName(),
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  /// 构建进度条
  Widget _buildProgressBar(
    FeynmanLearningController controller,
    int total,
    bool isDark,
  ) {
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
    FeynmanLearningController controller,
    List<String> terms,
    bool isDark,
  ) {
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

                  // 词条名称和已掌握标记
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          term,
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                      // 已掌握标记
                      Obx(() {
                        final isMastered =
                            controller.state.masteredTerms.contains(term);
                        if (isMastered) {
                          return Container(
                            margin: const EdgeInsets.only(left: 12, top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '已掌握',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
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
    FeynmanLearningController controller,
    int total,
    bool isDark,
  ) {
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
                actualIndex == current,
                dotColor,
                activeDotColor,
              );
            } else {
              return _buildDot(
                (total - 1) == current,
                dotColor,
                activeDotColor,
              );
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
              style: TextStyle(fontSize: 14, color: secondaryColor),
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
                _showWordExplanation(context, controller, term, isDark);
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
                controller.markAsMastered(term);
              },
              isDark: isDark,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 显示词汇解释对话框
  void _showWordExplanation(
    BuildContext context,
    FeynmanLearningController controller,
    String term,
    bool isDark,
  ) {
    final bgColor = isDark ? Colors.grey[900] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final cardColor = isDark ? Colors.grey[850] : Colors.grey[50];

    // 先获取解释
    controller.getWordExplanation(term);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Obx(() {
        final isLoading = controller.state.isLoadingExplanation.value;
        final explanation = controller.state.wordExplanations[term];

        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.lightbulb, color: const Color(0xFFF59E0B), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  term,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'AI 正在生成解释...',
                          style: TextStyle(fontSize: 14, color: secondaryColor),
                        ),
                      ],
                    ),
                  )
                : explanation == null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '获取解释失败，请稍后重试',
                          style: TextStyle(fontSize: 14, color: secondaryColor),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 类比
                            if (explanation.analogy.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFF59E0B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.compare_arrows,
                                      size: 20,
                                      color: const Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '就像：${explanation.analogy}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFF59E0B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 详细解释
                            if (explanation.simpleExplanation.isNotEmpty) ...[
                              Text(
                                '详细解释',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  explanation.simpleExplanation,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: textColor,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 关键点
                            if (explanation.keyPoint.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF10B981)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 20,
                                      color: const Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '关键点',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF10B981),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            explanation.keyPoint,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: textColor,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('关闭', style: TextStyle(color: textColor)),
            ),
            if (explanation != null) ...[
              TextButton.icon(
                onPressed: () {
                  _copyExplanationToClipboard(term, explanation);
                },
                icon: const Icon(
                  Icons.copy,
                  size: 18,
                  color: Color(0xFF10B981),
                ),
                label: const Text(
                  '复制',
                  style: TextStyle(color: Color(0xFF10B981)),
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  controller.handleCardExplain(term);
                },
                child: const Text(
                  '开始解释',
                  style: TextStyle(color: Color(0xFF6366F1)),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  /// 复制解释到剪贴板
  void _copyExplanationToClipboard(String term, WordExplanation explanation) {
    // 格式化解释内容
    final buffer = StringBuffer();
    buffer.writeln('【$term】');
    buffer.writeln();

    if (explanation.analogy.isNotEmpty) {
      buffer.writeln('💡 就像：${explanation.analogy}');
      buffer.writeln();
    }

    if (explanation.simpleExplanation.isNotEmpty) {
      buffer.writeln('📖 详细解释：');
      buffer.writeln(explanation.simpleExplanation);
      buffer.writeln();
    }

    if (explanation.keyPoint.isNotEmpty) {
      buffer.writeln('✅ 关键点：');
      buffer.writeln(explanation.keyPoint);
    }

    final textToCopy = buffer.toString();

    // 复制到剪贴板
    Clipboard.setData(ClipboardData(text: textToCopy));

    // 显示提示
    Get.snackbar(
      '已复制',
      '解释内容已复制到剪贴板',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  /// 构建解释视图
  Widget _buildExplanationView(
    FeynmanLearningController controller,
    bool isDark,
  ) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardColor = isDark ? Colors.grey[850]! : Colors.grey[50]!;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return Obx(() {
      final phase = controller.state.learningPhase.value;
      final currentTerm = controller.state.currentExplainingTerm.value;
      final confusedWords = controller.state.confusedWords;
      final userExplanation = controller.state.userExplanation.value;
      final isSubmitting = controller.state.isSubmittingSuggestion.value;

      // 成功状态
      if (phase == LearningPhase.success) {
        return _buildSuccessView(controller, isDark, currentTerm ?? '');
      }

      // 查看不清楚词汇状态
      if (phase == LearningPhase.reviewing && confusedWords.isNotEmpty) {
        return _buildReviewingView(controller, isDark, confusedWords);
      }

      // 解释输入状态
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 返回按钮
            IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => controller.restoreCardView(),
            ),
            const SizedBox(height: 16),

            // 当前词汇
            if (currentTerm != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.darkPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.darkPrimary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.school, color: AppTheme.darkPrimary, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '解释这个词',
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentTerm,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 提示文字
            Text(
              '用最简单的话解释这个词，就像向12岁的小学生解释一样',
              style: TextStyle(
                fontSize: 14,
                color: secondaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // 输入框和语音识别按钮
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: controller.state.textInputController,
                    maxLines: 6,
                    style: TextStyle(color: textColor, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: '例如：API就像餐厅的服务员，帮你和厨房沟通...',
                      hintStyle: TextStyle(color: secondaryColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onSubmitted: (text) {
                      if (!isSubmitting && text.trim().isNotEmpty) {
                        controller.handleTextSubmit(text);
                      }
                    },
                  ),
                  // 语音识别按钮
                  Obx(() {
                    final isListening = controller.state.isListening.value;
                    final speechAvailable =
                        controller.state.speechAvailable.value;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: borderColor)),
                      ),
                      child: Row(
                        children: [
                          if (isListening) ...[
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '正在录音...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => controller.stopListening(),
                              child: const Text('停止'),
                            ),
                          ] else ...[
                            // 只在语音识别可用时显示按钮
                            if (speechAvailable) ...[
                              Icon(
                                Icons.mic,
                                size: 20,
                                color: AppTheme.darkPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '语音输入',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.darkPrimary,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => controller.startListening(),
                                icon: const Icon(
                                  Icons.keyboard_voice,
                                  size: 18,
                                  color: AppTheme.darkPrimary,
                                ),
                                label: const Text(
                                  '开始录音',
                                  style: TextStyle(color: AppTheme.darkPrimary),
                                ),
                              ),
                            ] else ...[
                              // 语音不可用时显示提示
                              Icon(
                                Icons.mic_off,
                                size: 20,
                                color: secondaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '当前平台不支持语音输入',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 提交按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () {
                        final text = controller.state.textInputController.text;
                        if (text.trim().isNotEmpty) {
                          controller.handleTextSubmit(text);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        '提交解释',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            // 已输入的解释预览
            if (userExplanation != null && userExplanation.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '你的解释',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: secondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userExplanation,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// 构建成功视图
  Widget _buildSuccessView(
    FeynmanLearningController controller,
    bool isDark,
    String term,
  ) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 50,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '🎉 太棒了！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '你已经很好地理解了"$term"',
              style: TextStyle(fontSize: 16, color: secondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => controller.finishLearning(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('继续学习'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建查看不清楚词汇视图
  Widget _buildReviewingView(
    FeynmanLearningController controller,
    bool isDark,
    List<String> confusedWords,
  ) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardColor = isDark ? Colors.grey[850]! : Colors.grey[50]!;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => controller.restoreCardView(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFAA33).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFAA33).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: const Color(0xFFFFAA33),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '你的解释中还有一些不清楚的词',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '选择其中一个词继续学习',
                  style: TextStyle(fontSize: 14, color: secondaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ...confusedWords.map(
            (word) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.selectConfusedWord(word),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.darkPrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.help_outline,
                            color: AppTheme.darkPrimary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            word,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
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
              ),
            ),
          ),
        ],
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
            Icon(Icons.error_outline, size: 64, color: secondaryColor),
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
            Obx(
              () => Text(
                controller.state.errorMessage.value ?? '未知错误',
                style: TextStyle(fontSize: 14, color: secondaryColor),
                textAlign: TextAlign.center,
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
            Icon(Icons.inbox_outlined, size: 64, color: secondaryColor),
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
              style: TextStyle(fontSize: 14, color: secondaryColor),
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
                child: Icon(icon, color: color, size: 24),
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
                      style: TextStyle(fontSize: 13, color: secondaryColor),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: secondaryColor),
            ],
          ),
        ),
      ),
    );
  }
}
