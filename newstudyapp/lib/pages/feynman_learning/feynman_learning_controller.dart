import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_state.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/services/speech_recognizer_service.dart';

class FeynmanLearningController extends GetxController {
  // 使用 HttpService 单例
  final httpService = HttpService();
  late final FeynmanLearningState state;

  // 语音识别事件订阅
  StreamSubscription<SpeechRecognizerEvent>? _speechEventSubscription;

  @override
  void onInit() {
    super.onInit();
    state = FeynmanLearningState();
    _initializeSpeech();
    _setupSpeechEventListeners();

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
          // 重要：保存 noteId，即使有自定义词表也要保存，用于标记已掌握功能
          state.topicId.value = arguments['noteId'] as String?;
          state.activeCategory.value = 'note';
          state.isCustomDeck.value = true;
          state.terms.value = List.of(terms);
          state.isLoading.value = false;
          state.errorMessage.value = null;
          return;
        }
      }

      state.topicName.value = arguments['topic'] as String?;
      // 优先使用 noteId，如果没有则使用 topicId
      state.topicId.value =
          arguments['noteId'] as String? ?? arguments['topicId'] as String?;

      // 使用 topicId 作为 category 加载词汇
      final category =
          state.topicId.value ?? FeynmanLearningState.defaultCategory;
      state.activeCategory.value = category;
      loadTerms(category: category);
    } else {
      // 如果没有参数，使用默认 category
      loadTerms();
    }
  }

  @override
  void onClose() {
    _speechEventSubscription?.cancel();
    SpeechRecognizerService.shutdown();
    state.dispose();
    super.onClose();
  }

  /// 设置语音识别事件监听
  void _setupSpeechEventListeners() {
    _speechEventSubscription = SpeechRecognizerService.events.listen((event) {
      switch (event.type) {
        case SpeechEventType.onStart:
          state.isListening.value = true;
          debugPrint('[SpeechRecognizer] Started listening');
          break;
        case SpeechEventType.onResult:
          if (event.result != null && event.result!.isNotEmpty) {
            // 更新输入框内容
            final currentText = state.textInputController.text;
            if (event.isFinal) {
              // 最终结果：追加到现有文本
              final newText = currentText.isEmpty
                  ? event.result!
                  : '$currentText ${event.result!}';
              state.textInputController.text = newText;
              state.textInputController.selection = TextSelection.fromPosition(
                TextPosition(offset: newText.length),
              );
            } else {
              // 中间结果：可以实时显示（可选）
              debugPrint('[SpeechRecognizer] Partial result: ${event.result}');
            }
          }
          break;
        case SpeechEventType.onComplete:
          state.isListening.value = false;
          debugPrint('[SpeechRecognizer] Completed');
          break;
        case SpeechEventType.onError:
          state.isListening.value = false;
          state.speechError.value = event.errorMessage ?? '语音识别错误';
          Get.snackbar(
            '语音识别错误',
            event.errorMessage ?? '未知错误',
            snackPosition: SnackPosition.BOTTOM,
          );
          debugPrint('[SpeechRecognizer] Error: ${event.errorMessage}');
          break;
      }
    });
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

  /// 根据学习结果自动更新词条状态（学习成功）
  Future<void> _updateCardStatusOnSuccess() async {
    final noteId = state.topicId.value;
    final currentTerm = state.currentExplainingTerm.value;

    if (noteId == null || currentTerm == null) {
      debugPrint('[FeynmanLearningController] 无法自动更新状态：noteId或term为空');
      return;
    }

    try {
      // 学习成功，设置为已掌握
      await httpService.updateFlashCardStatus(noteId, currentTerm, 'mastered');
      debugPrint('[FeynmanLearningController] 学习成功，已自动标记为掌握: $currentTerm');

      // 添加到已掌握集合（用于UI显示）
      state.masteredTerms.add(currentTerm);
    } catch (e) {
      debugPrint('[FeynmanLearningController] 自动更新状态失败: $e');
      // 不显示错误提示，避免干扰用户体验
    }
  }

  /// 根据学习结果自动更新词条状态（学习失败）
  Future<void> _updateCardStatusOnFailure() async {
    final noteId = state.topicId.value;
    final currentTerm = state.currentExplainingTerm.value;

    if (noteId == null || currentTerm == null) {
      debugPrint('[FeynmanLearningController] 无法自动更新状态：noteId或term为空');
      return;
    }

    try {
      // 学习失败（有不清楚的词汇），设置为需要复习（困难词条）
      // 如果词条当前状态是notStarted，设置为needsReview
      // 如果词条当前状态是needsImprove，升级为needsReview（更困难）
      // 如果词条当前状态是mastered，降级为needsReview（复习时又困难了）
      // 如果词条当前状态是needsReview，保持needsReview
      await httpService.updateFlashCardStatus(
          noteId, currentTerm, 'needsReview');
      debugPrint('[FeynmanLearningController] 学习失败，已自动标记为需要复习: $currentTerm');
    } catch (e) {
      debugPrint('[FeynmanLearningController] 自动更新状态失败: $e');
      // 不显示错误提示，避免干扰用户体验
    }
  }

  /// 标记词条为已掌握
  Future<void> markAsMastered(String term) async {
    final noteId = state.topicId.value;
    if (noteId == null) {
      // 如果没有 noteId，说明不是从笔记进入的，只做本地处理
      // 添加到本地已掌握集合
      state.masteredTerms.add(term);
      Get.snackbar(
        '提示',
        '已标记为掌握（仅本地，未保存到数据库）',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      nextCard();
      return;
    }

    try {
      // 调用后端API更新状态
      await httpService.updateFlashCardStatus(noteId, term, 'mastered');

      // 添加到已掌握集合（用于UI显示）
      state.masteredTerms.add(term);

      Get.snackbar(
        '成功',
        '已标记为掌握',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // 不删除词条，保留在列表中但标记为已掌握
      // 这样用户翻回来时还能看到，但会显示为已掌握状态

      // 继续下一张卡片
      nextCard();
    } catch (e) {
      debugPrint('标记已掌握失败: $e');
      Get.snackbar(
        '错误',
        '标记失败：$e',
        snackPosition: SnackPosition.BOTTOM,
      );
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

  /// 保存困惑词到闪词卡片
  Future<void> _saveConfusedTermsToFlashCards(List<String> terms) async {
    final noteId = state.topicId.value;
    if (noteId == null || noteId.isEmpty) {
      debugPrint('[FeynmanLearningController] 无法保存困惑词: noteId为空');
      return;
    }

    try {
      debugPrint('[FeynmanLearningController] 保存困惑词到闪卡: $terms');
      await httpService.addConfusedTerms(
        noteId,
        terms,
        status: 'needsReview',
      );
      debugPrint('[FeynmanLearningController] 困惑词保存成功');
    } catch (e) {
      debugPrint('[FeynmanLearningController] 保存困惑词失败: $e');
      // 失败不阻断流程，只打印日志
    }
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

          // 自动更新词条状态为已掌握
          await _updateCardStatusOnSuccess();
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

      // 自动更新词条状态为需要复习
      await _updateCardStatusOnFailure();

      // 保存困惑词到闪词卡片
      await _saveConfusedTermsToFlashCards(extracted);
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
      final requestText =
          '{"words": ["<$word>"], "original_context": "${state.currentExplainingTerm.value ?? word}"}';
      final response = await httpService.runSimpleExplainer(requestText);

      debugPrint(
          '[FeynmanLearningController] Explanation reply: ${response.reply}');

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
    // 注意：不再从列表中移除词条，因为状态已经更新到数据库
    // 词条会保留在列表中，但会显示为已掌握状态

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

  // ========== 语音识别相关方法 ==========

  /// 初始化语音识别（使用 HarmonyOS 原生 API）
  Future<void> _initializeSpeech() async {
    try {
      // 先尝试检查是否可用
      final isAvailable = await SpeechRecognizerService.isAvailable();
      if (isAvailable) {
        state.speechAvailable.value = true;
        debugPrint('[SpeechRecognizer] Already available');
        return;
      }

      // 如果不可用，尝试初始化
      final available = await SpeechRecognizerService.initialize();
      state.speechAvailable.value = available;
      if (!available) {
        // 初始化失败，但不阻止使用（可能是权限问题，稍后可以重试）
        debugPrint(
            '[SpeechRecognizer] Initialize returned false, but will allow retry');
        // 仍然设置为 true，允许用户尝试使用
        state.speechAvailable.value = true;
      } else {
        debugPrint('[SpeechRecognizer] Initialized successfully');
      }
    } catch (e) {
      debugPrint('Speech initialization error: $e');
      // 即使初始化失败，也允许用户尝试（可能是权限问题）
      // 实际使用时会再次尝试初始化
      state.speechAvailable.value = true;
      state.speechError.value = null; // 清除错误，允许重试
    }
  }

  /// 开始语音识别（使用 HarmonyOS 原生 API）
  Future<void> startListening() async {
    // 确保已初始化
    try {
      final isAvailable = await SpeechRecognizerService.isAvailable();
      if (!isAvailable) {
        // 如果不可用，尝试初始化
        final initialized = await SpeechRecognizerService.initialize();
        if (!initialized) {
          Get.snackbar(
            '语音识别初始化失败',
            '请检查权限设置或稍后重试',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('Check/Initialize error: $e');
      // 即使检查失败，也尝试启动（可能是权限问题）
    }

    try {
      state.speechError.value = null;
      final success = await SpeechRecognizerService.startListening();
      if (!success) {
        Get.snackbar(
          '错误',
          '启动语音识别失败，请检查权限设置',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Start listening error: $e');
      state.isListening.value = false;
      Get.snackbar(
        '错误',
        '启动语音识别失败：$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// 停止语音识别
  Future<void> stopListening() async {
    try {
      await SpeechRecognizerService.stopListening();
      state.isListening.value = false;
    } catch (e) {
      debugPrint('Stop listening error: $e');
      state.isListening.value = false;
    }
  }

  /// 取消语音识别
  Future<void> cancelListening() async {
    try {
      await SpeechRecognizerService.cancel();
      state.isListening.value = false;
    } catch (e) {
      debugPrint('Cancel listening error: $e');
      state.isListening.value = false;
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
