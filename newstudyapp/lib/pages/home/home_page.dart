import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'package:newstudyapp/pages/feynman_card/feynman_card_state.dart';
import 'package:newstudyapp/routes/app_routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HomeController(), tag: 'home');

    return Scaffold(
      body: Container(
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

            return Column(
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
            );
          }),
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
          child: _buildCardContent(term, category, cardWidth, cardHeight),
        ),
      );
    });
  }

  /// 构建卡片内容
  Widget _buildCardContent(
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
          height: cardHeight,
          child: Container(
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
                // Card content
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
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
                      const SizedBox(height: 16),
                      // Description placeholder
                      Text(
                        '点击下方按钮了解更多关于"$term"的内容',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: -0.44,
                          height: 1.5,
                        ),
                      ),
                      const Spacer(),
                      // Bottom button
                      GestureDetector(
                        onTap: () {
                          // 创建临时 FeynmanCard 对象用于详情页
                          final card = FeynmanCard(
                            category: category,
                            title: term,
                            description: '点击下方按钮了解更多关于"$term"的内容',
                          );
                          Get.toNamed(
                            AppRoutes.FEYNMAN_CARD_DETAIL,
                            arguments: card,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.menu_book,
                                size: 20,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '点击查看学习步骤',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    letterSpacing: -0.31,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
      final terms = controller.state.terms.value;
      if (terms == null || terms.isEmpty) {
        return const SizedBox.shrink();
      }
      
      final currentIndex = controller.state.currentCardIndex.value;
      final totalCards = terms.length;
      
      return Column(
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
      );
    });
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
    required this.child,
  });

  final double cardWidth;
  final double cardHeight;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
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
      _dragOffset += details.delta;
      // 计算旋转角度（左滑为负，右滑为正）
      _rotation = (_dragOffset.dx / widget.cardWidth) * 0.3;
      // 计算缩放（稍微缩小以增强效果）
      _scale = 1.0 - (_dragOffset.dx.abs() / widget.cardWidth) * 0.1;
      _scale = _scale.clamp(0.9, 1.0);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final threshold = widget.cardWidth * 0.3;

    // 判断是否触发滑动
    if (_dragOffset.dx.abs() > threshold || velocity.abs() > 800) {
      if (_dragOffset.dx < 0) {
        // 左滑
        _animateSwipe(true);
      } else {
        // 右滑
        _animateSwipe(false);
      }
    } else {
      // 回弹
      _animateReset();
    }
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
        _rotation = _rotation + (targetRotation - _rotation) * animation.value * 0.1;
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

  void _animateReset() {
    _controller.reset();
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    final startOffset = _dragOffset;
    final startRotation = _rotation;
    final startScale = _scale;

    animation.addListener(() {
      setState(() {
        _dragOffset = Offset.lerp(startOffset, Offset.zero, animation.value)!;
        _rotation = startRotation * (1 - animation.value);
        _scale = startScale + (1.0 - startScale) * animation.value;
      });
    });

    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    // 计算透明度提示
    final swipeProgress = (_dragOffset.dx.abs() / widget.cardWidth).clamp(0.0, 1.0);
    final leftHintOpacity = _dragOffset.dx < 0 ? swipeProgress : 0.0;
    final rightHintOpacity = _dragOffset.dx > 0 ? swipeProgress : 0.0;

    return GestureDetector(
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
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
