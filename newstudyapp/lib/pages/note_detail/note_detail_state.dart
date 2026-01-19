import 'package:get/get.dart';

/// 闪词卡片状态枚举
enum CardStatus {
  notStarted,   // 未学习
  needsReview,  // 需巩固（良好）
  needsImprove, // 需改进
  notMastered,  // 未掌握
  mastered,     // 已掌握
}

/// 笔记模型
class NoteModel {
  final String id;
  final String title;
  final String content;
  final String? markdownContent; // AI生成的Markdown笔记内容
  final DateTime createdAt;
  final DateTime updatedAt;
  final int termCount;
  final List<String> terms; // 闪词列表

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.markdownContent,
    required this.createdAt,
    required this.updatedAt,
    this.termCount = 0,
    this.terms = const [],
  });

  /// 是否已生成闪词
  bool get hasFlashCards => termCount > 0;

  /// 是否有Markdown内容
  bool get hasMarkdownContent => markdownContent != null && markdownContent!.isNotEmpty;

  /// 复制并更新
  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? markdownContent,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? termCount,
    List<String>? terms,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      markdownContent: markdownContent ?? this.markdownContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      termCount: termCount ?? this.termCount,
      terms: terms ?? this.terms,
    );
  }
}

/// 闪词学习进度
class FlashCardProgress {
  final int total;
  final int mastered;
  final int needsReview;
  final int needsImprove;
  final int notMastered;
  final int notStarted;

  FlashCardProgress({
    required this.total,
    required this.mastered,
    required this.needsReview,
    required this.needsImprove,
    this.notMastered = 0,
    required this.notStarted,
  });

  factory FlashCardProgress.fromJson(Map<String, dynamic> json) {
    return FlashCardProgress(
      total: json['total'] as int,
      mastered: json['mastered'] as int,
      needsReview: json['needsReview'] as int,
      needsImprove: json['needsImprove'] as int,
      notMastered: json['notMastered'] as int? ?? 0,
      notStarted: json['notStarted'] as int,
    );
  }

  /// 已掌握百分比
  double get masteredPercent => total > 0 ? mastered / total : 0;

  /// 学习进度百分比（已掌握 + 需巩固 + 需改进 + 未掌握）
  /// 只要学习过就算进度，包括已掌握、需巩固、需改进和未掌握
  double get progressPercent => total > 0 ? (mastered + needsReview + needsImprove + notMastered) / total : 0;
}

/// 笔记详情页状态
class NoteDetailState {
  /// 用户输入的原始内容（从创建笔记页面传入）
  final RxString userInput = ''.obs;
  
  /// 当前笔记
  final Rx<NoteModel?> note = Rx<NoteModel?>(null);

  /// 闪词学习进度
  final Rx<FlashCardProgress?> progress = Rx<FlashCardProgress?>(null);

  /// 是否正在加载
  final RxBool isLoading = false.obs;

  /// 是否正在生成闪词/笔记
  final RxBool isGenerating = false.obs;
  
  /// 生成状态文本
  final RxString generatingStatus = ''.obs;

  /// 是否已生成闪词
  bool get hasFlashCards => note.value?.hasFlashCards ?? false;
  
  /// 是否有Markdown内容
  bool get hasMarkdownContent => note.value?.hasMarkdownContent ?? false;

  /// 笔记标题
  String get noteTitle => note.value?.title ?? '智能笔记';

  /// 笔记内容（原始内容）
  String get noteContent => note.value?.content ?? '';
  
  /// Markdown笔记内容
  String get markdownContent => note.value?.markdownContent ?? '';
  
  /// 闪词列表
  List<String> get terms => note.value?.terms ?? [];
  
  /// 笔记的默认学习角色
  final RxString defaultRole = ''.obs;

  /// 是否已加载闪词卡片（懒加载控制）
  final RxBool flashCardsLoaded = false.obs;

  /// 是否展开笔记完整内容（用于内容过长的懒加载）
  final RxBool isNoteContentExpanded = false.obs;

  /// 笔记内容是否过长（超过一定字数）
  bool get isContentTooLong => markdownContent.length > 800;

  /// 截断后的笔记内容（用于预览）
  String get truncatedContent {
    if (!isContentTooLong) return markdownContent;
    final preview = markdownContent.substring(0, 800);
    // 在合适的分隔符处截断（如段落、标题等）
    final breakPoints = ['\n\n', '\n# ', '\n## ', '。', '！', '？', '.'];
    for (final bp in breakPoints) {
      final lastIndex = preview.lastIndexOf(bp);
      if (lastIndex > 200) {
        return preview.substring(0, lastIndex + bp.length);
      }
    }
    return preview;
  }
}
