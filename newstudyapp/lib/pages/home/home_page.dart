import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'package:newstudyapp/pages/home/home_state.dart';
import 'package:newstudyapp/services/agent_service.dart';
import 'package:newstudyapp/config/app_config.dart';
import 'dart:math' as math;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 初始化或获取 Controller
    final controller = Get.isRegistered<HomeController>(tag: 'home')
        ? Get.find<HomeController>(tag: 'home')
        : Get.put(
            HomeController(),
            tag: 'home',
          );
    
    // 使用全局配置初始化 baseUrl
    if (controller.backendBaseUrl.value.isEmpty) {
      controller.backendBaseUrl.value = AppConfig.backendBaseUrl;
      controller.agentService = AgentService(baseUrl: AppConfig.backendBaseUrl);
      controller.loadTerms();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appTitle),
        actions: [
          Obx(() => IconButton(
            onPressed: controller.state.isLoading.value ? null : controller.loadTerms,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          )),
        ],
      ),
      body: _buildBody(context, controller),
    );
  }

  Widget _buildBody(BuildContext context, HomeController controller) {
    return Obx(() {
      final theme = Theme.of(context);

      if (controller.state.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.state.errorMessage.value != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  controller.state.errorMessage.value!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: theme.colorScheme.error),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: controller.loadTerms,
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        );
      }

      Widget mainContent;
      if (controller.state.terms.value == null || controller.state.terms.value!.isEmpty) {
        mainContent = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildConfirmedArea(theme, controller),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        controller.state.selectedTerm.value != null ? '已确认当前词汇' : '暂无词汇',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (controller.state.selectedTerm.value == null)
                        FilledButton.icon(
                          onPressed: controller.loadTerms,
                          icon: const Icon(Icons.refresh),
                          label: const Text('重新获取词汇'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildInputArea(theme, controller),
            ],
          ),
        );
      } else {
        final media = MediaQuery.of(context);
        final cardWidth =
            math.max(math.min(media.size.width * 0.85, 360.0), 260.0);
        final cardHeight = cardWidth * 1.45;

        mainContent = Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildConfirmedArea(theme, controller),
              Text(
                '类别：${controller.getCategoryDisplayName()}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: (!controller.state.floatingAnimating.value && controller.state.selectedTerm.value == null)
                        ? SizedBox(
                            key: const ValueKey('card-stack'),
                            width: cardWidth,
                            height: cardHeight,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: _buildCardStack(
                                theme,
                                cardWidth,
                                cardHeight,
                                controller,
                              ),
                            ),
                          )
                        : (controller.state.selectedTerm.value != null
                            ? _SelectionPlaceholder(theme: theme)
                            : const SizedBox.shrink()),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildInputArea(theme, controller),
            ],
          ),
        );
      }

      return Stack(
        children: [
          Positioned.fill(child: mainContent),
          if (controller.state.floatingAnimating.value && controller.state.floatingTerm.value != null)
            Positioned.fill(
              child: IgnorePointer(
                child: _buildFloatingCard(theme, controller),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildConfirmedArea(ThemeData theme, HomeController controller) {
    return Obx(() {
      final activeTerm = controller.state.floatingAnimating.value
          ? controller.state.floatingTerm.value
          : controller.state.selectedTerm.value;
      final showSelection = activeTerm != null;

      return AnimatedSize(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: showSelection
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '已确认词汇',
                        style: theme.textTheme.titleMedium,
                      ),
                      if (!controller.state.floatingAnimating.value && controller.state.selectedTerm.value != null)
                        TextButton.icon(
                          onPressed: controller.resumeSelection,
                          icon: const Icon(Icons.refresh),
                          label: const Text('重新选择'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: controller.state.floatingAnimating.value
                        ? const SizedBox.shrink()
                        : _SelectedTermCard(term: controller.state.selectedTerm.value!),
                  ),
                  const SizedBox(height: 16),
                ],
              )
            : const SizedBox.shrink(),
      );
    });
  }

  Widget _buildInputArea(ThemeData theme, HomeController controller) {
    return Obx(() {
      if (controller.state.selectedTerm.value == null) {
        return const SizedBox.shrink();
      }

      final isVoice = controller.state.inputMode.value == InputMode.voice;
      final surfaceColor = theme.colorScheme.surfaceVariant;
      final textPlaceholder = controller.state.textInputController.text.isEmpty
          ? '输入新的词汇或备注'
          : 'AI 的解释（可继续编辑）';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '输入方式',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('语音'),
                avatar: const Icon(Icons.mic, size: 18),
                selected: isVoice,
                onSelected: (selected) {
                  if (selected && controller.state.inputMode.value != InputMode.voice) {
                    controller.state.inputMode.value = InputMode.voice;
                    controller.state.textInputController.clear();
                  }
                },
              ),
              ChoiceChip(
                label: const Text('文本'),
                avatar: const Icon(Icons.keyboard_alt_rounded, size: 18),
                selected: !isVoice,
                onSelected: (selected) {
                  if (selected && controller.state.inputMode.value != InputMode.text) {
                    controller.state.inputMode.value = InputMode.text;
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isVoice
                  ? _VoiceInputPanel(
                      key: const ValueKey('voice-mode'),
                      theme: theme,
                      surfaceColor: surfaceColor,
                      onTap: () {
                        Get.snackbar(
                          '提示',
                          '语音输入功能开发中',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(milliseconds: 1500),
                        );
                      },
                    )
                  : _TextInputPanel(
                      key: const ValueKey('text-mode'),
                      theme: theme,
                      surfaceColor: surfaceColor,
                      controller: controller.state.textInputController,
                      onSubmit: controller.handleTextSubmit,
                      isSubmitting: controller.state.isSubmittingSuggestion.value,
                      placeholder: textPlaceholder,
                    ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFloatingCard(ThemeData theme, HomeController controller) {
    return Obx(() {
      final term = controller.state.floatingTerm.value;
      if (term == null) {
        return const SizedBox.shrink();
      }

      final baseWidth = controller.state.floatingCardWidth.value ?? 300;
      final baseHeight = controller.state.floatingCardHeight.value ?? baseWidth * 1.45;

      return AnimatedAlign(
        alignment: controller.state.floatingAlignment.value,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
        onEnd: controller.handleFloatingAnimationEnd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic,
          width: baseWidth * controller.state.floatingSizeFactor.value,
          height: baseHeight * controller.state.floatingSizeFactor.value,
          child: _TermCard(
            term: term,
            width: baseWidth * controller.state.floatingSizeFactor.value,
            height: baseHeight * controller.state.floatingSizeFactor.value,
            showHint: false,
          ),
        ),
      );
    });
  }

  List<Widget> _buildCardStack(
    ThemeData theme,
    double cardWidth,
    double cardHeight,
    HomeController controller,
  ) {
    final widgets = <Widget>[];
    final terms = controller.state.terms.value ?? [];
    final visibleCount = math.min(terms.length, 3);
    const animationDuration = Duration(milliseconds: 260);
    const animationCurve = Curves.easeOutCubic;

    // 倒序遍历：从后往前，先添加底层卡片，再添加顶层卡片
    // 这样Stack中最后添加的terms[0]就会显示在最上面
    for (var index = visibleCount - 1; index >= 0; index--) {
      final term = terms[index];
      // index越小，layer值越小，verticalOffset越小（越靠上）
      final layer = index;
      final verticalOffset = layer * 20.0;
      final scale = 1.0 - layer * 0.05;
      // terms[0]是最顶层卡片，可交互
      final isTop = index == 0;

      final cardSurface = _buildCardSurface(
        term,
        theme,
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        isTop: isTop,
        controller: controller,
      );

      widgets.add(
        AnimatedPositioned(
          key: ValueKey('card-position-$term'),
          duration: animationDuration,
          curve: animationCurve,
          left: 0,
          right: 0,
          top: verticalOffset,
          child: AnimatedScale(
            scale: scale,
            duration: animationDuration,
            curve: animationCurve,
            alignment: Alignment.center,
            child: cardSurface,
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildCardSurface(
    String term,
    ThemeData theme, {
    required double cardWidth,
    required double cardHeight,
    required bool isTop,
    required HomeController controller,
  }) {
    final cardContent = _TermCard(
      term: term,
      width: cardWidth,
      height: cardHeight,
      showHint: isTop,
    );

    if (!isTop) {
      return IgnorePointer(
        child: Opacity(
          opacity: 0.85,
          child: cardContent,
        ),
      );
    }

    return _SwipeableCard(
      key: ValueKey(term),
      term: term,
      width: cardWidth,
      height: cardHeight,
      onExplain: controller.handleCardExplain,
      isExplainInProgress: controller.state.isExplaining.value,
      onDismissed: (isConfirm) =>
          controller.handleCardDismiss(term, isConfirm, cardWidth, cardHeight),
      child: cardContent,
    );
  }
}

class _SelectionPlaceholder extends StatelessWidget {
  const _SelectionPlaceholder({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('selection-placeholder'),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_outlined,
              size: 40, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            '已确认当前词汇',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '如需重新挑选，请点击上方"重新选择"。',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _VoiceInputPanel extends StatelessWidget {
  const _VoiceInputPanel({
    super.key,
    required this.theme,
    required this.surfaceColor,
    required this.onTap,
  });

  final ThemeData theme;
  final Color surfaceColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(26),
              backgroundColor: theme.colorScheme.primary,
            ),
            onPressed: onTap,
            child: Icon(
              Icons.mic,
              size: 36,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '按住开始说话，松开发送语音内容',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TextInputPanel extends StatelessWidget {
  const _TextInputPanel({
    super.key,
    required this.theme,
    required this.surfaceColor,
    required this.controller,
    required this.onSubmit,
    required this.isSubmitting,
    required this.placeholder,
  });

  final ThemeData theme;
  final Color surfaceColor;
  final TextEditingController controller;
  final Future<void> Function(String text) onSubmit;
  final bool isSubmitting;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            minLines: 3,
            decoration: InputDecoration(
              labelText: placeholder,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final trimmed = value.text.trim();
              final canSend = trimmed.isNotEmpty;
              final submitting = isSubmitting;

              return Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed:
                      (!canSend || submitting) ? null : () => onSubmit(trimmed),
                  icon: submitting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(submitting ? '提交中...' : '提交'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({
    required this.term,
    required this.width,
    required this.height,
    required this.showHint,
  });

  final String term;
  final double width;
  final double height;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: Card(
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.class_, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 28),
              Text(
                term,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showHint) ...[
                const SizedBox(height: 24),
                Text(
                  '向左滑动查看下一个词，向右滑动表示确认',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedTermCard extends StatelessWidget {
  const _SelectedTermCard({required this.term});

  final String term;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              term,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeableCard extends StatefulWidget {
  const _SwipeableCard({
    super.key,
    required this.term,
    required this.width,
    required this.height,
    required this.child,
    required this.onExplain,
    required this.isExplainInProgress,
    required this.onDismissed,
  });

  final String term;
  final double width;
  final double height;
  final Widget child;
  final Future<void> Function(String term) onExplain;
  final bool isExplainInProgress;
  final ValueChanged<bool> onDismissed;

  @override
  State<_SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<_SwipeableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Animation<Offset>? _offsetAnimation;
  Animation<double>? _rotationAnimation;
  Animation<double>? _scaleAnimation;

  Offset _offset = Offset.zero;
  double _rotation = 0;
  double _scale = 1;
  bool _isAnimating = false;
  bool? _pendingConfirm;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),  // 增加到600ms，让回弹更柔和
    )
      ..addListener(_handleAnimationTick)
      ..addStatusListener(_handleAnimationStatus);
  }

  @override
  void didUpdateWidget(covariant _SwipeableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.term != widget.term) {
      _controller.stop();
      _offset = Offset.zero;
      _rotation = 0;
      _scale = 1;
      _pendingConfirm = null;
      _isAnimating = false;
      _offsetAnimation = null;
      _rotationAnimation = null;
      _scaleAnimation = null;
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleAnimationTick)
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  void _handleAnimationTick() {
    if (!mounted) {
      return;
    }
    setState(() {
      if (_offsetAnimation != null) {
        _offset = _offsetAnimation!.value;
      }
      if (_rotationAnimation != null) {
        _rotation = _rotationAnimation!.value;
      }
      if (_scaleAnimation != null) {
        _scale = _scaleAnimation!.value;
      }
    });
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) {
      return;
    }

    if (_pendingConfirm != null) {
      final confirm = _pendingConfirm!;
      _pendingConfirm = null;
      _offsetAnimation = null;
      _rotationAnimation = null;
      _scaleAnimation = null;
      _isAnimating = false;
      widget.onDismissed(confirm);
      return;
    }

    _resetToCenter();
  }

  void _resetToCenter() {
    _offset = Offset.zero;
    _rotation = 0;
    _scale = 1;
    _isAnimating = false;
    _pendingConfirm = null;
    _offsetAnimation = null;
    _rotationAnimation = null;
    _scaleAnimation = null;
    if (mounted) {
      setState(() {});
    }
  }

  void _animateDismiss(bool isConfirm) {
    _controller.stop();
    _pendingConfirm = isConfirm;
    _isAnimating = true;
    final curve = CurvedAnimation(
      parent: _controller,
      curve: isConfirm ? Curves.easeInOutCubic : Curves.easeIn,
    );

    if (isConfirm) {
      _offsetAnimation = Tween<Offset>(
        begin: _offset,
        end: Offset(0, -widget.height * 1.2),
      ).animate(curve);
      _rotationAnimation = Tween<double>(
        begin: _rotation,
        end: 0,
      ).animate(curve);
      _scaleAnimation = Tween<double>(
        begin: _scale,
        end: 0.55,
      ).animate(curve);
    } else {
      _offsetAnimation = Tween<Offset>(
        begin: _offset,
        end: Offset(-widget.width * 1.3, widget.height * 0.1),
      ).animate(curve);
      _rotationAnimation = Tween<double>(
        begin: _rotation,
        end: -0.45,
      ).animate(curve);
      _scaleAnimation = Tween<double>(
        begin: _scale,
        end: 1,
      ).animate(curve);
    }

    _controller.forward(from: 0);
  }

  void _animateReset() {
    _controller.stop();
    _pendingConfirm = null;
    _isAnimating = true;

    // 使用弹性曲线，带有更明显的回弹效果
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,  // 使用elasticOut曲线，带有弹性回弹效果
    );

    _offsetAnimation =
        Tween<Offset>(begin: _offset, end: Offset.zero).animate(curve);
    _rotationAnimation = Tween<double>(begin: _rotation, end: 0).animate(curve);
    _scaleAnimation = Tween<double>(begin: _scale, end: 1).animate(curve);

    _controller.forward(from: 0);
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating) {
      return;
    }
    _controller.stop();
    _offsetAnimation = null;
    _rotationAnimation = null;
    _scaleAnimation = null;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating) {
      return;
    }
    setState(() {
      final newDx = _offset.dx + details.delta.dx;
      _offset = Offset(newDx, 0);
      final normalized = (_offset.dx / widget.width).clamp(-1.0, 1.0);
      _rotation = normalized * 0.4;
      _scale = 1;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating) {
      return;
    }
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final threshold = widget.width * 0.32;
    final hasVelocity = velocityX.abs() > 650;
    final shouldDismiss = _offset.dx.abs() > threshold || hasVelocity;

    if (shouldDismiss) {
      final isConfirm = (_offset.dx + velocityX * 0.1) > 0;
      _animateDismiss(isConfirm);
    } else {
      _animateReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_offset.dx / widget.width).clamp(-1.0, 1.0);
    final confirmOpacity =
        progress > 0 ? progress.abs().clamp(0.0, 1.0).toDouble() : 0.0;
    final skipOpacity =
        progress < 0 ? progress.abs().clamp(0.0, 1.0).toDouble() : 0.0;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: GestureDetector(
        onLongPress: widget.isExplainInProgress
            ? null
            : () => widget.onExplain(widget.term),
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 移除滑动提示层，保留纯净的卡片滚动效果
            Transform.translate(
              offset: _offset,
              child: Transform.rotate(
                angle: _rotation,
                child: Transform.scale(
                  scale: _scale,
                  alignment: Alignment.topCenter,
                  child: widget.child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardActionOverlay extends StatelessWidget {
  const _CardActionOverlay({
    required this.alignment,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.label,
  });

  final Alignment alignment;
  final IconData icon;
  final Color color;
  final Color textColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
