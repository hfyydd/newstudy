import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:newstudyapp/pages/home/home_state.dart';
import 'package:newstudyapp/services/agent_service.dart';

class HomeController extends GetxController {
  late final AgentService agentService;
  late final HomeState state;

  final backendBaseUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    state = HomeState();
  }

  void initializeWithBaseUrl(String baseUrl) {
    if (baseUrl.isNotEmpty) {
      backendBaseUrl.value = baseUrl;
      agentService = AgentService(baseUrl: baseUrl);
      loadTerms();
    }
  }

  @override
  void onClose() {
    agentService.dispose();
    state.dispose();
    super.onClose();
  }

  Future<void> loadTerms() async {
    state.errorMessage.value = null;
    state.isLoading.value = true;
    state.terms.value = null;
    state.selectedTerm.value = null;
    state.isAppending.value = false;
    state.floatingTerm.value = null;
    state.floatingAnimating.value = false;
    state.floatingCardWidth.value = null;
    state.floatingCardHeight.value = null;
    state.floatingAlignment.value = Alignment.center;
    state.floatingSizeFactor.value = 1.0;
    state.floatingPhase.value = FloatingPhase.idle;
    state.inputMode.value = InputMode.voice;
    state.isSubmittingSuggestion.value = false;
    state.textInputController.clear();

    try {
      final response = await agentService.fetchTerms(category: state.activeCategory.value);
      state.terms.value = List.of(response.terms);
      state.activeCategory.value = response.category;
      state.isLoading.value = false;
    } catch (error) {
      state.errorMessage.value = '获取术语失败：$error';
      state.isLoading.value = false;
    }
  }

  void handleCardDismiss(
    String term,
    bool isConfirm,
    double cardWidth,
    double cardHeight,
  ) {
    if (isConfirm) {
      // 先从列表中移除该术语
      state.terms.value?.remove(term);
      state.terms.refresh();  // 通知GetX更新UI
      
      state.floatingTerm.value = term;
      state.floatingCardWidth.value = cardWidth;
      state.floatingCardHeight.value = cardHeight;
      state.floatingAlignment.value = Alignment.center;
      state.floatingSizeFactor.value = 1.0;
      state.floatingAnimating.value = true;
      state.floatingPhase.value = FloatingPhase.flyingUp;

      Future.delayed(const Duration(milliseconds: 50), () {
        if (state.floatingAnimating.value) {
          state.floatingAlignment.value = HomeState.floatingTargetAlignment;
          state.floatingSizeFactor.value = HomeState.floatingTargetSizeFactor;
        }
      });
    } else {
      // 向左滑动跳过：先从列表中移除该术语
      state.terms.value?.remove(term);
      state.terms.refresh();  // 通知GetX更新UI
      maybeReplenishDeck();
    }
  }

  void resumeSelection() {
    final term = state.selectedTerm.value;
    if (term == null || state.floatingAnimating.value) {
      return;
    }

    state.floatingTerm.value = term;
    state.floatingAnimating.value = true;
    state.floatingPhase.value = FloatingPhase.flyingDown;
    state.floatingAlignment.value = HomeState.floatingTargetAlignment;
    state.floatingSizeFactor.value = HomeState.floatingTargetSizeFactor;
    state.inputMode.value = InputMode.voice;
    state.textInputController.clear();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (state.floatingPhase.value == FloatingPhase.flyingDown) {
        state.floatingAlignment.value = Alignment.center;
        state.floatingSizeFactor.value = 1.0;
      }
    });
  }

  Future<void> handleCardExplain(String term) async {
    if (state.isExplaining.value) {
      return;
    }
    state.isExplaining.value = true;

    try {
      final response = await agentService.runSimpleExplainer(term);
      final replyText = response.reply.trim();

      String explanationText = replyText;
      try {
        final jsonCandidate = _extractJsonBlock(replyText);
        if (jsonCandidate != null) {
          final decoded = jsonDecode(jsonCandidate);
          if (decoded is Map<String, dynamic>) {
            final explanations = decoded['explanations'];
            if (explanations is List && explanations.isNotEmpty) {
              final firstExplanation = explanations[0];
              if (firstExplanation is Map<String, dynamic>) {
                final simpleExplanation = firstExplanation['simple_explanation'];
                if (simpleExplanation is String && simpleExplanation.isNotEmpty) {
                  explanationText = simpleExplanation;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[HomeController] Failed to parse explanation JSON: $e');
      }

      state.inputMode.value = InputMode.text;
      state.textInputController.text = explanationText;
    } catch (error) {
      Get.snackbar(
        '错误',
        '获取解释失败：$error',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 1800),
      );
    } finally {
      state.isExplaining.value = false;
    }
  }

  Future<void> handleTextSubmit(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSubmittingSuggestion.value) {
      return;
    }

    state.isSubmittingSuggestion.value = true;

    try {
      debugPrint('[HomeController] Submit text: "$trimmed"');
      final response = await agentService.runCuriousStudent(trimmed);
      debugPrint('[HomeController] Raw reply: ${response.reply}');
      final extraction = _extractTermsFromReply(
        reply: response.reply,
        originalText: trimmed,
      );
      final extracted = extraction.terms;
      debugPrint('[HomeController] Extracted terms: $extracted');

      if (extracted.isEmpty) {
        if (extraction.isClear) {
          Get.snackbar(
            '提示',
            '解释已清楚，无需新增词汇',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(milliseconds: 1500),
          );
          state.selectedTerm.value = null;
          state.floatingTerm.value = null;
          state.floatingAnimating.value = false;
          state.floatingCardWidth.value = null;
          state.floatingCardHeight.value = null;
          state.floatingAlignment.value = Alignment.center;
          state.floatingSizeFactor.value = 1.0;
          state.floatingPhase.value = FloatingPhase.idle;
          state.inputMode.value = InputMode.voice;
          state.textInputController.clear();
          maybeReplenishDeck();
        } else {
          Get.snackbar(
            '提示',
            '未从响应中解析到词汇，请重试',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(milliseconds: 1500),
          );
        }
        return;
      }

      state.terms.value = List.of(extracted);
      state.selectedTerm.value = null;
      state.floatingTerm.value = null;
      state.floatingAnimating.value = false;
      state.floatingCardWidth.value = null;
      state.floatingCardHeight.value = null;
      state.floatingAlignment.value = Alignment.center;
      state.floatingSizeFactor.value = 1.0;
      state.floatingPhase.value = FloatingPhase.idle;
      state.inputMode.value = InputMode.voice;
      state.textInputController.clear();
    } catch (error) {
      Get.snackbar(
        '错误',
        '获取词汇失败：$error',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 1800),
      );
    } finally {
      state.isSubmittingSuggestion.value = false;
    }
  }

  void handleFloatingAnimationEnd() {
    if (!state.floatingAnimating.value) {
      return;
    }

    final term = state.floatingTerm.value ?? state.selectedTerm.value;
    if (term == null) {
      state.floatingAnimating.value = false;
      state.floatingPhase.value = FloatingPhase.idle;
      state.floatingAlignment.value = Alignment.center;
      state.floatingSizeFactor.value = 1.0;
      return;
    }

    if (state.floatingPhase.value == FloatingPhase.flyingUp &&
        state.floatingAlignment.value == HomeState.floatingTargetAlignment) {
      state.selectedTerm.value = term;
      state.floatingTerm.value = null;
      state.floatingAnimating.value = false;
      state.floatingSizeFactor.value = 1.0;
      state.floatingPhase.value = FloatingPhase.idle;
      state.floatingAlignment.value = Alignment.center;

      Get.snackbar(
        '提示',
        '已确认：$term',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 1200),
      );

      maybeReplenishDeck();
    } else if (state.floatingPhase.value == FloatingPhase.flyingDown &&
        state.floatingAlignment.value == Alignment.center) {
      state.terms.value ??= <String>[];
      if (!(state.terms.value?.contains(term) ?? false)) {
        state.terms.value?.insert(0, term);
      }
      state.selectedTerm.value = null;
      state.floatingTerm.value = null;
      state.floatingAnimating.value = false;
      state.floatingCardWidth.value = null;
      state.floatingCardHeight.value = null;
      state.floatingAlignment.value = Alignment.center;
      state.floatingSizeFactor.value = 1.0;
      state.floatingPhase.value = FloatingPhase.idle;

      maybeReplenishDeck();
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
      debugPrint('[HomeController] JSON candidate: $jsonCandidate');
      try {
        final decoded = jsonDecode(jsonCandidate);
        if (decoded is Map<String, dynamic>) {
          final status = decoded['status'];
          final wordsRaw = decoded['words'];
          if (status == 'confused' && wordsRaw is List) {
            final termsResult = wordsRaw
                .whereType<String>()
                .map((word) => word.replaceAll(RegExp(r'^<|>$'), '').trim())
                .where((word) => word.isNotEmpty)
                .take(10)
                .toList(growable: false);
            if (termsResult.isNotEmpty) {
              return _ExtractionResult(terms: termsResult, isClear: false);
            }
          }
          if (status == 'clear') {
            return const _ExtractionResult(terms: <String>[], isClear: true);
          }
        }
      } catch (error, stackTrace) {
        debugPrint('[HomeController] JSON parse error: $error');
        debugPrint('[HomeController] Stack trace: $stackTrace');
      }
    }

    final parts = trimmed
        .split(RegExp(r'[\s,，；;。.!?\n\r]+'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      debugPrint('[HomeController] Fallback split produced 0 parts');
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
    debugPrint('[HomeController] Fallback terms: $unique');
    return _ExtractionResult(terms: unique, isClear: false);
  }

  String? _extractJsonBlock(String text) {
    if (text.startsWith('```')) {
      debugPrint('[HomeController] Detected code block response');
      final startBrace = text.indexOf('{');
      final endBrace = text.lastIndexOf('}');
      if (startBrace != -1 && endBrace > startBrace) {
        return text.substring(startBrace, endBrace + 1);
      }
    }

    if (text.startsWith('{') && text.endsWith('}')) {
      debugPrint('[HomeController] Reply appears to be pure JSON');
      return text;
    }

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) {
      debugPrint('[HomeController] Found JSON within text block');
      return text.substring(start, end + 1);
    }

    debugPrint('[HomeController] No JSON block detected');
    return null;
  }

  String getCategoryDisplayName() {
    switch (state.activeCategory.value) {
      case 'economics':
        return '经济学';
      default:
        return state.activeCategory.value;
    }
  }

  void maybeReplenishDeck() {
    // 当术语数量低于3个或正在补充或动画中时，不进行操作
    if ((state.terms.value?.length ?? 0) >= 3 ||
        state.isAppending.value ||
        state.floatingAnimating.value) {
      return;
    }
    fetchAdditionalTerms();
  }

  Future<void> fetchAdditionalTerms() async {
    if (state.isAppending.value) {
      return;
    }
    state.isAppending.value = true;
    try {
      final response = await agentService.fetchTerms(category: state.activeCategory.value);
      if (state.terms.value == null) {
        return;
      }
      final existing = <String>{...?state.terms.value};
      if (state.selectedTerm.value != null) {
        existing.add(state.selectedTerm.value!);
      }
      if (state.floatingTerm.value != null) {
        existing.add(state.floatingTerm.value!);
      }
      final newTerms = response.terms.where((term) => !existing.contains(term));
      if (newTerms.isNotEmpty) {
        state.terms.value?.addAll(newTerms);
        state.terms.refresh();
      } else {
        Get.snackbar(
          '提示',
          '暂无更多新的词汇可补充',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(milliseconds: 1600),
        );
      }
    } catch (error) {
      Get.snackbar(
        '错误',
        '补充词汇失败：$error',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 1800),
      );
    } finally {
      state.isAppending.value = false;
    }
  }
}

class _ExtractionResult {
  const _ExtractionResult({required this.terms, required this.isClear});

  final List<String> terms;
  final bool isClear;

  static _ExtractionResult empty() =>
      const _ExtractionResult(terms: <String>[], isClear: false);
}
