import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_controller.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_state.dart';

class FeynmanLearningPage extends StatelessWidget {
  const FeynmanLearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FeynmanLearningController());

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (controller.state.isExplanationViewVisible.value &&
              controller.state.learningPhase.value == LearningPhase.explaining) {
            // 点击背景时恢复（但实际上子组件会拦截点击）
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172B), // Dark purple
                Color(0xFF59168B), // Purple
                Color(0xFF0F172B), // Dark purple
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Obx(() {
              if (controller.state.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              }

              if (controller.state.errorMessage.value != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.state.errorMessage.value!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => controller.loadTerms(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF59168B),
                          ),
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final terms = controller.state.terms.value;
              if (terms == null || terms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '暂无卡片',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => controller.loadTerms(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF59168B),
                        ),
                        child: const Text('刷新'),
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                children: [
                  Column(
                    children: [
                      // Header section
                      _buildHeader(controller),
                      const SizedBox(height: 24),
                      // Card section
                      Expanded(
                        child: Center(
                          child: _buildCardSection(context, controller),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Pagination section
                      _buildPagination(controller),
                      const SizedBox(height: 32),
                    ],
                  ),
                  // Input Panel (Voice/Text)
                  _buildInputPanel(context, controller),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(FeynmanLearningController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 返回按钮和主题名称
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    controller.getCategoryDisplayName(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48), // 平衡返回按钮
            ],
          ),
          const SizedBox(height: 8),
          // 标题
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 24,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                '费曼学习法',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                  letterSpacing: 0.07,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.auto_awesome,
                size: 24,
                color: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 副标题
          const Text(
            '左右滑动切换卡片，上滑开始解释',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFE9D4FF),
              letterSpacing: -0.15,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建卡片区域
  Widget _buildCardSection(BuildContext context, FeynmanLearningController controller) {
    return Obx(() {
      final learningPhase = controller.state.learningPhase.value;
      
      // 在 reviewing 阶段，显示待解释的词汇卡片
      if (learningPhase == LearningPhase.reviewing) {
        return _buildConfusedWordsCards(controller);
      }
      
      // 在 success 阶段，显示成功界面
      if (learningPhase == LearningPhase.success) {
        return _buildSuccessCard(controller);
      }
      
      // 在 explaining 阶段，显示当前解释词汇的卡片
      if (learningPhase == LearningPhase.explaining) {
        final currentTerm = controller.state.currentExplainingTerm.value;
        if (currentTerm != null) {
          return _buildExplainingTermCard(controller, currentTerm);
        }
      }
      
      // 正常的术语卡片（selecting 阶段）
      final terms = controller.state.terms.value!;
      final currentIndex = controller.state.currentCardIndex.value;

      if (currentIndex >= terms.length) {
        return const SizedBox.shrink();
      }

      final term = terms[currentIndex];
      final category = controller.getCategoryDisplayName();

      // 固定卡片尺寸
      const cardWidth = 345.0;
      const cardHeight = 500.0;

      return SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: _SwipeableCard(
          key: ValueKey(currentIndex),
          cardWidth: cardWidth,
          cardHeight: cardHeight,
          onSwipeLeft: controller.previousCard,
          onSwipeRight: controller.nextCard,
          onSwipeUp: () => controller.handleCardExplain(term),
          onRestore: controller.restoreCardView,
          child: _buildCardContent(controller, term, category, cardWidth, cardHeight),
        ),
      );
    });
  }

  /// 构建当前正在解释的词汇卡片（explaining 阶段显示）
  Widget _buildExplainingTermCard(FeynmanLearningController controller, String term) {
    const cardWidth = 345.0;
    const cardHeight = 200.0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF6366F1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                '正在解释',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              term,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.37,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建待解释词汇卡片
  Widget _buildConfusedWordsCards(FeynmanLearningController controller) {
    return Obx(() {
      final confusedWords = controller.state.confusedWords;
      final currentIndex = controller.state.currentConfusedIndex.value;
      
      if (confusedWords.isEmpty) {
        return const SizedBox.shrink();
      }
      
      final safeIndex = currentIndex.clamp(0, confusedWords.length - 1);
      final currentWord = confusedWords[safeIndex];

      const cardWidth = 345.0;
      const cardHeight = 500.0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: _SwipeableCard(
              key: ValueKey('confused_${safeIndex}_$currentWord'),
              cardWidth: cardWidth,
              cardHeight: cardHeight,
              onSwipeLeft: () {
                if (confusedWords.length > 1) {
                  controller.state.currentConfusedIndex.value = 
                      (safeIndex + 1) % confusedWords.length;
                }
              },
              onSwipeRight: () {
                if (confusedWords.length > 1) {
                  controller.state.currentConfusedIndex.value = 
                      (safeIndex - 1 + confusedWords.length) % confusedWords.length;
                }
              },
              onSwipeUp: () => controller.selectConfusedWord(currentWord),
              onRestore: () {},
              child: _buildConfusedWordCardContent(controller, currentWord, cardWidth, cardHeight),
            ),
          ),
          if (confusedWords.length > 1)
            _buildConfusedWordsPagination(controller, confusedWords.length, safeIndex),
        ],
      );
    });
  }

  /// 待解释词汇的底部分页器
  Widget _buildConfusedWordsPagination(FeynmanLearningController controller, int total, int current) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          SizedBox(
            height: 8,
            child: ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: total,
              itemBuilder: (context, index) {
                final isActive = index == current;
                return Container(
                  width: isActive ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(100),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${current + 1} / $total',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFE9D4FF),
              letterSpacing: -0.15,
            ),
          ),
        ],
      ),
    );
  }

  /// 待解释词汇卡片内容
  Widget _buildConfusedWordCardContent(
    FeynmanLearningController controller,
    String word,
    double cardWidth,
    double cardHeight,
  ) {
    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF6366F1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    '需要解释',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      letterSpacing: -0.15,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  word,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.37,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '↑ 上滑开始解释',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showExplanationDialog(controller, word),
                    icon: const Icon(Icons.lightbulb_outline, color: Colors.white),
                    label: const Text(
                      '不会？获取提示',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 成功界面卡片
  Widget _buildSuccessCard(FeynmanLearningController controller) {
    const cardWidth = 345.0;
    const cardHeight = 500.0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10B981),
            Color(0xFF059669),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '🎉 解释清楚了！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final history = controller.state.explanationHistory;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '学习路径 (${history.length}步)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(history.length, (index) {
                              final term = history[index];
                              final isLast = index == history.length - 1;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(isLast ? 0.3 : 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      term,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(
                                        Icons.arrow_forward,
                                        size: 16,
                                        color: Colors.white.withOpacity(0.6),
                                      ),
                                    ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.finishLearning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '继续学习下一个',
                  style: TextStyle(
                    fontSize: 16,
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

  /// 构建卡片内容
  Widget _buildCardContent(
    FeynmanLearningController controller,
    String term,
    String category,
    double cardWidth,
    double cardHeight,
  ) {
    return Stack(
      children: [
        Positioned(
          left: 8,
          top: 28,
          right: 8,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 50,
                  offset: const Offset(0, 25),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: cardWidth,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF10B981), // Green
                  Color(0xFF059669), // Darker green
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 50,
                  offset: const Offset(0, 25),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -40,
                  top: -80,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -64,
                  bottom: -64,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: cardHeight,
                  child: Obx(() {
                    final isExplanation =
                        controller.state.isExplanationViewVisible.value;
                    return AnimatedPadding(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: EdgeInsets.only(
                        left: 32,
                        right: 32,
                        top: isExplanation ? 20 : 32,
                        bottom: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: isExplanation ? 0.0 : 1.0,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      letterSpacing: -0.15,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                          Text(
                            term,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.normal,
                              color: Colors.white,
                              letterSpacing: 0.37,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建分页指示器
  Widget _buildPagination(FeynmanLearningController controller) {
    return Obx(() {
      final isHidden = controller.state.isExplanationViewVisible.value;
      
      final terms = controller.state.terms.value;
      if (terms == null || terms.isEmpty) {
        return const SizedBox.shrink();
      }

      final currentIndex = controller.state.currentCardIndex.value;
      final totalCards = terms.length;

      return AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isHidden ? 0.0 : 1.0,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalCards,
                (index) {
                  final isActive = index == currentIndex;
                  return GestureDetector(
                    onTap: () => controller.goToCard(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isActive ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${currentIndex + 1} / $totalCards',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFE9D4FF),
                letterSpacing: -0.15,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInputPanel(BuildContext context, FeynmanLearningController controller) {
    return Obx(() {
      final isVisible = controller.state.isExplanationViewVisible.value;
      final learningPhase = controller.state.learningPhase.value;

      if (learningPhase == LearningPhase.reviewing || 
          learningPhase == LearningPhase.success) {
        return const SizedBox.shrink();
      }

      final hasExplanation = controller.state.userExplanation.value != null;
      final panelHeight = hasExplanation ? 220.0 : 180.0;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        left: 0,
        right: 0,
        bottom: isVisible ? 0 : -panelHeight - 50,
        child: GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: panelHeight,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _buildExplainingView(controller),
          ),
        ),
      );
    });
  }

  /// 解释输入界面
  Widget _buildExplainingView(FeynmanLearningController controller) {
    return Obx(() {
      final inputMode = controller.state.inputMode.value;
      final currentTerm = controller.state.currentExplainingTerm.value ?? '';
      final isSubmitting = controller.state.isSubmittingSuggestion.value;
      final userExplanation = controller.state.userExplanation.value;
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '请解释：$currentTerm',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          if (userExplanation != null && userExplanation.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      userExplanation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSubmitting)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 16,
                      height: 16,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ],
          
          Expanded(
            child: Center(
              child: isSubmitting
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          'AI 正在评估你的解释...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: inputMode == InputMode.voice
                          ? _buildVoiceButton(controller)
                          : _buildTextInput(controller),
                    ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildVoiceButton(FeynmanLearningController controller) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
          controller.state.inputMode.value = InputMode.text;
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Icon(
          Icons.mic,
          size: 40,
          color: Color(0xFF59168B),
        ),
      ),
    );
  }

  Widget _buildTextInput(FeynmanLearningController controller) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.state.textInputController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '输入你的理解...',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF59168B)),
            onPressed: () => controller.handleTextSubmit(
                controller.state.textInputController.text),
          ),
        ],
      ),
    );
  }

  /// 显示辅助解释弹窗
  void _showExplanationDialog(FeynmanLearningController controller, String word) async {
    await controller.getWordExplanation(word);
    
    final explanation = controller.state.wordExplanations[word];
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Color(0xFFFBBF24), size: 24),
                const SizedBox(width: 8),
                Text(
                  word,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (controller.state.isLoadingExplanation.value)
              const Center(child: CircularProgressIndicator())
            else if (explanation == null)
              const Text('获取解释失败，请稍后重试')
            else ...[
              Text(
                explanation.simpleExplanation,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF374151),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('💡 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        '类比：${explanation.analogy}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('🎯 ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        explanation.keyPoint,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
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
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

/// 可滑动的卡片组件
class _SwipeableCard extends StatefulWidget {
  const _SwipeableCard({
    super.key,
    required this.cardWidth,
    required this.cardHeight,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    this.onSwipeUp,
    required this.onRestore,
    required this.child,
  });

  final double cardWidth;
  final double cardHeight;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback onRestore;
  final Widget child;

  @override
  State<_SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _dragOffset = Offset.zero;
  double _rotation = 0.0;
  double _scale = 1.0;
  double _heightFactor = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {}

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      final dx = _dragOffset.dx + details.delta.dx;
      double dy = _dragOffset.dy + details.delta.dy;
      if (dy > 0) dy = 0;
      
      _dragOffset = Offset(dx, dy);
      _rotation = (_dragOffset.dx / widget.cardWidth) * 0.3;
      final horizontalRatio = (_dragOffset.dx.abs() / widget.cardWidth);
      _scale = 1.0 - horizontalRatio * 0.1;
      _scale = _scale.clamp(0.9, 1.0);

      if (_dragOffset.dy < 0 && _dragOffset.dx.abs() < 20) {
        final verticalProgress = (_dragOffset.dy.abs() / (widget.cardHeight * 0.8)).clamp(0.0, 1.0);
        _heightFactor = 1.0 - verticalProgress * 0.75;
      } else {
        _heightFactor = 1.0;
      }
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    final horizontalThreshold = widget.cardWidth * 0.3;
    final verticalThreshold = widget.cardHeight * 0.25;

    final isHorizontalGesture = _dragOffset.dx.abs() >= _dragOffset.dy.abs();

    if (isHorizontalGesture &&
        (_dragOffset.dx.abs() > horizontalThreshold ||
            velocity.dx.abs() > 800)) {
      if (_dragOffset.dx < 0) {
        _animateSwipe(true);
      } else {
        _animateSwipe(false);
      }
      return;
    }

    final isUpSwipe = _dragOffset.dy < -verticalThreshold || velocity.dy < -800;
    if (!isHorizontalGesture && isUpSwipe) {
      widget.onSwipeUp?.call();
      _animateSwipeUp();
      return;
    }

    _animateReset();
  }

  void _animateSwipe(bool isLeft) {
    final targetX = isLeft ? -widget.cardWidth * 1.5 : widget.cardWidth * 1.5;
    final targetRotation = isLeft ? -0.5 : 0.5;

    _controller.reset();
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    animation.addListener(() {
      setState(() {
        _dragOffset = Offset(
          _dragOffset.dx + (targetX - _dragOffset.dx) * animation.value * 0.1,
          _dragOffset.dy,
        );
        _rotation =
            _rotation + (targetRotation - _rotation) * animation.value * 0.1;
        _scale = 1.0 - animation.value * 0.2;
      });
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (isLeft) {
          widget.onSwipeLeft();
        } else {
          widget.onSwipeRight();
        }
        setState(() {
          _dragOffset = Offset.zero;
          _rotation = 0.0;
          _scale = 1.0;
        });
      }
    });

    _controller.forward();
  }

  void _animateSwipeUp() {
    final targetOffset = Offset(0, -widget.cardHeight * 0.38);
    const targetHeightFactor = 0.25;

    _controller.reset();
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    final startOffset = _dragOffset;
    final startHeightFactor = _heightFactor;
    final startScale = _scale;

    animation.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(startOffset, targetOffset, animation.value)!;
        _heightFactor = startHeightFactor +
            (targetHeightFactor - startHeightFactor) * animation.value;
        _scale = startScale + (1.0 - startScale) * animation.value;
      });
    });

    _controller.forward();
  }

  void _animateReset() {
    _controller.reset();
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    final startOffset = _dragOffset;
    final startRotation = _rotation;
    final startScale = _scale;
    final startHeightFactor = _heightFactor;

    animation.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(startOffset, Offset.zero, animation.value)!;
        _rotation = startRotation * (1 - animation.value);
        _scale = startScale + (1.0 - startScale) * animation.value;
        _heightFactor =
            startHeightFactor + (1.0 - startHeightFactor) * animation.value;
      });
    });

    _controller.forward();
  }

  void _handleTap() {
    if (_heightFactor < 0.95) {
      _animateRestore();
    }
  }

  void _animateRestore() {
    widget.onRestore.call();

    _controller.reset();
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    final startOffset = _dragOffset;
    final startHeightFactor = _heightFactor;
    final startScale = _scale;

    animation.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(startOffset, Offset.zero, animation.value)!;
        _heightFactor =
            startHeightFactor + (1.0 - startHeightFactor) * animation.value;
        _scale = startScale + (1.0 - startScale) * animation.value;
      });
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onRestore.call();
      }
    });

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final swipeProgress =
        (_dragOffset.dx.abs() / widget.cardWidth).clamp(0.0, 1.0);
    final leftHintOpacity = _dragOffset.dx < 0 ? swipeProgress : 0.0;
    final rightHintOpacity = _dragOffset.dx > 0 ? swipeProgress : 0.0;

    return GestureDetector(
      onTap: _handleTap,
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (leftHintOpacity > 0)
            Positioned.fill(
              child: Opacity(
                opacity: leftHintOpacity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.blue.withOpacity(0.3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          if (rightHintOpacity > 0)
            Positioned.fill(
              child: Opacity(
                opacity: rightHintOpacity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.green.withOpacity(0.3),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: _dragOffset,
            child: Transform.rotate(
              angle: _rotation,
              child: Transform.scale(
                scale: _scale,
                child: SizedBox(
                  width: widget.cardWidth,
                  height: widget.cardHeight * _heightFactor,
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

