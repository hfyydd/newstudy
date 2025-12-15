import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_state.dart';
import 'package:newstudyapp/services/http_service.dart';

class FeynmanLearningController extends GetxController {
  // 使用 HttpService 单例
  final httpService = HttpService();
  late final FeynmanLearningState state;

  @override
  void onInit() {
    super.onInit();
    state = FeynmanLearningState();
    
    // 从路由参数获取主题信息
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      // 1) 如果携带自定义词表，直接使用，不再走后端 /topics/terms
      final termsRaw = arguments['terms'];
      if (termsRaw is List) {
        final terms = termsRaw
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false);
        if (terms.isNotEmpty) {
          state.topicName.value = arguments['topic'] as String? ?? '我的笔记';
          state.topicId.value = null;
          state.activeCategory.value = 'note';
          state.isCustomDeck.value = true;
          state.terms.value = List.of(terms);
          state.isLoading.value = false;
          state.errorMessage.value = null;
          return;
        }
      }

      state.topicName.value = arguments['topic'] as String?;
      state.topicId.value = arguments['topicId'] as String?;
      
      // 使用 topicId 作为 category 加载词汇
      final category = state.topicId.value ?? FeynmanLearningState.defaultCategory;
      state.activeCategory.value = category;
      loadTerms(category: category);
    } else {
      // 如果没有参数，使用默认 category
      loadTerms();
    }
  }

  @override
  void onClose() {
    state.dispose();
    super.onClose();
  }

  Future<void> loadTerms({String? category}) async {
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
    state.currentCardIndex.value = 0;

    try {
      final categoryToUse = category ?? state.activeCategory.value;
      final response = await httpService.fetchTerms(category: categoryToUse);
      state.terms.value = List.of(response.terms);
      state.activeCategory.value = response.category;
      state.isLoading.value = false;
    } catch (error) {
      state.errorMessage.value = '获取术语失败：$error';
      state.isLoading.value = false;
    }
  }

  /// 切换到上一张卡片
  void previousCard() {
    if (state.currentCardIndex.value > 0) {
      state.currentCardIndex.value--;
    }
  }

  /// 切换到下一张卡片
  void nextCard() {
    final totalCards = state.terms.value?.length ?? 0;
    if (state.currentCardIndex.value < totalCards - 1) {
      state.currentCardIndex.value++;
    }
  }

  /// 跳转到指定卡片
  void goToCard(int index) {
    final totalCards = state.terms.value?.length ?? 0;
    if (index >= 0 && index < totalCards) {
      state.currentCardIndex.value = index;
    }
  }

  Future<void> handleCardExplain(String term) async {
    // 设置当前解释的词汇
    state.currentExplainingTerm.value = term;
    state.learningPhase.value = LearningPhase.explaining;
    state.explanationHistory.add(term);
    
    // 切换到解释视图状态
    state.isExplanationViewVisible.value = true;
    state.inputMode.value = InputMode.voice;
    state.textInputController.clear();
  }

  void restoreCardView() {
    // 重置学习状态
    state.learningPhase.value = LearningPhase.selecting;
    state.currentExplainingTerm.value = null;
    state.confusedWords.clear();
    state.explanationHistory.clear();
    
    // 先更新状态
    state.isExplanationViewVisible.value = false;
    state.isExplanationViewVisible.refresh(); // 强制刷新
    
    try {
      state.inputMode.value = InputMode.voice;
      state.textInputController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    } catch (e) {
      debugPrint('Error checking/restoring view: $e');
    }
  }

  Future<void> handleTextSubmit(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSubmittingSuggestion.value) {
      return;
    }

    state.isSubmittingSuggestion.value = true;
    
    // 保存用户输入的解释内容，用于页面显示
    state.userExplanation.value = trimmed;
    
    // 保存到解释历史记录中（词汇 -> 解释内容）
    final currentTerm = state.currentExplainingTerm.value;
    if (currentTerm != null) {
      state.explanationContents[currentTerm] = trimmed;
    }

    try {
      debugPrint('[FeynmanLearningController] Submit text: "$trimmed"');
      final response = await httpService.runCuriousStudent(trimmed);
      debugPrint('[FeynmanLearningController] Raw reply: ${response.reply}');
      final extraction = _extractTermsFromReply(
        reply: response.reply,
        originalText: trimmed,
      );
      final extracted = extraction.terms;
      debugPrint('[FeynmanLearningController] Extracted terms: $extracted');

      if (extracted.isEmpty) {
        if (extraction.isClear) {
          // 🎉 学习成功！显示成功界面
          state.learningPhase.value = LearningPhase.success;
          state.confusedWords.clear();
          state.textInputController.clear();
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

      // 有不清楚的词汇，进入 reviewing 阶段
      state.confusedWords.value = List.of(extracted);
      state.learningPhase.value = LearningPhase.reviewing;
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
      debugPrint('[FeynmanLearningController] JSON candidate: $jsonCandidate');
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
        debugPrint('[FeynmanLearningController] JSON parse error: $error');
        debugPrint('[FeynmanLearningController] Stack trace: $stackTrace');
      }
    }

    final parts = trimmed
        .split(RegExp(r'[\s,，；;。.!?\n\r]+'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      debugPrint('[FeynmanLearningController] Fallback split produced 0 parts');
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
    debugPrint('[FeynmanLearningController] Fallback terms: $unique');
    return _ExtractionResult(terms: unique, isClear: false);
  }

  String? _extractJsonBlock(String text) {
    if (text.startsWith('```')) {
      debugPrint('[FeynmanLearningController] Detected code block response');
      final startBrace = text.indexOf('{');
      final endBrace = text.lastIndexOf('}');
      if (startBrace != -1 && endBrace > startBrace) {
        return text.substring(startBrace, endBrace + 1);
      }
    }

    if (text.startsWith('{') && text.endsWith('}')) {
      debugPrint('[FeynmanLearningController] Reply appears to be pure JSON');
      return text;
    }

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end > start) {
      debugPrint('[FeynmanLearningController] Found JSON within text block');
      return text.substring(start, end + 1);
    }

    debugPrint('[FeynmanLearningController] No JSON block detected');
    return null;
  }

  String getCategoryDisplayName() {
    // 如果有主题名称，优先使用主题名称
    if (state.topicName.value != null) {
      return state.topicName.value!;
    }
    
    // 否则根据 category 返回显示名称
    switch (state.activeCategory.value) {
      case 'economics':
        return '经济学';
      case 'finance':
        return '金融';
      case 'technology':
        return '科技';
      case 'medicine':
        return '医学';
      case 'law':
        return '法律';
      case 'psychology':
        return '心理学';
      case 'philosophy':
        return '哲学';
      case 'history':
        return '历史';
      default:
        return state.activeCategory.value;
    }
  }

  void maybeReplenishDeck() {
    if (state.isCustomDeck.value) {
      return;
    }
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
      final categoryToUse = state.topicId.value ?? state.activeCategory.value;
      final response = await httpService.fetchTerms(category: categoryToUse);
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
  
  // ========== 学习流程方法 ==========
  
  /// 选择一个不清楚的词汇继续解释
  void selectConfusedWord(String word) {
    // 清除上一轮的解释内容
    state.userExplanation.value = null;
    state.confusedWords.clear();
    
    // 设置新的解释词汇
    state.currentExplainingTerm.value = word;
    state.explanationHistory.add(word);
    state.learningPhase.value = LearningPhase.explaining;
    state.inputMode.value = InputMode.voice;
    state.textInputController.clear();
  }
  
  /// 获取词汇的辅助解释（可选功能）
  Future<void> getWordExplanation(String word) async {
    // 如果已经缓存了，直接返回
    if (state.wordExplanations.containsKey(word)) {
      return;
    }
    
    state.isLoadingExplanation.value = true;
    
    try {
      // 构造请求：包含词汇和上下文
      final requestText = '{"words": ["<$word>"], "original_context": "${state.currentExplainingTerm.value ?? word}"}';
      final response = await httpService.runSimpleExplainer(requestText);
      
      debugPrint('[FeynmanLearningController] Explanation reply: ${response.reply}');
      
      // 解析响应
      final explanation = _parseExplanation(response.reply, word);
      if (explanation != null) {
        state.wordExplanations[word] = explanation;
      }
    } catch (error) {
      Get.snackbar(
        '提示',
        '获取解释失败：$error',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 1500),
      );
    } finally {
      state.isLoadingExplanation.value = false;
    }
  }
  
  /// 解析辅助解释响应
  WordExplanation? _parseExplanation(String reply, String word) {
    try {
      final jsonBlock = _extractJsonBlock(reply);
      if (jsonBlock == null) return null;
      
      final decoded = jsonDecode(jsonBlock);
      if (decoded is Map<String, dynamic>) {
        final explanations = decoded['explanations'];
        if (explanations is List && explanations.isNotEmpty) {
          final first = explanations.first as Map<String, dynamic>;
          return WordExplanation(
            word: first['word']?.toString() ?? word,
            simpleExplanation: first['simple_explanation']?.toString() ?? '',
            analogy: first['analogy']?.toString() ?? '',
            keyPoint: first['key_point']?.toString() ?? '',
          );
        }
      }
    } catch (e) {
      debugPrint('[FeynmanLearningController] Parse explanation error: $e');
    }
    return null;
  }
  
  /// 完成学习，返回卡片选择界面
  void finishLearning() {
    // 先保存要移除的词汇（在重置状态之前）
    final originalTerm = state.explanationHistory.isNotEmpty 
        ? state.explanationHistory.first 
        : null;
    
    // 从术语列表中移除已成功学习的词汇
    if (originalTerm != null && state.terms.value != null) {
      state.terms.value!.remove(originalTerm);
      state.terms.refresh();
    }
    
    // 重置学习状态
    state.resetLearningState();
    state.isExplanationViewVisible.value = false;
    state.inputMode.value = InputMode.voice;
    state.textInputController.clear();
    
    // 如果列表为空，补充新词汇
    maybeReplenishDeck();
  }
  
  /// 中途退出学习
  void cancelLearning() {
    state.resetLearningState();
    state.isExplanationViewVisible.value = false;
    state.inputMode.value = InputMode.voice;
    state.textInputController.clear();
  }
}

class _ExtractionResult {
  const _ExtractionResult({required this.terms, required this.isClear});

  final List<String> terms;
  final bool isClear;

  static _ExtractionResult empty() =>
      const _ExtractionResult(terms: <String>[], isClear: false);
}

