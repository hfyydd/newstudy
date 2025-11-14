import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:newstudyapp/services/agent_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.title,
    required this.backendBaseUrl,
  });

  final String title;
  final String backendBaseUrl;

  @override
  State<HomePage> createState() => _HomePageState();
}

enum _FloatingPhase { idle, flyingUp, flyingDown }

enum _InputMode { voice, text }

class _HomePageState extends State<HomePage> {
  late final AgentService _agentService;

  bool _isLoading = true;
  List<String>? _terms;
  String? _selectedTerm;
  bool _isAppending = false;
  String? _floatingTerm;
  double? _floatingCardWidth;
  double? _floatingCardHeight;
  Alignment _floatingAlignment = Alignment.center;
  double _floatingSizeFactor = 1.0;
  bool _floatingAnimating = false;
  _FloatingPhase _floatingPhase = _FloatingPhase.idle;
  _InputMode _inputMode = _InputMode.voice;
  bool _isExplaining = false;
  bool _isSubmittingSuggestion = false;
  final TextEditingController _textInputController = TextEditingController();
  String _activeCategory = _defaultCategory;
  String? _errorMessage;

  static const String _defaultCategory = 'economics';
  static const Alignment _floatingTargetAlignment = Alignment(-0.9, -0.9);
  static const double _floatingTargetSizeFactor = 0.55;

  @override
  void initState() {
    super.initState();
    _agentService = AgentService(baseUrl: widget.backendBaseUrl);
    _loadTerms();
  }

  @override
  void dispose() {
    _agentService.dispose();
    _textInputController.dispose();
    super.dispose();
  }

  Future<void> _loadTerms() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _terms = null;
      _selectedTerm = null;
      _isAppending = false;
      _floatingTerm = null;
      _floatingAnimating = false;
      _floatingCardWidth = null;
      _floatingCardHeight = null;
      _floatingAlignment = Alignment.center;
      _floatingSizeFactor = 1.0;
      _floatingPhase = _FloatingPhase.idle;
      _inputMode = _InputMode.voice;
      _isSubmittingSuggestion = false;
      _textInputController.clear();
    });
    try {
      final response =
          await _agentService.fetchTerms(category: _activeCategory);
      setState(() {
        _terms = List.of(response.terms);
        _activeCategory = response.category;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = '获取术语失败：$error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadTerms,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildConfirmedArea(ThemeData theme) {
    final activeTerm = _floatingAnimating ? _floatingTerm : _selectedTerm;
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
                    if (!_floatingAnimating && _selectedTerm != null)
                      TextButton.icon(
                        onPressed: _resumeSelection,
                        icon: const Icon(Icons.refresh),
                        label: const Text('重新选择'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: _floatingAnimating
                      ? const SizedBox.shrink()
                      : _SelectedTermCard(term: _selectedTerm!),
                ),
                const SizedBox(height: 16),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    if (_selectedTerm == null) {
      return const SizedBox.shrink();
    }

    final isVoice = _inputMode == _InputMode.voice;
    final surfaceColor = theme.colorScheme.surfaceVariant;
    final textPlaceholder =
        _textInputController.text.isEmpty ? '输入新的词汇或备注' : 'AI 的解释（可继续编辑）';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '输入方式',
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                if (selected && _inputMode != _InputMode.voice) {
                  setState(() {
                    _inputMode = _InputMode.voice;
                    _textInputController.clear();
                  });
                }
              },
            ),
            ChoiceChip(
              label: const Text('文本'),
              avatar: const Icon(Icons.keyboard_alt_rounded, size: 18),
              selected: !isVoice,
              onSelected: (selected) {
                if (selected && _inputMode != _InputMode.text) {
                  setState(() {
                    _inputMode = _InputMode.text;
                  });
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('语音输入功能开发中'),
                          duration: Duration(milliseconds: 1500),
                        ),
                      );
                    },
                  )
                : _TextInputPanel(
                    key: const ValueKey('text-mode'),
                    theme: theme,
                    surfaceColor: surfaceColor,
                    controller: _textInputController,
                    onSubmit: _handleTextSubmit,
                    isSubmitting: _isSubmittingSuggestion,
                    placeholder: textPlaceholder,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingCard(ThemeData theme) {
    final term = _floatingTerm;
    if (term == null) {
      return const SizedBox.shrink();
    }

    final baseWidth = _floatingCardWidth ?? 300;
    final baseHeight = _floatingCardHeight ?? baseWidth * 1.45;

    return AnimatedAlign(
      alignment: _floatingAlignment,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOutCubic,
      onEnd: _handleFloatingAnimationEnd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
        width: baseWidth * _floatingSizeFactor,
        height: baseHeight * _floatingSizeFactor,
        child: _TermCard(
          term: term,
          width: baseWidth * _floatingSizeFactor,
          height: baseHeight * _floatingSizeFactor,
          showHint: false,
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadTerms,
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    Widget mainContent;
    if (_terms == null || _terms!.isEmpty) {
      mainContent = Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConfirmedArea(theme),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedTerm != null ? '已确认当前词汇' : '暂无词汇',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedTerm == null)
                      FilledButton.icon(
                        onPressed: _loadTerms,
                        icon: const Icon(Icons.refresh),
                        label: const Text('重新获取词汇'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInputArea(theme),
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
            _buildConfirmedArea(theme),
            Text(
              '类别：${_categoryDisplayName()}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: (!_floatingAnimating && _selectedTerm == null)
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
                            ),
                          ),
                        )
                      : (_selectedTerm != null
                          ? _SelectionPlaceholder(theme: theme)
                          : const SizedBox.shrink()),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInputArea(theme),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: mainContent),
        if (_floatingAnimating && _floatingTerm != null)
          Positioned.fill(
            child: IgnorePointer(
              child: _buildFloatingCard(theme),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildCardStack(
    ThemeData theme,
    double cardWidth,
    double cardHeight,
  ) {
    final widgets = <Widget>[];
    final terms = _terms!;
    final visibleCount = math.min(terms.length, 3);
    const animationDuration = Duration(milliseconds: 260);
    const animationCurve = Curves.easeOutCubic;

    for (var index = visibleCount - 1; index >= 0; index--) {
      final term = terms[index];
      final layer = index;
      final verticalOffset = layer * 20.0;
      final scale = 1.0 - layer * 0.05;

      final cardSurface = _buildCardSurface(
        term,
        theme,
        cardWidth: cardWidth,
        cardHeight: cardHeight,
        isTop: index == 0,
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
      onExplain: _handleCardExplain,
      isExplainInProgress: _isExplaining,
      onDismissed: (isConfirm) =>
          _handleCardDismiss(term, isConfirm, cardWidth, cardHeight),
      child: cardContent,
    );
  }

  void _handleCardDismiss(
    String term,
    bool isConfirm,
    double cardWidth,
    double cardHeight,
  ) {
    if (isConfirm) {
      setState(() {
        _terms!.remove(term);
        _floatingTerm = term;
        _floatingCardWidth = cardWidth;
        _floatingCardHeight = cardHeight;
        _floatingAlignment = Alignment.center;
        _floatingSizeFactor = 1.0;
        _floatingAnimating = true;
        _floatingPhase = _FloatingPhase.flyingUp;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_floatingAnimating) {
          return;
        }
        setState(() {
          _floatingAlignment = _floatingTargetAlignment;
          _floatingSizeFactor = _floatingTargetSizeFactor;
        });
      });
    } else {
      setState(() {
        _terms!.remove(term);
      });
      _maybeReplenishDeck();
    }
  }

  void _resumeSelection() {
    final term = _selectedTerm;
    if (term == null || _floatingAnimating) {
      return;
    }
    final media = MediaQuery.of(context);
    final cardWidth = math.max(math.min(media.size.width * 0.85, 360.0), 260.0);
    final cardHeight = cardWidth * 1.45;

    setState(() {
      _floatingTerm = term;
      _floatingCardWidth = cardWidth;
      _floatingCardHeight = cardHeight;
      _floatingAnimating = true;
      _floatingPhase = _FloatingPhase.flyingDown;
      _floatingAlignment = _floatingTargetAlignment;
      _floatingSizeFactor = _floatingTargetSizeFactor;
      _inputMode = _InputMode.voice;
      _textInputController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _floatingPhase != _FloatingPhase.flyingDown) {
        return;
      }
      setState(() {
        _floatingAlignment = Alignment.center;
        _floatingSizeFactor = 1.0;
      });
    });
  }

  Future<void> _handleCardExplain(String term) async {
    if (_isExplaining) {
      return;
    }
    setState(() {
      _isExplaining = true;
    });

    try {
      final response = await _agentService.runSimpleExplainer(term);
      final suggestion = response.reply.trim();
      if (mounted) {
        setState(() {
          _inputMode = _InputMode.text;
        });
        _textInputController.text = suggestion;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取解释失败：$error'),
            duration: const Duration(milliseconds: 1800),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExplaining = false;
        });
      }
    }
  }

  Future<void> _handleTextSubmit(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSubmittingSuggestion) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmittingSuggestion = true;
    });

    try {
      debugPrint('[HomePage] Submit text: "$trimmed"');
      final response = await _agentService.runCuriousStudent(trimmed);
      debugPrint('[HomePage] Raw reply: ${response.reply}');
      final extraction = _extractTermsFromReply(
        reply: response.reply,
        originalText: trimmed,
      );
      final extracted = extraction.terms;
      debugPrint('[HomePage] Extracted terms: $extracted');

      if (extracted.isEmpty) {
        if (extraction.isClear) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('解释已清楚，无需新增词汇'),
                duration: Duration(milliseconds: 1500),
              ),
            );
            setState(() {
              _selectedTerm = null;
              _floatingTerm = null;
              _floatingAnimating = false;
              _floatingCardWidth = null;
              _floatingCardHeight = null;
              _floatingAlignment = Alignment.center;
              _floatingSizeFactor = 1.0;
              _floatingPhase = _FloatingPhase.idle;
              _inputMode = _InputMode.voice;
            });
            _textInputController.clear();
          }
          _maybeReplenishDeck();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('未从响应中解析到词汇，请重试'),
                duration: Duration(milliseconds: 1500),
              ),
            );
          }
        }
        return;
      }

      if (mounted) {
        setState(() {
          _terms = List.of(extracted);
          _selectedTerm = null;
          _floatingTerm = null;
          _floatingAnimating = false;
          _floatingCardWidth = null;
          _floatingCardHeight = null;
          _floatingAlignment = Alignment.center;
          _floatingSizeFactor = 1.0;
          _floatingPhase = _FloatingPhase.idle;
          _inputMode = _InputMode.voice;
        });
        _textInputController.clear();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获取词汇失败：$error'),
            duration: const Duration(milliseconds: 1800),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingSuggestion = false;
        });
      }
    }
  }

  void _handleFloatingAnimationEnd() {
    if (!_floatingAnimating) {
      return;
    }

    final term = _floatingTerm ?? _selectedTerm;
    if (term == null) {
      setState(() {
        _floatingAnimating = false;
        _floatingPhase = _FloatingPhase.idle;
        _floatingAlignment = Alignment.center;
        _floatingSizeFactor = 1.0;
      });
      return;
    }

    if (_floatingPhase == _FloatingPhase.flyingUp &&
        _floatingAlignment == _floatingTargetAlignment) {
      setState(() {
        _selectedTerm = term;
        _floatingTerm = null;
        _floatingAnimating = false;
        _floatingSizeFactor = 1.0;
        _floatingPhase = _FloatingPhase.idle;
        _floatingAlignment = Alignment.center;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已确认：$term'),
          duration: const Duration(milliseconds: 1200),
        ),
      );

      _maybeReplenishDeck();
    } else if (_floatingPhase == _FloatingPhase.flyingDown &&
        _floatingAlignment == Alignment.center) {
      setState(() {
        _terms ??= <String>[];
        if (!_terms!.contains(term)) {
          _terms!.insert(0, term);
        }
        _selectedTerm = null;
        _floatingTerm = null;
        _floatingAnimating = false;
        _floatingCardWidth = null;
        _floatingCardHeight = null;
        _floatingAlignment = Alignment.center;
        _floatingSizeFactor = 1.0;
        _floatingPhase = _FloatingPhase.idle;
      });

      _maybeReplenishDeck();
    }
  }

  _ExtractionResult _extractTermsFromReply({
    required String reply,
    required String originalText,
  }) {
    final trimmed = reply.trim();
    if (trimmed.isEmpty) {
      return _ExtractionResult.empty();
    }

    final jsonCandidate = _extractJsonBlock(trimmed);
    if (jsonCandidate != null) {
      debugPrint('[HomePage] JSON candidate: $jsonCandidate');
      try {
        final decoded = jsonDecode(jsonCandidate);
        if (decoded is Map<String, dynamic>) {
          final status = decoded['status'];
          final wordsRaw = decoded['words'];
          if (status == 'confused' && wordsRaw is List) {
            final terms = wordsRaw
                .whereType<String>()
                .map((word) => word.replaceAll(RegExp(r'^<|>$'), '').trim())
                .where((word) => word.isNotEmpty)
                .take(10)
                .toList(growable: false);
            if (terms.isNotEmpty) {
              return _ExtractionResult(terms: terms, isClear: false);
            }
          }
          if (status == 'clear') {
            return const _ExtractionResult(terms: <String>[], isClear: true);
          }
        }
      } catch (error, stackTrace) {
        debugPrint('[HomePage] JSON parse error: $error');
        debugPrint('[HomePage] Stack trace: $stackTrace');
        // fall through to fallback parsing
      }
    }

    final parts = trimmed
        .split(RegExp(r'[\s,，；;。.!?\n\r]+'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      debugPrint('[HomePage] Fallback split produced 0 parts');
      return _ExtractionResult.empty();
    }

    final unique = <String>[];
    for (final part in parts) {
      final normalized = part.replaceAll(RegExp(r'^<|>$'), '');
      if (normalized.isEmpty) {
        continue;
      }
      if (!unique.contains(normalized)) {
        unique.add(normalized);
      }
      if (unique.length >= 10) {
        break;
      }
    }
    debugPrint('[HomePage] Fallback terms: $unique');
    return _ExtractionResult(terms: unique, isClear: false);
  }

  String? _extractJsonBlock(String text) {
    if (text.startsWith('```')) {
      debugPrint('[HomePage] Detected code block response');
      final startBrace = text.indexOf('{');
      final endBrace = text.lastIndexOf('}');
      if (startBrace != -1 && endBrace > startBrace) {
        return text.substring(startBrace, endBrace + 1);
      }
    }

    if (text.startsWith('{') && text.endsWith('}')) {
      debugPrint('[HomePage] Reply appears to be pure JSON');
      return text;
    }

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) {
      debugPrint('[HomePage] Found JSON within text block');
      return text.substring(start, end + 1);
    }

    debugPrint('[HomePage] No JSON block detected');

    return null;
  }

  String _categoryDisplayName() {
    switch (_activeCategory) {
      case 'economics':
        return '经济学';
      default:
        return _activeCategory;
    }
  }

  void _maybeReplenishDeck() {
    if (_terms == null ||
        _terms!.length > 1 ||
        _isAppending ||
        _floatingAnimating) {
      return;
    }
    _fetchAdditionalTerms();
  }

  Future<void> _fetchAdditionalTerms() async {
    if (_isAppending) {
      return;
    }
    _isAppending = true;
    try {
      final response =
          await _agentService.fetchTerms(category: _activeCategory);
      if (!mounted || _terms == null) {
        return;
      }
      final existing = <String>{..._terms!};
      if (_selectedTerm != null) {
        existing.add(_selectedTerm!);
      }
      if (_floatingTerm != null) {
        existing.add(_floatingTerm!);
      }
      final newTerms = response.terms.where((term) => !existing.contains(term));
      if (newTerms.isNotEmpty) {
        setState(() {
          _terms!.addAll(newTerms);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('暂无更多新的词汇可补充'),
            duration: Duration(milliseconds: 1600),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('补充词汇失败：$error'),
          duration: const Duration(milliseconds: 1800),
        ),
      );
    } finally {
      _isAppending = false;
    }
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
            '如需重新挑选，请点击上方“重新选择”。',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ExtractionResult {
  const _ExtractionResult({required this.terms, required this.isClear});

  final List<String> terms;
  final bool isClear;

  static _ExtractionResult empty() =>
      const _ExtractionResult(terms: <String>[], isClear: false);
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
      duration: const Duration(milliseconds: 280),
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

    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
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
            Opacity(
              opacity: confirmOpacity,
              child: _CardActionOverlay(
                alignment: Alignment.centerLeft,
                icon: Icons.check_circle,
                color: theme.colorScheme.primaryContainer,
                textColor: theme.colorScheme.onPrimaryContainer,
                label: '确认',
              ),
            ),
            Opacity(
              opacity: skipOpacity,
              child: _CardActionOverlay(
                alignment: Alignment.centerRight,
                icon: Icons.skip_next,
                color: theme.colorScheme.secondaryContainer,
                textColor: theme.colorScheme.onSecondaryContainer,
                label: '跳过',
              ),
            ),
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
