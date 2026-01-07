import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:newstudyapp/pages/feynman_learning/feynman_learning_state.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/models/note_models.dart';
import 'package:newstudyapp/pages/note_detail/note_detail_controller.dart';
import 'package:newstudyapp/pages/home/home_controller.dart';
import 'package:newstudyapp/config/app_theme.dart';

class FeynmanLearningController extends GetxController {
  // 使用 HttpService 单例
  final httpService = HttpService();
  late final FeynmanLearningState state;
  
  // 语音转文字
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechAvailable = false;

  @override
  void onInit() {
    super.onInit();
    state = FeynmanLearningState();
    
    // 监听输入文本变化
    state.textInputController.addListener(() {
      state.inputText.value = state.textInputController.text;
    });
    
    // 初始化语音识别
    _initializeSpeech();
    
    // 从路由参数获取主题信息
    final arguments = Get.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      // 保存笔记ID和默认角色
      state.currentNoteId.value = arguments['noteId'] as int?;
      state.noteDefaultRole.value = arguments['defaultRole'] as String?;
      
      // 1) 如果携带闪词卡片列表（带ID），使用完整的卡片信息
      final flashCardsRaw = arguments['flashCards'];
      if (flashCardsRaw is List) {
        final cards = flashCardsRaw.whereType<Map<String, dynamic>>().toList();
        if (cards.isNotEmpty) {
          state.topicName.value = arguments['topic'] as String? ?? '我的笔记';
          state.topicId.value = null;
          state.activeCategory.value = 'note';
          state.isCustomDeck.value = true;
          
          // 保存分页信息（用于后续加载更多）
          state.pageType.value = arguments['pageType'] as String?;
          state.statusFilter.value = arguments['statusFilter'] as String?;
          state.currentSkip.value = arguments['currentSkip'] as int? ?? cards.length;
          state.totalCount.value = arguments['total'] as int? ?? cards.length;
          
          // 从卡片信息中提取词条列表（过滤掉无效数据）
          state.terms.value = cards
              .where((c) => c['term'] != null && c['term'].toString().isNotEmpty)
              .map((c) => c['term'].toString())
              .toList();
          // 保存完整的卡片信息供后续使用（过滤掉无效数据）
          _flashCardsData = cards
              .where((c) => c['term'] != null && c['id'] != null)
              .toList();
          
          // 打印每张卡片的状态，用于调试
          for (final card in _flashCardsData) {
            debugPrint('[FeynmanLearningController] 卡片: ${card['term']}, 状态: ${card['status']}, 复习次数: ${card['review_count']}');
          }
          
          debugPrint('[FeynmanLearningController] 加载了 ${_flashCardsData.length} 张卡片，总数: ${state.totalCount.value}');
          state.isLoading.value = false;
          state.errorMessage.value = null;
          // 加载角色列表
          _loadRoles();
          return;
        }
      }
      
      // 2) 如果携带自定义词表，直接使用，不再走后端 /topics/terms
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
  
  /// 闪词卡片完整数据（包含ID）
  List<Map<String, dynamic>> _flashCardsData = [];

  @override
  void onClose() {
    // 停止语音识别
    try {
      if (state.isListening.value) {
        _speech.stop();
      }
    } catch (e) {
      debugPrint('[FeynmanLearningController] 停止语音识别失败: $e');
    }
    
    // 页面关闭时不刷新数据，因为评估完成后已经刷新过了
    // 如果在这里刷新，evaluationResult 可能已经被清空
    
    state.dispose();
    super.onClose();
  }
  
  /// 初始化语音识别
  Future<void> _initializeSpeech() async {
    try {
      _isSpeechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            state.isListening.value = false;
          }
        },
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          state.isListening.value = false;
          Get.snackbar(
            '语音识别错误',
            error.errorMsg,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        },
      );
      debugPrint('Speech recognition available: $_isSpeechAvailable');
    } catch (e) {
      debugPrint('Failed to initialize speech recognition: $e');
      _isSpeechAvailable = false;
    }
  }
  
  /// 切换语音输入
  Future<void> toggleSpeechInput() async {
    if (state.isListening.value) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }
  
  /// 开始语音识别
  Future<void> _startListening() async {
    if (!_isSpeechAvailable) {
      Get.snackbar(
        '提示',
        '语音识别不可用，请检查设备权限',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    
    // 请求麦克风权限
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      Get.snackbar(
        '权限错误',
        '需要麦克风权限才能使用语音输入',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFF6B6B),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }
    
    try {
      state.isListening.value = true;
      state.speechText.value = '';
      
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            // 最终结果，追加到输入框
            final recognizedText = result.recognizedWords;
            if (recognizedText.isNotEmpty) {
              final currentText = state.textInputController.text;
              final newText = currentText.isEmpty
                  ? recognizedText
                  : '$currentText $recognizedText';
              state.textInputController.text = newText;
              state.textInputController.selection = TextSelection.fromPosition(
                TextPosition(offset: newText.length),
              );
              state.speechText.value = '';
            }
            state.isListening.value = false;
          } else {
            // 临时结果，显示在状态栏
            state.speechText.value = result.recognizedWords;
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: 'zh_CN',
        cancelOnError: true,
        partialResults: true,
      );
    } catch (e) {
      debugPrint('Failed to start listening: $e');
      state.isListening.value = false;
      Get.snackbar(
        '错误',
        '启动语音识别失败：$e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
  
  /// 停止语音识别
  Future<void> _stopListening() async {
    try {
      await _speech.stop();
      state.isListening.value = false;
      state.speechText.value = '';
    } catch (e) {
      debugPrint('Failed to stop listening: $e');
    }
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
      
      // 如果滑动到接近末尾（剩余3张卡片），且还有更多数据，自动加载更多
      if (index >= totalCards - 3 && 
          state.currentSkip.value < state.totalCount.value &&
          !state.isLoadingMore.value &&
          state.pageType.value != null) {
        _loadMoreCards();
      }
    }
  }
  
  /// 加载更多词条（分页加载）
  Future<void> _loadMoreCards() async {
    if (state.isLoadingMore.value || 
        state.currentSkip.value >= state.totalCount.value ||
        state.pageType.value == null) {
      return;
    }
    
    try {
      state.isLoadingMore.value = true;
      final pageType = state.pageType.value!;
      final statusFilter = state.statusFilter.value;
      final skip = state.currentSkip.value;
      const limit = 30; // 每次加载30条
      
      FlashCardListResponse response;
      
      // 根据页面类型加载数据
      switch (pageType) {
        case 'todayReview':
          response = await httpService.getTodayReviewCards(
            skip: skip,
            limit: limit,
          );
          break;
        case 'weakCards':
          response = await httpService.getWeakCards(
            skip: skip,
            limit: limit,
            status: statusFilter,
          );
          break;
        case 'masteredCards':
          response = await httpService.getMasteredCards(
            skip: skip,
            limit: limit,
          );
          break;
        case 'allCards':
          response = await httpService.getAllCards(
            skip: skip,
            limit: limit,
          );
          break;
        default:
          return;
      }
      
      if (response.cards.isEmpty) {
        // 没有更多数据了
        return;
      }
      
      // 转换为费曼学习页面需要的格式
      final newFlashCards = response.cards
          .map((card) => {
                'id': card.id,
                'term': card.term,
                'status': card.status,
                'review_count': card.reviewCount,
                'last_reviewed_at': null,
                'mastered_at': null,
              })
          .toList();
      
      // 添加到现有数据中
      final newTerms = newFlashCards
          .where((c) => c['term'] != null && c['term'].toString().isNotEmpty)
          .map((c) => c['term'].toString())
          .toList();
      
      // 更新词条列表和卡片数据
      if (state.terms.value != null) {
        state.terms.value!.addAll(newTerms);
        state.terms.refresh();
      }
      
      _flashCardsData.addAll(newFlashCards
          .where((c) => c['term'] != null && c['id'] != null)
          .toList());
      
      // 更新分页信息
      state.currentSkip.value = skip + response.cards.length;
      
      debugPrint('[FeynmanLearningController] 加载了更多 ${newFlashCards.length} 张卡片，当前总数: ${state.terms.value?.length ?? 0}');
    } catch (e) {
      debugPrint('[FeynmanLearningController] 加载更多失败: $e');
      // 不显示错误提示，避免打扰用户学习
    } finally {
      state.isLoadingMore.value = false;
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
    // 如果已经有评估结果，说明有学习记录，需要刷新
    final hasLearningRecord = state.evaluationResult.value != null;
    
    state.resetLearningState();
    state.isExplanationViewVisible.value = false;
    state.inputMode.value = InputMode.voice;
    state.textInputController.clear();
    
    // 如果有学习记录，刷新数据
    if (hasLearningRecord) {
      _refreshNoteData();
    }
  }
  
  /// 刷新笔记详情页和首页的数据
  void _refreshNoteData() {
    final noteId = state.currentNoteId.value;
    if (noteId == null) {
      debugPrint('[FeynmanLearningController] noteId 为空，跳过刷新');
      return;
    }
    
    debugPrint('[FeynmanLearningController] 刷新笔记数据，noteId: $noteId');
    
    // 刷新笔记详情页的数据
    try {
      if (Get.isRegistered<NoteDetailController>()) {
        final noteDetailController = Get.find<NoteDetailController>();
        noteDetailController.refreshNoteData(noteId);
        debugPrint('[FeynmanLearningController] ✅ 已刷新笔记详情页');
      } else {
        debugPrint('[FeynmanLearningController] ⚠️ NoteDetailController 未注册');
      }
    } catch (e) {
      debugPrint('[FeynmanLearningController] ❌ 无法刷新笔记详情页: $e');
    }
    
    // 刷新首页的数据
    try {
      if (Get.isRegistered<HomeController>()) {
        final homeController = Get.find<HomeController>();
        homeController.loadNotes();
        debugPrint('[FeynmanLearningController] ✅ 已刷新首页');
      } else {
        debugPrint('[FeynmanLearningController] ⚠️ HomeController 未注册');
      }
    } catch (e) {
      debugPrint('[FeynmanLearningController] ❌ 无法刷新首页: $e');
    }
  }
  
  // ========== 新增：角色选择和评估相关方法 ==========
  
  /// 加载学习角色列表
  Future<void> _loadRoles({bool force = false}) async {
    if (!force && state.roles.isNotEmpty) return;
    
    state.isLoadingRoles.value = true;
    try {
      final response = await httpService.getLearningRoles();
      state.roles.value = response.roles;
      debugPrint('[FeynmanLearningController] 加载角色列表成功: ${state.roles.length}个');
      for (final role in state.roles) {
        debugPrint('  - ${role.name} (${role.id})');
      }
    } catch (e) {
      debugPrint('[FeynmanLearningController] 加载角色列表失败: $e');
      // 使用默认角色
      state.roles.value = [
        const LearningRole(id: 'child_5', name: '5岁孩子', description: '用最简单的话解释，像讲故事一样'),
        const LearningRole(id: 'elementary', name: '小学生', description: '用简单易懂的语言，结合生活例子'),
        const LearningRole(id: 'middle_school', name: '中学生', description: '用基础概念解释，可以适当使用专业词汇'),
        const LearningRole(id: 'college', name: '大学生', description: '用专业但易懂的方式解释，可以涉及相关概念'),
        const LearningRole(id: 'master', name: '研究生', description: '用精确的专业术语和理论框架解释'),
      ];
      debugPrint('[FeynmanLearningController] 使用默认角色列表: ${state.roles.length}个');
    } finally {
      state.isLoadingRoles.value = false;
    }
  }
  
  /// 获取当前卡片信息
  Map<String, dynamic>? getCurrentCardData() {
    final index = state.currentCardIndex.value;
    if (index >= 0 && index < _flashCardsData.length) {
      return _flashCardsData[index];
    }
    return null;
  }
  
  /// 根据词条获取卡片数据
  Map<String, dynamic>? getCardDataByTerm(String term) {
    try {
      final cardData = _flashCardsData.firstWhere(
        (c) => c['term'] != null && c['term'].toString() == term,
        orElse: () => <String, dynamic>{},
      );
      return cardData.isEmpty ? null : cardData;
    } catch (e) {
      return null;
    }
  }
  
  /// 开始学习当前卡片（根据卡片状态决定流程）
  Future<void> startLearningCard(String term) async {
    // 检查数据是否已加载
    if (_flashCardsData.isEmpty) {
      Get.snackbar('提示', '闪词卡片数据未加载，请稍后再试', snackPosition: SnackPosition.BOTTOM);
      debugPrint('[FeynmanLearningController] _flashCardsData 为空');
      return;
    }
    
    if (term.isEmpty) {
      Get.snackbar('提示', '词条信息无效', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    // 查找对应的卡片数据
    Map<String, dynamic> cardData;
    try {
      cardData = _flashCardsData.firstWhere(
        (c) => c['term'] != null && c['term'].toString() == term,
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      debugPrint('[FeynmanLearningController] 查找卡片数据失败: $e');
      Get.snackbar('提示', '查找卡片信息失败', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    if (cardData.isEmpty) {
      Get.snackbar('提示', '未找到卡片信息', snackPosition: SnackPosition.BOTTOM);
      debugPrint('[FeynmanLearningController] 未找到词条: $term');
      return;
    }
    
    // 检查必要的字段
    if (cardData['id'] == null) {
      Get.snackbar('提示', '卡片ID缺失', snackPosition: SnackPosition.BOTTOM);
      debugPrint('[FeynmanLearningController] 卡片ID缺失: $cardData');
      return;
    }
    
    state.currentCard.value = cardData;
    state.currentExplainingTerm.value = term;
    state.userExplanation.value = null;
    state.evaluationResult.value = null;
    
    // 检查卡片状态
    final statusRaw = cardData['status'] as String? ?? 'NOT_STARTED';
    final status = statusRaw.toUpperCase();
    final reviewCount = cardData['review_count'] as int? ?? 0;
    
    debugPrint('[FeynmanLearningController] 卡片状态: $status, 复习次数: $reviewCount');
    
    // 如果已经学习过，加载学习历史
    if (reviewCount > 0) {
      await _loadCardLearningHistory(cardData['id'] as int);
      debugPrint('[FeynmanLearningController] 学习历史加载完成，记录数: ${state.cardLearningHistory.length}');
    }
    
    state.isExplanationViewVisible.value = true;
    
    // 根据状态决定流程
    // 注意：status 已经是大写，直接使用
    debugPrint('[FeynmanLearningController] 判断流程 - 状态: $status, 复习次数: $reviewCount, 历史记录数: ${state.cardLearningHistory.length}');
    debugPrint('[FeynmanLearningController] 卡片数据: ${cardData.toString()}');
    
    // 如果已经学习过（有学习历史），直接显示最后一次的学习结果
    if (reviewCount > 0 && state.cardLearningHistory.isNotEmpty) {
      // 显示最后一次的学习记录
      final lastRecord = state.cardLearningHistory.first;
      debugPrint('[FeynmanLearningController] ✅ 已学习的词条，显示学习历史。分数: ${lastRecord.score}, 状态: ${lastRecord.status}');
      debugPrint('[FeynmanLearningController] 学习记录中的角色ID: ${lastRecord.selectedRole}');
      
      // 先确保角色列表已加载（无论是否有角色都需要加载，因为UI可能需要）
      // 如果角色列表为空或正在加载，等待加载完成
      if (state.roles.isEmpty) {
        debugPrint('[FeynmanLearningController] 角色列表为空，开始加载...');
        await _loadRoles(force: true);
        debugPrint('[FeynmanLearningController] 角色列表加载完成，数量: ${state.roles.length}');
      }
      
      // 设置选择的角色（从学习记录中获取）
      // 兼容两种情况：1. 存储的是角色ID（如 "child_5"） 2. 存储的是角色名称（如 "5岁孩子"）
      if (lastRecord.selectedRole.isNotEmpty) {
        final roleValue = lastRecord.selectedRole;
        debugPrint('[FeynmanLearningController] 查找角色: $roleValue, 当前角色列表数量: ${state.roles.length}');
        debugPrint('[FeynmanLearningController] 当前角色列表: ${state.roles.map((r) => '${r.id}:${r.name}').join(', ')}');
        
        // 先尝试按ID查找
        var role = state.roles.firstWhereOrNull((r) => r.id == roleValue);
        
        // 如果按ID找不到，尝试按名称查找（兼容旧数据）
        if (role == null) {
          role = state.roles.firstWhereOrNull((r) => r.name == roleValue);
          if (role != null) {
            debugPrint('[FeynmanLearningController] 通过名称找到角色: ${role.name} (${role.id})');
          }
        }
        
        if (role != null) {
          state.selectedRole.value = role;
          debugPrint('[FeynmanLearningController] ✅ 设置角色成功: ${role.name} (${role.id})');
        } else {
          debugPrint('[FeynmanLearningController] ❌ 未找到角色: $roleValue');
          debugPrint('[FeynmanLearningController] 可用角色列表: ${state.roles.map((r) => '${r.id}:${r.name}').join(', ')}');
        }
      } else {
        debugPrint('[FeynmanLearningController] ⚠️ 学习记录中没有角色信息');
      }
      
      // 显示最后一次的学习结果
      state.evaluationResult.value = EvaluateResponse(
        score: lastRecord.score,
        status: lastRecord.status.toLowerCase(),
        feedback: _parseFeedbackFromJson(lastRecord.aiFeedback),
        highlights: [],
        suggestions: [],
        learningRecordId: lastRecord.id,
      );
      state.userExplanation.value = lastRecord.userExplanation;
      state.learningPhase.value = LearningPhase.result;
      // 已学习的词条直接显示结果
      return;
    }
    
    // 未学习过的词条：正常学习流程
    debugPrint('[FeynmanLearningController] 🆕 未学习的词条，进入正常学习流程');
    state.selectedRole.value = null;
    state.learningPhase.value = LearningPhase.selectingRole;
    
    // 加载角色列表
    _loadRoles(force: true);
  }
  
  /// 加载卡片的学习历史
  Future<void> _loadCardLearningHistory(int cardId) async {
    try {
      final cardDetail = await httpService.getCardDetail(cardId);
      // 转换为可增长的列表，避免固定长度列表的问题
      state.cardLearningHistory.value = List<LearningRecord>.from(cardDetail.learningHistory);
      debugPrint('[FeynmanLearningController] 加载学习历史成功: ${state.cardLearningHistory.length}条记录');
    } catch (e) {
      debugPrint('[FeynmanLearningController] 加载学习历史失败: $e');
      // 使用赋值空列表而不是 clear()，避免固定长度列表的问题
      state.cardLearningHistory.value = <LearningRecord>[];
    }
  }
  
  /// 从 JSON 字符串中解析反馈文本
  String _parseFeedbackFromJson(String aiFeedbackJson) {
    try {
      final feedbackData = jsonDecode(aiFeedbackJson);
      if (feedbackData is Map<String, dynamic>) {
        return feedbackData['feedback'] as String? ?? '感谢你的解释！';
      }
    } catch (e) {
      debugPrint('[FeynmanLearningController] 解析反馈失败: $e');
    }
    return '感谢你的解释！';
  }
  
  /// 重新学习当前卡片（清除历史，重新开始）
  void restartLearning() {
    state.userExplanation.value = null;
    state.evaluationResult.value = null;
    state.selectedRole.value = null;
    state.learningPhase.value = LearningPhase.selectingRole;
    state.textInputController.clear();
    _loadRoles(force: true);
  }
  
  /// 选择学习角色
  void selectRole(LearningRole role) {
    state.selectedRole.value = role;
    // 直接进入解释阶段，不保存角色选择
    state.learningPhase.value = LearningPhase.explaining;
    state.textInputController.clear();
  }
  
  /// 提交解释并获取AI评估
  Future<void> submitExplanation(String explanation) async {
    if (explanation.trim().isEmpty) {
      Get.snackbar('提示', '请输入你的解释', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    final cardData = state.currentCard.value;
    final selectedRole = state.selectedRole.value;
    final noteId = state.currentNoteId.value;
    
    if (cardData == null || selectedRole == null || noteId == null) {
      Get.snackbar('错误', '缺少必要信息', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    final cardId = cardData['id'] as int?;
    if (cardId == null) {
      Get.snackbar('错误', '卡片ID不存在', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    state.userExplanation.value = explanation.trim();
    state.isEvaluating.value = true;
    state.learningPhase.value = LearningPhase.evaluating;
    
    try {
      debugPrint('[FeynmanLearningController] 提交评估: cardId=$cardId, noteId=$noteId, role=${selectedRole.id}');
      
      final result = await httpService.evaluateExplanation(
        cardId: cardId,
        noteId: noteId,
        selectedRole: selectedRole.id,
        userExplanation: explanation.trim(),
      );
      
      state.evaluationResult.value = result;
      state.learningPhase.value = LearningPhase.result;
      
      // 更新本地卡片状态
      _updateLocalCardStatus(cardId, result.status.toUpperCase());
      
      debugPrint('[FeynmanLearningController] 评估完成: score=${result.score}, status=${result.status}');
      
      // 评估完成后立即刷新笔记详情页和首页的数据
      _refreshNoteData();
      
    } catch (e) {
      debugPrint('[FeynmanLearningController] 评估失败: $e');
      Get.snackbar('错误', '评估失败：$e', snackPosition: SnackPosition.BOTTOM);
      // 回到解释输入阶段
      state.learningPhase.value = LearningPhase.explaining;
    } finally {
      state.isEvaluating.value = false;
    }
  }
  
  /// 更新本地卡片状态
  void _updateLocalCardStatus(int cardId, String newStatus) {
    final index = _flashCardsData.indexWhere((c) => c['id'] == cardId);
    if (index != -1) {
      _flashCardsData[index]['status'] = newStatus;
      _flashCardsData[index]['review_count'] = 
          (_flashCardsData[index]['review_count'] as int? ?? 0) + 1;
    }
  }
  
  /// 继续学习下一张卡片
  void continueToNextCard() {
    // 注意：不在这里刷新，因为评估完成后已经刷新过了
    // 如果在这里刷新，evaluationResult 已经被 resetLearningState() 清空
    state.resetLearningState();
    state.isExplanationViewVisible.value = false;
    
    // 移动到下一张卡片
    final totalCards = state.terms.value?.length ?? 0;
    if (state.currentCardIndex.value < totalCards - 1) {
      state.currentCardIndex.value++;
    }
  }
  
  /// 重新学习当前卡片
  void retryCurrentCard() {
    state.selectedRole.value = null;
    state.userExplanation.value = null;
    state.evaluationResult.value = null;
    state.learningPhase.value = LearningPhase.selectingRole;
    state.textInputController.clear();
  }
  
  /// 直接标记为已掌握
  Future<void> markAsMastered() async {
    final cardData = state.currentCard.value;
    if (cardData == null) return;
    
    final cardId = cardData['id'] as int?;
    if (cardId == null) return;
    
    try {
      await httpService.updateCardStatus(cardId: cardId, status: 'MASTERED');
      _updateLocalCardStatus(cardId, 'MASTERED');
      
      Get.snackbar('成功', '已标记为掌握', snackPosition: SnackPosition.BOTTOM);
      continueToNextCard();
    } catch (e) {
      Get.snackbar('错误', '标记失败：$e', snackPosition: SnackPosition.BOTTOM);
    }
  }
  
  /// 获取状态的中文显示名称
  String getStatusDisplayName(String status) {
    switch (status.toUpperCase()) {
      case 'MASTERED':
        return '已掌握';
      case 'NEEDS_REVIEW':
        return '需巩固';
      case 'NEEDS_IMPROVE':
        return '需改进';
      case 'NOT_MASTERED':
        return '未掌握';
      case 'NOT_STARTED':
        return '未开始';
      default:
        return status;
    }
  }
  
  /// 获取状态对应的颜色（使用全局配置）
  Color getStatusColor(String status) {
    return AppTheme.getStatusColor(status);
  }
}

class _ExtractionResult {
  const _ExtractionResult({required this.terms, required this.isClear});

  final List<String> terms;
  final bool isClear;

  static _ExtractionResult empty() =>
      const _ExtractionResult(terms: <String>[], isClear: false);
}

