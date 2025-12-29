import 'package:get/get.dart';

/// 闪词卡片状态枚举
enum CardStatus {
  notStarted,   // 未学习
  needsReview,  // 待复习（良好）
  needsImprove, // 需改进
  notMastered,  // 未掌握
  mastered,     // 已掌握
}

/// 笔记模型
class NoteModel {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int termCount;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.termCount = 0,
  });

  /// 是否已生成闪词
  bool get hasFlashCards => termCount > 0;
}

/// 闪词学习进度
class FlashCardProgress {
  final int total;
  final int mastered;
  final int needsReview;
  final int needsImprove;
  final int notStarted;

  FlashCardProgress({
    required this.total,
    required this.mastered,
    required this.needsReview,
    required this.needsImprove,
    required this.notStarted,
  });

  /// 已掌握百分比
  double get masteredPercent => total > 0 ? mastered / total : 0;

  /// 学习进度百分比（已掌握 + 待复习）
  double get progressPercent => total > 0 ? (mastered + needsReview) / total : 0;
}

/// 笔记详情页状态
class NoteDetailState {
  /// 当前笔记
  final Rx<NoteModel?> note = Rx<NoteModel?>(null);

  /// 闪词学习进度
  final Rx<FlashCardProgress?> progress = Rx<FlashCardProgress?>(null);

  /// 是否正在加载
  final RxBool isLoading = false.obs;

  /// 是否正在生成闪词
  final RxBool isGenerating = false.obs;

  /// 是否已生成闪词
  bool get hasFlashCards => note.value?.hasFlashCards ?? false;

  /// 笔记标题
  String get noteTitle => note.value?.title ?? '';

  /// 笔记内容
  String get noteContent => note.value?.content ?? '';
}

