import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/models/note_models.dart';

enum FloatingPhase { idle, flyingUp, flyingDown }
enum InputMode { voice, text }

/// 学习阶段枚举
enum LearningPhase {
  /// 选择卡片阶段
  selecting,
  /// 选择角色阶段
  selectingRole,
  /// 解释中（输入解释）
  explaining,
  /// 等待AI评估
  evaluating,
  /// 查看评估结果
  result,
  /// 查看不清楚的词汇列表
  reviewing,
  /// 学习成功
  success,
}

/// 词汇解释结果
class WordExplanation {
  final String word;
  final String simpleExplanation;
  final String analogy;
  final String keyPoint;

  const WordExplanation({
    required this.word,
    required this.simpleExplanation,
    required this.analogy,
    required this.keyPoint,
  });
}

class FeynmanLearningState {
  // 服务相关
  static const String defaultCategory = 'economics';
  static const Alignment floatingTargetAlignment = Alignment(-0.9, -0.9);
  static const double floatingTargetSizeFactor = 0.55;

  // 主题信息
  final topicName = Rxn<String>();
  final topicId = Rxn<String>();
  
  /// 是否使用自定义词表（例如：笔记抽取的词表）
  /// - true：不自动从 /topics/terms 补充牌库，避免"跑偏"
  final isCustomDeck = false.obs;
  
  // 分页加载相关（用于从学习中心跳转时的分页加载）
  final RxnString pageType = RxnString(); // 页面类型：todayReview, weakCards, masteredCards, allCards
  final RxnString statusFilter = RxnString(); // 状态筛选：NEEDS_REVIEW, NEEDS_IMPROVE, NOT_MASTERED
  final currentSkip = 0.obs; // 当前已加载的数量
  final totalCount = 0.obs; // 总数
  final isLoadingMore = false.obs; // 是否正在加载更多

  // 加载状态
  final isLoading = true.obs;
  final errorMessage = Rxn<String>();

  // 术语列表管理
  final terms = Rxn<List<String>>();
  final selectedTerm = Rxn<String>();
  final activeCategory = 'economics'.obs;
  
  // 卡片浏览状态
  final currentCardIndex = 0.obs;

  // 浮动卡片动画状态
  final floatingTerm = Rxn<String>();
  final floatingCardWidth = Rxn<double>();
  final floatingCardHeight = Rxn<double>();
  final floatingAlignment = Alignment.center.obs;
  final floatingSizeFactor = 1.0.obs;
  final floatingAnimating = false.obs;
  final floatingPhase = FloatingPhase.idle.obs;

  // 输入相关状态
  final isExplanationViewVisible = false.obs;
  final inputMode = InputMode.voice.obs;
  final isExplaining = false.obs;
  final isSubmittingSuggestion = false.obs;
  final textInputController = TextEditingController();
  final inputText = ''.obs; // 用于跟踪输入文本内容
  final isAppending = false.obs;

  // ========== 学习流程状态 ==========
  /// 当前学习阶段
  final learningPhase = LearningPhase.selecting.obs;
  
  /// 当前正在解释的词汇（根词汇或衍生词汇）
  final currentExplainingTerm = Rxn<String>();
  
  /// Agent 返回的不清楚词汇列表
  final confusedWords = <String>[].obs;
  
  /// 当前显示的不清楚词汇索引
  final currentConfusedIndex = 0.obs;
  
  /// 解释历史：记录用户解释过的词汇链
  final explanationHistory = <String>[].obs;
  
  /// 解释内容记录：词汇 -> 用户的解释内容
  final explanationContents = <String, String>{}.obs;
  
  /// 词汇解释缓存（辅助解释功能）
  final wordExplanations = <String, WordExplanation>{}.obs;
  
  /// 是否正在加载辅助解释
  final isLoadingExplanation = false.obs;
  
  /// 用户当前输入的解释内容
  final userExplanation = Rxn<String>();

  // ========== 新增：角色选择和评估相关状态 ==========
  
  // ========== 语音输入相关状态 ==========
  /// 是否正在语音识别
  final isListening = false.obs;
  
  /// 语音识别的文本结果
  final speechText = ''.obs;
  
  /// 可用的学习角色列表
  final roles = <LearningRole>[].obs;
  
  /// 是否正在加载角色列表
  final isLoadingRoles = false.obs;
  
  /// 当前选中的角色
  final selectedRole = Rxn<LearningRole>();
  
  /// 当前学习的卡片信息
  final currentCard = Rxn<Map<String, dynamic>>();
  
  /// 当前笔记ID
  final currentNoteId = Rxn<int>();
  
  /// 笔记的默认角色（从笔记详情获取）
  final noteDefaultRole = Rxn<String>();
  
  /// 是否正在提交评估
  final isEvaluating = false.obs;
  
  /// 评估结果
  final evaluationResult = Rxn<EvaluateResponse>();
  
  /// 当前卡片的学习历史
  final cardLearningHistory = <LearningRecord>[].obs;

  void dispose() {
    textInputController.dispose();
  }
  
  /// 重置学习状态
  void resetLearningState() {
    learningPhase.value = LearningPhase.selecting;
    currentExplainingTerm.value = null;
    confusedWords.clear();
    currentConfusedIndex.value = 0;
    explanationHistory.clear();
    explanationContents.clear();
    wordExplanations.clear();
    isLoadingExplanation.value = false;
    userExplanation.value = null;
    selectedRole.value = null;
    currentCard.value = null;
    evaluationResult.value = null;
    isEvaluating.value = false;
    // 使用赋值空列表而不是 clear()，避免固定长度列表的问题
    cardLearningHistory.value = <LearningRecord>[];
  }
}

