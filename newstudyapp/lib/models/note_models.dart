import 'package:flutter/foundation.dart';

class NoteExtractResponse {
  const NoteExtractResponse({
    required this.title,
    required this.terms,
    required this.totalChars,
    this.text,
  });

  factory NoteExtractResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('[NoteExtractResponse] JSON keys: ${json.keys.toList()}');
    final titleRaw = json['title'];
    final termsRaw = json['terms'];
    final totalCharsRaw = json['total_chars'];
    final textRaw = json['text'];
    debugPrint('[NoteExtractResponse] textRaw type: ${textRaw.runtimeType}');

    final String? title =
        titleRaw is String && titleRaw.trim().isNotEmpty ? titleRaw : null;

    if (termsRaw is! List) {
      throw const FormatException('缺少 terms 字段');
    }
    final terms = termsRaw
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    if (totalCharsRaw is! int || totalCharsRaw < 0) {
      throw const FormatException('缺少 total_chars 字段');
    }

    final String? text = textRaw is String ? textRaw : null;

    return NoteExtractResponse(
        title: title, terms: terms, totalChars: totalCharsRaw, text: text);
  }

  final String? title;
  final List<String> terms;
  final int totalChars;
  final String? text;
}

/// 智能笔记生成响应模型
class SmartNoteResponse {
  const SmartNoteResponse({
    required this.noteContent,
    required this.terms,
    required this.inputChars,
  });

  factory SmartNoteResponse.fromJson(Map<String, dynamic> json) {
    final noteContentRaw = json['note_content'];
    final termsRaw = json['terms'];
    final inputCharsRaw = json['input_chars'];

    if (noteContentRaw is! String) {
      throw const FormatException('缺少 note_content 字段');
    }

    if (termsRaw is! List) {
      throw const FormatException('缺少 terms 字段');
    }
    final terms = termsRaw
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    if (inputCharsRaw is! int || inputCharsRaw < 0) {
      throw const FormatException('缺少 input_chars 字段');
    }

    return SmartNoteResponse(
      noteContent: noteContentRaw,
      terms: terms,
      inputChars: inputCharsRaw,
    );
  }

  /// Markdown格式的笔记内容
  final String noteContent;

  /// 闪词列表
  final List<String> terms;

  /// 用户输入字符数
  final int inputChars;
}

/// 创建笔记响应模型
class CreateNoteResponse {
  const CreateNoteResponse({
    required this.noteId,
    required this.title,
    required this.flashCardCount,
  });

  factory CreateNoteResponse.fromJson(Map<String, dynamic> json) {
    final noteIdRaw = json['note_id'];
    final titleRaw = json['title'];
    final flashCardCountRaw = json['flash_card_count'];

    // note_id 可能是字符串（UUID）或整数，统一转换为字符串
    final String noteId;
    if (noteIdRaw is String) {
      noteId = noteIdRaw;
    } else if (noteIdRaw is int) {
      noteId = noteIdRaw.toString();
    } else {
      throw FormatException('解析失败: note_id 字段无效 (值为: $noteIdRaw)');
    }

    if (titleRaw == null) {
      // 容错处理：如果后端没返回标题，使用默认值
      // throw const FormatException('缺少 title 字段');
    }
    final String title = (titleRaw is String && titleRaw.isNotEmpty) ? titleRaw : '未命名笔记';

    // 容错处理：flash_card_count
    final int flashCardCount = (flashCardCountRaw is int && flashCardCountRaw >= 0) ? flashCardCountRaw : 0;

    return CreateNoteResponse(
      noteId: noteId,
      title: titleRaw,
      flashCardCount: flashCardCountRaw,
    );
  }

  final String noteId;
  final String title;
  final int flashCardCount;
}

/// 笔记列表项模型
class NoteListItem {
  const NoteListItem({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.flashCardCount,
    required this.masteredCount,
    required this.needsReviewCount,
    this.needsImproveCount = 0,
    this.notMasteredCount = 0,
  });

  factory NoteListItem.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final titleRaw = json['title'];
    final createdAtRaw = json['created_at'];
    final flashCardCountRaw = json['flash_card_count'];
    final masteredCountRaw = json['mastered_count'] ?? 0;
    final needsReviewCountRaw = json['needs_review_count'] ?? 0;
    final needsImproveCountRaw = json['needs_improve_count'] ?? 0;
    final notMasteredCountRaw = json['not_mastered_count'] ?? 0;

    // ID 可能是字符串（UUID）或整数，统一转换为字符串
    final String id;
    if (idRaw is String) {
      id = idRaw;
    } else if (idRaw is int) {
      id = idRaw.toString();
    } else {
      throw const FormatException('缺少 id 字段或 id 类型无效');
    }

    if (titleRaw is! String || titleRaw.isEmpty) {
      throw const FormatException('缺少 title 字段');
    }

    if (createdAtRaw is! String) {
      throw const FormatException('缺少 created_at 字段');
    }

    if (flashCardCountRaw is! int || flashCardCountRaw < 0) {
      throw const FormatException('缺少 flash_card_count 字段');
    }

    return NoteListItem(
      id: id,
      title: titleRaw,
      createdAt: createdAtRaw,
      flashCardCount: flashCardCountRaw,
      masteredCount: masteredCountRaw is int ? masteredCountRaw : 0,
      needsReviewCount: needsReviewCountRaw is int ? needsReviewCountRaw : 0,
      needsImproveCount: needsImproveCountRaw is int ? needsImproveCountRaw : 0,
      notMasteredCount: notMasteredCountRaw is int ? notMasteredCountRaw : 0,
    );
  }

  final String id;
  final String title;
  final String createdAt;
  final int flashCardCount;
  final int masteredCount;
  final int needsReviewCount;
  final int needsImproveCount;
  final int notMasteredCount;
}

/// 笔记列表响应模型
class NotesListResponse {
  const NotesListResponse({
    required this.notes,
    required this.total,
  });

  factory NotesListResponse.fromJson(Map<String, dynamic> json) {
    final notesRaw = json['notes'];
    final totalRaw = json['total'];

    if (notesRaw is! List) {
      throw const FormatException('缺少 notes 字段');
    }

    final notes = notesRaw
        .map((e) => NoteListItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    if (totalRaw is! int || totalRaw < 0) {
      throw const FormatException('缺少 total 字段');
    }

    return NotesListResponse(
      notes: notes,
      total: totalRaw,
    );
  }

  final List<NoteListItem> notes;
  final int total;
}

// ==================== 学习相关模型 ====================

/// 学习角色模型
class LearningRole {
  const LearningRole({
    required this.id,
    required this.name,
    required this.description,
  });

  factory LearningRole.fromJson(Map<String, dynamic> json) {
    return LearningRole(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  final String id;
  final String name;
  final String description;
}

/// 角色列表响应模型
class RolesResponse {
  const RolesResponse({required this.roles});

  factory RolesResponse.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'];
    if (rolesRaw is! List) {
      throw const FormatException('缺少 roles 字段');
    }

    final roles = rolesRaw
        .map((e) => LearningRole.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    return RolesResponse(roles: roles);
  }

  final List<LearningRole> roles;
}

/// 评估请求模型
class EvaluateRequest {
  const EvaluateRequest({
    required this.cardId,
    required this.noteId,
    required this.selectedRole,
    required this.userExplanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'note_id': noteId,
      'selected_role': selectedRole,
      'user_explanation': userExplanation,
    };
  }

  final int cardId;
  final String noteId;
  final String selectedRole;
  final String userExplanation;
}

/// 评估响应模型
class EvaluateResponse {
  const EvaluateResponse({
    required this.score,
    required this.status,
    required this.feedback,
    required this.highlights,
    required this.suggestions,
    required this.learningRecordId,
  });

  factory EvaluateResponse.fromJson(Map<String, dynamic> json) {
    // Handle both int and String for score
    final scoreRaw = json['score'];
    final int score = scoreRaw is int
        ? scoreRaw
        : (scoreRaw is String ? int.tryParse(scoreRaw) ?? 0 : 0);
    final status = json['status'] as String;
    final feedback = json['feedback'] as String;

    final highlightsRaw = json['highlights'] as List? ?? [];
    final highlights =
        highlightsRaw.whereType<String>().toList(growable: false);

    final suggestionsRaw = json['suggestions'] as List? ?? [];
    final suggestions =
        suggestionsRaw.whereType<String>().toList(growable: false);

    // learning_record_id 可能是整数或字符串（UUID），统一转换为字符串
    final idRaw = json['learning_record_id'];
    final learningRecordId = idRaw is String ? idRaw : idRaw.toString();

    return EvaluateResponse(
      score: score,
      status: status,
      feedback: feedback,
      highlights: highlights,
      suggestions: suggestions,
      learningRecordId: learningRecordId,
    );
  }

  final int score;
  final String status;
  final String feedback;
  final List<String> highlights;
  final List<String> suggestions;
  final String learningRecordId;
}

/// 闪词卡片状态响应模型
class CardStatusResponse {
  const CardStatusResponse({
    required this.id,
    required this.term,
    required this.status,
    required this.reviewCount,
  });

  factory CardStatusResponse.fromJson(Map<String, dynamic> json) {
    return CardStatusResponse(
      id: json['id'] as int,
      term: json['term'] as String,
      status: json['status'] as String,
      reviewCount: json['review_count'] as int,
    );
  }

  final int id;
  final String term;
  final String status;
  final int reviewCount;
}

/// 闪词卡片模型（包含学习历史）
class FlashCard {
  const FlashCard({
    required this.id,
    required this.noteId,
    required this.term,
    required this.status,
    required this.reviewCount,
    required this.createdAt,
    required this.updatedAt,
    this.learningHistory = const [],
  });

  factory FlashCard.fromJson(Map<String, dynamic> json) {
    final historyRaw = json['learning_history'] as List? ?? [];
    final history = historyRaw
        .map((e) => LearningRecord.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    // ID 可能是字符串（UUID）或整数，统一转换为字符串
    final idRaw = json['id'];
    final String id = idRaw is String ? idRaw : idRaw.toString();
    
    final noteIdRaw = json['note_id'];
    final String noteId = noteIdRaw is String ? noteIdRaw : noteIdRaw.toString();

    return FlashCard(
      id: id,
      noteId: noteId,
      term: json['term'] as String,
      status: json['status'] as String,
      reviewCount: json['review_count'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      learningHistory: history,
    );
  }

  final String id;
  final String noteId;
  final String term;
  final String status;
  final int reviewCount;
  final String createdAt;
  final String updatedAt;
  final List<LearningRecord> learningHistory;
}

/// 学习记录模型
class LearningRecord {
  const LearningRecord({
    required this.id,
    required this.selectedRole,
    required this.userExplanation,
    required this.score,
    required this.aiFeedback,
    required this.status,
    required this.attemptNumber,
    required this.attemptedAt,
  });

  factory LearningRecord.fromJson(Map<String, dynamic> json) {
    // Handle both int and String for id (could be UUID or integer)
    final idRaw = json['id'];
    final int id = idRaw is int
        ? idRaw
        : (idRaw is String ? int.tryParse(idRaw) ?? 0 : 0);

    // Handle both int and String for score
    final scoreRaw = json['score'];
    final int score = scoreRaw is int
        ? scoreRaw
        : (scoreRaw is String ? int.tryParse(scoreRaw) ?? 0 : 0);

    return LearningRecord(
      id: id,
      selectedRole: json['selected_role'] as String? ?? '',
      userExplanation: json['user_explanation'] as String? ?? '',
      score: score,
      aiFeedback: json['ai_feedback'] as String? ?? '',
      status: json['status'] as String? ?? '',
      attemptNumber: json['attempt_number'] is int
          ? json['attempt_number'] as int
          : (json['attempt_number'] is String ? int.tryParse(json['attempt_number'] as String) ?? 1 : 1),
      attemptedAt: json['attempted_at'] as String? ?? '',
    );
  }

  final int id;
  final String selectedRole;
  final String userExplanation;
  final int score;
  final String aiFeedback;
  final String status;
  final int attemptNumber;
  final String attemptedAt;
}

// ==================== 学习中心相关模型 ====================

/// 学习中心统计数据模型
class StudyCenterStatistics {
  const StudyCenterStatistics({
    required this.todayReviewCount,
    required this.masteredCount,
    required this.needsReviewCount,
    required this.needsImproveCount,
    required this.notMasteredCount,
    required this.totalCardsCount,
  });

  factory StudyCenterStatistics.fromJson(Map<String, dynamic> json) {
    return StudyCenterStatistics(
      todayReviewCount: json['today_review_count'] as int? ?? 0,
      masteredCount: json['mastered_count'] as int? ?? 0,
      needsReviewCount: json['needs_review_count'] as int? ?? 0,
      needsImproveCount: json['needs_improve_count'] as int? ?? 0,
      notMasteredCount: json['not_mastered_count'] as int? ?? 0,
      totalCardsCount: json['total_cards_count'] as int? ?? 0,
    );
  }

  final int todayReviewCount;
  final int masteredCount;
  final int needsReviewCount;
  final int needsImproveCount;
  final int notMasteredCount;
  final int totalCardsCount;
}

/// 闪词卡片列表项模型（用于学习中心）
class FlashCardListItem {
  const FlashCardListItem({
    required this.id,
    required this.term,
    required this.status,
    required this.noteId,
    required this.noteTitle,
    this.reviewCount = 0,
    this.lastStudiedAt,
    this.bestScore,
    this.attemptCount = 0,
  });

  factory FlashCardListItem.fromJson(Map<String, dynamic> json) {
    // ID 可能是字符串（UUID）或整数，统一转换为字符串
    final idRaw = json['id'];
    final String id = idRaw is String ? idRaw : idRaw.toString();
    
    final noteIdRaw = json['note_id'];
    final String noteId = noteIdRaw is String ? noteIdRaw : noteIdRaw.toString();

    return FlashCardListItem(
      id: id,
      term: json['term'] as String,
      status: json['status'] as String,
      noteId: noteId,
      noteTitle: json['note_title'] as String? ?? '',
      reviewCount: json['review_count'] as int? ?? 0,
      lastStudiedAt: json['last_studied_at'] as String?,
      bestScore: json['best_score'] as int?,
      attemptCount: json['attempt_count'] as int? ?? 0,
    );
  }

  final String id;
  final String term;
  final String status;
  final String noteId;
  final String noteTitle;
  final int reviewCount;
  final String? lastStudiedAt;
  final int? bestScore;
  final int attemptCount;
}

/// 闪词卡片列表响应模型
class FlashCardListResponse {
  const FlashCardListResponse({
    required this.cards,
    required this.total,
  });

  factory FlashCardListResponse.fromJson(Map<String, dynamic> json) {
    final cardsRaw = json['cards'] as List? ?? [];
    final cards = cardsRaw
        .map((e) => FlashCardListItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    return FlashCardListResponse(
      cards: cards,
      total: json['total'] as int? ?? 0,
    );
  }

  final List<FlashCardListItem> cards;
  final int total;
}

/// 首页学习统计 - 趋势点
class DailyStudyCount {
  const DailyStudyCount({
    required this.date,
    required this.count,
  });

  factory DailyStudyCount.fromJson(Map<String, dynamic> json) {
    return DailyStudyCount(
      date: json['date'] as String,
      count: json['count'] as int? ?? 0,
    );
  }

  final String date;
  final int count;
}

/// 首页学习统计
class HomeStatisticsResponse {
  const HomeStatisticsResponse({
    required this.todayReviewCount,
    required this.masteredCount,
    required this.needsReviewCount,
    required this.needsImproveCount,
    required this.notMasteredCount,
    required this.totalCardsCount,
    required this.streakDays,
    required this.activeDays7d,
    required this.weekCompleted,
    required this.weekTarget,
    required this.trend7d,
  });

  factory HomeStatisticsResponse.fromJson(Map<String, dynamic> json) {
    final trendRaw = json['trend_7d'] as List? ?? [];
    return HomeStatisticsResponse(
      todayReviewCount: json['today_review_count'] as int? ?? 0,
      masteredCount: json['mastered_count'] as int? ?? 0,
      needsReviewCount: json['needs_review_count'] as int? ?? 0,
      needsImproveCount: json['needs_improve_count'] as int? ?? 0,
      notMasteredCount: json['not_mastered_count'] as int? ?? 0,
      totalCardsCount: json['total_cards_count'] as int? ?? 0,
      streakDays: json['streak_days'] as int? ?? 0,
      activeDays7d: json['active_days_7d'] as int? ?? 0,
      weekCompleted: json['week_completed'] as int? ?? 0,
      weekTarget: json['week_target'] as int? ?? 0,
      trend7d: trendRaw
          .whereType<Map<String, dynamic>>()
          .map(DailyStudyCount.fromJson)
          .toList(growable: false),
    );
  }

  final int todayReviewCount;
  final int masteredCount;
  final int needsReviewCount;
  final int needsImproveCount;
  final int notMasteredCount;
  final int totalCardsCount;
  final int streakDays;
  final int activeDays7d;
  final int weekCompleted;
  final int weekTarget;
  final List<DailyStudyCount> trend7d;
}

/// 按笔记分类的词条统计模型
class CardsByNoteItem {
  const CardsByNoteItem({
    required this.noteId,
    required this.noteTitle,
    required this.totalCount,
    required this.masteredCount,
    required this.needsReviewCount,
    required this.needsImproveCount,
    required this.notMasteredCount,
  });

  factory CardsByNoteItem.fromJson(Map<String, dynamic> json) {
    // note_id 可能是字符串（UUID）或整数，统一转换为字符串
    final noteIdRaw = json['note_id'];
    final String noteId = noteIdRaw is String ? noteIdRaw : noteIdRaw.toString();

    return CardsByNoteItem(
      noteId: noteId,
      noteTitle: json['note_title'] as String? ?? '',
      totalCount: json['total_count'] as int? ?? 0,
      masteredCount: json['mastered_count'] as int? ?? 0,
      needsReviewCount: json['needs_review_count'] as int? ?? 0,
      needsImproveCount: json['needs_improve_count'] as int? ?? 0,
      notMasteredCount: json['not_mastered_count'] as int? ?? 0,
    );
  }

  final String noteId;
  final String noteTitle;
  final int totalCount;
  final int masteredCount;
  final int needsReviewCount;
  final int needsImproveCount;
  final int notMasteredCount;
}

/// 按笔记分类的词条列表响应模型
class CardsByNoteResponse {
  const CardsByNoteResponse({
    required this.notes,
    required this.total,
  });

  factory CardsByNoteResponse.fromJson(Map<String, dynamic> json) {
    final notesRaw = json['notes'] as List? ?? [];
    final notes = notesRaw
        .map((e) => CardsByNoteItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    return CardsByNoteResponse(
      notes: notes,
      total: json['total'] as int? ?? 0,
    );
  }

  final List<CardsByNoteItem> notes;
  final int total;
}

/// 学习统计响应
class LearningStatisticsResponse {
  const LearningStatisticsResponse({
    required this.mastered,
    required this.totalTerms,
    required this.consecutiveDays,
    required this.totalMinutes,
  });

  factory LearningStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return LearningStatisticsResponse(
      mastered: json['mastered'] as int? ?? 0,
      totalTerms: json['totalTerms'] as int? ?? 0,
      consecutiveDays: json['consecutiveDays'] as int? ?? 0,
      totalMinutes: json['totalMinutes'] as int? ?? 0,
    );
  }

  final int mastered;
  final int totalTerms;
  final int consecutiveDays;
  final int totalMinutes;
}

/// 今日复习统计响应
class TodayReviewStatisticsResponse {
  const TodayReviewStatisticsResponse({
    required this.reviewDue,
    required this.reviewCompleted,
  });

  factory TodayReviewStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return TodayReviewStatisticsResponse(
      reviewDue: json['reviewDue'] as int? ?? 0,
      reviewCompleted: json['reviewCompleted'] as int? ?? 0,
    );
  }

  final int reviewDue;
  final int reviewCompleted;
}

/// 笔记响应
class NoteResponse {
  const NoteResponse({
    required this.id,
    this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.termCount,
  });

  factory NoteResponse.fromJson(Map<String, dynamic> json) {
    return NoteResponse(
      id: json['id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String? ?? '', // 内容可能为空
      createdAt: (json['created_at'] ?? json['createdAt']) as String? ?? '',
      updatedAt: (json['updated_at'] ?? json['updatedAt']) as String? ?? '',
      termCount: (json['term_count'] ?? json['termCount']) as int? ?? 0,
    );
  }

  final String id;
  final String? title;
  final String content;
  final String createdAt;
  final String updatedAt;
  final int termCount;
}

/// 闪卡生成响应
class FlashCardGenerateResponse {
  const FlashCardGenerateResponse({
    required this.noteId,
    required this.terms,
    required this.total,
  });

  factory FlashCardGenerateResponse.fromJson(Map<String, dynamic> json) {
    final termsRaw = json['terms'] as List? ?? [];
    return FlashCardGenerateResponse(
      noteId: json['note_id'] as String,
      terms: termsRaw.map((e) => e as String).toList(growable: false),
      total: json['total'] as int,
    );
  }

  final String noteId;
  final List<String> terms;
  final int total;
}

/// 闪卡详情响应（含状态）
class FlashCardDetailResponse {
  const FlashCardDetailResponse({
    required this.term,
    required this.status,
  });

  factory FlashCardDetailResponse.fromJson(Map<String, dynamic> json) {
    return FlashCardDetailResponse(
      term: json['term'] as String,
      status: json['status'] as String,
    );
  }

  final String term;
  final String status;
}

/// 闪卡列表响应（含状态）
class FlashCardListWithStatusResponse {
  const FlashCardListWithStatusResponse({
    required this.noteId,
    required this.cards,
    required this.total,
    required this.masteredCount,
  });

  factory FlashCardListWithStatusResponse.fromJson(Map<String, dynamic> json) {
    final cardsRaw = json['cards'] as List? ?? [];
    return FlashCardListWithStatusResponse(
      noteId: json['note_id'] as String,
      cards: cardsRaw
          .map((e) => FlashCardDetailResponse.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      total: json['total'] as int,
      masteredCount: json['mastered_count'] as int? ?? 0,
    );
  }

  final String noteId;
  final List<FlashCardDetailResponse> cards;
  final int total;
  final int masteredCount;
}

/// 复习闪卡响应（单个卡片）
class ReviewFlashCardResponse {
  const ReviewFlashCardResponse({
    required this.id,
    required this.noteId,
    required this.term,
    required this.status,
    required this.createdAt,
    this.lastReviewedAt,
  });

  factory ReviewFlashCardResponse.fromJson(Map<String, dynamic> json) {
    return ReviewFlashCardResponse(
      id: json['id'] as String,
      noteId: json['noteId'] as String,
      term: json['term'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      lastReviewedAt: json['lastReviewedAt'] as String?,
    );
  }

  final String id;
  final String noteId;
  final String term;
  final String status;
  final String createdAt;
  final String? lastReviewedAt;
}

/// 复习闪卡列表响应
class ReviewFlashCardsResponse {
  const ReviewFlashCardsResponse({
    required this.cards,
    this.total,
  });

  factory ReviewFlashCardsResponse.fromJson(Map<String, dynamic> json) {
    final cardsRaw = json['cards'] as List? ?? [];
    return ReviewFlashCardsResponse(
      cards: cardsRaw
          .map((e) => ReviewFlashCardResponse.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      total: json['total'] as int?,
    );
  }

  final List<ReviewFlashCardResponse> cards;
  final int? total;
}
