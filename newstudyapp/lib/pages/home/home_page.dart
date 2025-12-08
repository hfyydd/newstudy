import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'package:newstudyapp/pages/home/home_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController(), tag: 'home');

    return Scaffold(
      body: GestureDetector(
        // 只有点击到背景区域时才恢复卡片视图，子组件的点击不会冒泡
        behavior: HitTestBehavior.translucent,
        onTap: () {
          // 只在点击非输入面板区域时触发
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
                        onPressed: controller.loadTerms,
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
                      onPressed: controller.loadTerms,
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
  Widget _buildHeader(HomeController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Title row with icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
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
          // Subtitle
          const Text(
            '左右滑动切换卡片',
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
  Widget _buildCardSection(BuildContext context, HomeController controller) {
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

      // 固定卡片尺寸，与设计稿保持一致
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
          // 上滑触发解释当前术语
          onSwipeUp: () => controller.handleCardExplain(term),
          // 点击收起的卡片恢复原状
          onRestore: controller.restoreCardView,
          child: _buildCardContent(controller, term, category, cardWidth, cardHeight),
        ),
      );
    });
  }

  /// 构建当前正在解释的词汇卡片（explaining 阶段显示）
  Widget _buildExplainingTermCard(HomeController controller, String term) {
    const cardWidth = 345.0;
    const cardHeight = 200.0; // 缩小的卡片

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
            // 标签
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
            // 词汇
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


  /// 构建待解释词汇的全尺寸卡片（使用和选择卡片一样的滑动机制）
  Widget _buildConfusedWordsCards(HomeController controller) {
    return Obx(() {
      final confusedWords = controller.state.confusedWords;
      final currentIndex = controller.state.currentConfusedIndex.value;
      
      if (confusedWords.isEmpty) {
        return const SizedBox.shrink();
      }
      
      // 确保索引在有效范围内
      final safeIndex = currentIndex.clamp(0, confusedWords.length - 1);
      final currentWord = confusedWords[safeIndex];

      const cardWidth = 345.0;
      const cardHeight = 500.0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 卡片区域
          SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: _SwipeableCard(
              key: ValueKey('confused_${safeIndex}_$currentWord'),
              cardWidth: cardWidth,
              cardHeight: cardHeight,
              // 左滑：下一个词
              onSwipeLeft: () {
                if (confusedWords.length > 1) {
                  controller.state.currentConfusedIndex.value = 
                      (safeIndex + 1) % confusedWords.length;
                }
              },
              // 右滑：上一个词  
              onSwipeRight: () {
                if (confusedWords.length > 1) {
                  controller.state.currentConfusedIndex.value = 
                      (safeIndex - 1 + confusedWords.length) % confusedWords.length;
                }
              },
              // 上滑：开始解释当前词汇
              onSwipeUp: () => controller.selectConfusedWord(currentWord),
              onRestore: () {},
              child: _buildConfusedWordCardContent(controller, currentWord, cardWidth, cardHeight),
            ),
          ),
          // 底部分页器（和选择卡片一样的样式）
          if (confusedWords.length > 1)
            _buildConfusedWordsPagination(controller, confusedWords.length, safeIndex),
        ],
      );
    });
  }

  /// 待解释词汇的底部分页器
  Widget _buildConfusedWordsPagination(HomeController controller, int total, int current) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // 分页点
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
          // 页码文字
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
    HomeController controller,
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
          // 背景装饰
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
          // 内容
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标签
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
                // 词汇
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
                // 提示
                Text(
                  '↑ 上滑开始解释',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                // 获取提示按钮
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
  Widget _buildSuccessCard(HomeController controller) {
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
            // 庆祝图标
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
            // 成功文字
            const Text(
              '🎉 解释清楚了！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // 学习路径展示
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
                      // 词汇链展示
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
            // 查看详细解释按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showExplanationHistory(controller),
                icon: const Icon(Icons.history, color: Colors.white),
                label: const Text(
                  '查看解释详情',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 继续学习按钮
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

  /// 显示解释历史详情弹窗
  void _showExplanationHistory(HomeController controller) {
    final history = controller.state.explanationHistory.toList();
    final contents = controller.state.explanationContents;

    Get.bottomSheet(
      Container(
        height: MediaQuery.of(Get.context!).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.route, color: Color(0xFF10B981), size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    '学习路径详情',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            // 历史列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final term = history[index];
                  final explanation = contents[term] ?? '(无记录)';
                  final isFirst = index == 0;
                  final isLast = index == history.length - 1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 时间线
                        Column(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isLast 
                                    ? const Color(0xFF10B981) 
                                    : const Color(0xFF6366F1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 60,
                                color: Colors.grey.shade300,
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // 内容
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isLast 
                                  ? const Color(0xFFDCFCE7) 
                                  : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      term,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isLast 
                                            ? const Color(0xFF166534) 
                                            : const Color(0xFF1F2937),
                                      ),
                                    ),
                                    if (isFirst)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          '起点',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    if (isLast)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          '完成',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  explanation,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }



  /// 构建卡片内容
  Widget _buildCardContent(
    HomeController controller,
    String term,
    String category,
    double cardWidth,
    double cardHeight,
  ) {
    return Stack(
      children: [
        // Blur shadow container
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
        // Main card
        SizedBox(
          width: cardWidth,
          // height: cardHeight, // 移除固定高度，由父级控制
          child: Container(
            clipBehavior: Clip.hardEdge, // 确保内容被圆角裁剪
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
                // Decorative circles
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
                // Card content - 强制保持原高度，顶部对齐
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
                          // Category badge
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
                          // Title
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
  Widget _buildPagination(HomeController controller) {
    return Obx(() {
      // 如果处于解释视图，隐藏翻页器
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
            // Dots
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
            // Page number
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

  Widget _buildInputPanel(BuildContext context, HomeController controller) {
    return Obx(() {
      final isVisible = controller.state.isExplanationViewVisible.value;
      final learningPhase = controller.state.learningPhase.value;

      // reviewing 和 success 阶段不显示底部面板（卡片区域已显示）
      if (learningPhase == LearningPhase.reviewing || 
          learningPhase == LearningPhase.success) {
        return const SizedBox.shrink();
      }

      // 解释阶段：根据是否有用户解释内容决定高度
      final hasExplanation = controller.state.userExplanation.value != null;
      final panelHeight = hasExplanation ? 220.0 : 180.0;

      return AnimatedPositioned(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        left: 0,
        right: 0,
        bottom: isVisible ? 0 : -panelHeight - 50,
        child: GestureDetector(
          // 阻止点击事件冒泡到父级，避免意外触发 restoreCardView
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


  /// 根据学习阶段构建对应内容
  Widget _buildLearningPhaseContent(
    BuildContext context,
    HomeController controller,
    LearningPhase phase,
  ) {
    switch (phase) {
      case LearningPhase.selecting:
        // 如果面板可见但处于selecting阶段，显示输入界面（兼容旧逻辑）
        return _buildExplainingView(controller);
      case LearningPhase.explaining:
        return _buildExplainingView(controller);
      case LearningPhase.reviewing:
        return _buildReviewingView(controller);
      case LearningPhase.success:
        return _buildSuccessView(controller);
    }
  }

  /// 解释输入界面
  Widget _buildExplainingView(HomeController controller) {
    return Obx(() {
      final inputMode = controller.state.inputMode.value;
      final currentTerm = controller.state.currentExplainingTerm.value ?? '';
      final isSubmitting = controller.state.isSubmittingSuggestion.value;
      final userExplanation = controller.state.userExplanation.value;
      
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 当前解释的词汇提示
          Text(
            '请解释：$currentTerm',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          // 显示用户输入的解释（如果有）
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
          
          // 输入区域
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

  /// 词汇列表界面（reviewing 阶段）
  Widget _buildReviewingView(HomeController controller) {
    return Obx(() {
      final confusedWords = controller.state.confusedWords;
      
      return Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            const Text(
              '🤔 这些词需要继续解释',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '选择一个词继续解释，或点击 ❓ 查看提示',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            // 词汇列表
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: confusedWords.length,
                itemBuilder: (context, index) {
                  final word = confusedWords[index];
                  return _buildWordCard(controller, word);
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 单个词汇卡片
  Widget _buildWordCard(HomeController controller, String word) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.selectConfusedWord(word),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 词汇
                Expanded(
                  child: Center(
                    child: Text(
                      word,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // 操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 帮助按钮
                    GestureDetector(
                      onTap: () => _showExplanationDialog(controller, word),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.help_outline,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // 选择解释按钮
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '解释',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 显示辅助解释弹窗
  void _showExplanationDialog(HomeController controller, String word) async {
    // 先获取解释
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
            // 标题
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
              // 简单解释
              Text(
                explanation.simpleExplanation,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF374151),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // 类比
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
              // 核心要点
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
            // 关闭按钮
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

  /// 成功界面
  Widget _buildSuccessView(HomeController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 庆祝图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          // 成功文字
          const Text(
            '🎉 解释清楚了！',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final history = controller.state.explanationHistory;
            return Text(
              '你解释了 ${history.length} 个概念',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            );
          }),
          const SizedBox(height: 24),
          // 继续学习按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.finishLearning,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
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
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildVoiceButton(HomeController controller) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -300) {
          controller.state.inputMode.value = InputMode.text;
        }
      },
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx < -10) {
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

  Widget _buildTextInput(HomeController controller) {
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
    this.onTap,
    required this.child,
  });

  final double cardWidth;
  final double cardHeight;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback onRestore;
  final VoidCallback? onTap;
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

  void _handlePanStart(DragStartDetails details) {
    // Start dragging
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      // 处理水平位移
      final dx = _dragOffset.dx + details.delta.dx;
      
      // 处理垂直位移：禁止向下拖动 (dy > 0)
      double dy = _dragOffset.dy + details.delta.dy;
      if (dy > 0) dy = 0;
      
      _dragOffset = Offset(dx, dy);
      
      // 计算旋转角度（左滑为负，右滑为正）
      _rotation = (_dragOffset.dx / widget.cardWidth) * 0.3;
      // 计算缩放（稍微缩小以增强效果），主要根据水平位移
      final horizontalRatio = (_dragOffset.dx.abs() / widget.cardWidth);
      _scale = 1.0 - horizontalRatio * 0.1;
      _scale = _scale.clamp(0.9, 1.0);

      // 仅在上滑时改变高度因子
      if (_dragOffset.dy < 0 && _dragOffset.dx.abs() < 20) {
        // 增加阻尼
        final verticalProgress = (_dragOffset.dy.abs() / (widget.cardHeight * 0.8)).clamp(0.0, 1.0);
        // 随上滑高度逐渐变矮，允许变到 0.25
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

    // 优先识别左右滑动切换卡片
    if (isHorizontalGesture &&
        (_dragOffset.dx.abs() > horizontalThreshold ||
            velocity.dx.abs() > 800)) {
      if (_dragOffset.dx < 0) {
        // 左滑
        _animateSwipe(true);
      } else {
        // 右滑
        _animateSwipe(false);
      }
      return;
    }

    // 上滑触发解释：向上滑动一定距离或速度
    final isUpSwipe = _dragOffset.dy < -verticalThreshold || velocity.dy < -800;
    if (!isHorizontalGesture && isUpSwipe) {
      // 1. 先通知外部进入「解释模式」：显示输入区 & 隐藏分页
      widget.onSwipeUp?.call();
      // 2. 再驱动卡片本身的上移 + 变矮动画
      _animateSwipeUp();
      return;
    }

    // 其他情况回弹
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
        // 执行回调并重置
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
    // 目标位置：大幅上移，腾出下方空间
    final targetOffset = Offset(0, -widget.cardHeight * 0.38);
    // 目标高度因子：大幅变矮，只保留顶部标题区域（约25%高度）
    const targetHeightFactor = 0.25;

    _controller.reset();
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    final startOffset = _dragOffset;
    final startHeightFactor = _heightFactor;
    // 恢复 scale 到 1.0，保证宽度不变
    final startScale = _scale;

    animation.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(startOffset, targetOffset, animation.value)!;
        _heightFactor = startHeightFactor +
            (targetHeightFactor - startHeightFactor) * animation.value;
        // 动画过程中把 scale 恢复到 1.0 (如果有水平移动导致的缩放)
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
      // 处于收起状态，执行恢复
      _animateRestore();
    } else {
      // 正常状态
      widget.onTap?.call();
    }
  }

  void _animateRestore() {
    // 通知外部状态恢复 (动画开始前)
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
        // 动画结束后再次确认状态恢复，防止中间被改
        widget.onRestore.call();
      }
    });

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    // 计算透明度提示
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
          // Left hint (上一张)
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
          // Right hint (下一张)
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
          // Card with transform
          Transform.translate(
            offset: _dragOffset,
            child: Transform.rotate(
              angle: _rotation,
              child: Transform.scale(
                scale: _scale,
                // 使用 SizedBox 控制高度变化，子组件背景自适应，内容被内部裁剪
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
