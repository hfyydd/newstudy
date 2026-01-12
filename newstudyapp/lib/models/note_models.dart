import 'package:newstudyapp/pages/note_detail/note_detail_state.dart';

class NoteExtractResponse {
  const NoteExtractResponse({
    required this.title,
    required this.text,
    required this.terms,
    required this.totalChars,
  });

  factory NoteExtractResponse.fromJson(Map<String, dynamic> json) {
    final titleRaw = json['title'];
    final textRaw = json['text'];
    final termsRaw = json['terms'];
    final totalCharsRaw = json['total_chars'];

    final String? title =
        titleRaw is String && titleRaw.trim().isNotEmpty ? titleRaw : null;

    final String text = textRaw is String ? textRaw : '';

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

    return NoteExtractResponse(
        title: title, text: text, terms: terms, totalChars: totalCharsRaw);
  }

  final String? title;
  final String text;
  final List<String> terms;
  final int totalChars;
}

/// 笔记响应模型（用于创建和获取笔记）
class NoteResponse {
  const NoteResponse({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    required this.createdAt,
    required this.updatedAt,
    required this.termCount,
  });

  factory NoteResponse.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final titleRaw = json['title'];
    final contentRaw = json['content'];
    final summaryRaw = json['summary'];
    final createdAtRaw = json['createdAt'];
    final updatedAtRaw = json['updatedAt'];
    final termCountRaw = json['termCount'];

    if (idRaw is! String || idRaw.isEmpty) {
      throw const FormatException('缺少 id 字段');
    }
    if (contentRaw is! String) {
      throw const FormatException('缺少 content 字段');
    }
    if (createdAtRaw is! String) {
      throw const FormatException('缺少 createdAt 字段');
    }
    if (updatedAtRaw is! String) {
      throw const FormatException('缺少 updatedAt 字段');
    }

    final String? title =
        titleRaw is String && titleRaw.trim().isNotEmpty ? titleRaw : null;

    final String? summary = summaryRaw is String && summaryRaw.trim().isNotEmpty
        ? summaryRaw
        : null;

    return NoteResponse(
      id: idRaw,
      title: title,
      content: contentRaw,
      summary: summary,
      createdAt: DateTime.parse(createdAtRaw),
      updatedAt: DateTime.parse(updatedAtRaw),
      termCount: termCountRaw is int ? termCountRaw : 0,
    );
  }

  final String id;
  final String? title;
  final String content;
  final String? summary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int termCount;

  /// 转换为 NoteModel
  NoteModel toNoteModel() {
    return NoteModel(
      id: id,
      title: title ?? '',
      content: content,
      summary: summary,
      createdAt: createdAt,
      updatedAt: updatedAt,
      termCount: termCount,
    );
  }
}

/// 生成闪词卡片响应模型
class FlashCardGenerateResponse {
  const FlashCardGenerateResponse({
    required this.noteId,
    required this.terms,
    required this.total,
  });

  factory FlashCardGenerateResponse.fromJson(Map<String, dynamic> json) {
    final noteIdRaw = json['note_id'];
    final termsRaw = json['terms'];
    final totalRaw = json['total'];

    if (noteIdRaw is! String || noteIdRaw.isEmpty) {
      throw const FormatException('缺少 note_id 字段');
    }
    if (termsRaw is! List) {
      throw const FormatException('缺少 terms 字段');
    }
    if (totalRaw is! int) {
      throw const FormatException('缺少 total 字段');
    }

    final terms = termsRaw
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    return FlashCardGenerateResponse(
      noteId: noteIdRaw,
      terms: terms,
      total: totalRaw,
    );
  }

  final String noteId;
  final List<String> terms;
  final int total;
}

/// 闪词卡片列表响应模型
class FlashCardListResponse {
  const FlashCardListResponse({
    required this.noteId,
    required this.terms,
    required this.total,
  });

  factory FlashCardListResponse.fromJson(Map<String, dynamic> json) {
    final noteIdRaw = json['note_id'];
    final termsRaw = json['terms'];
    final totalRaw = json['total'];

    if (noteIdRaw is! String || noteIdRaw.isEmpty) {
      throw const FormatException('缺少 note_id 字段');
    }
    if (termsRaw is! List) {
      throw const FormatException('缺少 terms 字段');
    }
    if (totalRaw is! int) {
      throw const FormatException('缺少 total 字段');
    }

    final terms = termsRaw
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    return FlashCardListResponse(
      noteId: noteIdRaw,
      terms: terms,
      total: totalRaw,
    );
  }

  final String noteId;
  final List<String> terms;
  final int total;
}

/// 闪词卡片详情模型（含状态）
class FlashCardDetail {
  const FlashCardDetail({
    required this.term,
    required this.status,
  });

  factory FlashCardDetail.fromJson(Map<String, dynamic> json) {
    final termRaw = json['term'];
    final statusRaw = json['status'];

    if (termRaw is! String || termRaw.trim().isEmpty) {
      throw const FormatException('缺少 term 字段');
    }
    if (statusRaw is! String) {
      throw const FormatException('缺少 status 字段');
    }

    return FlashCardDetail(
      term: termRaw.trim(),
      status: statusRaw,
    );
  }

  final String term;
  final String status; // notStarted, needsReview, needsImprove, mastered
}

/// 闪词卡片列表响应模型（含状态）
class FlashCardListWithStatusResponse {
  const FlashCardListWithStatusResponse({
    required this.noteId,
    required this.cards,
    required this.total,
    required this.masteredCount,
  });

  factory FlashCardListWithStatusResponse.fromJson(Map<String, dynamic> json) {
    final noteIdRaw = json['note_id'];
    final cardsRaw = json['cards'];
    final totalRaw = json['total'];
    final masteredCountRaw = json['mastered_count'];

    if (noteIdRaw is! String || noteIdRaw.isEmpty) {
      throw const FormatException('缺少 note_id 字段');
    }
    if (cardsRaw is! List) {
      throw const FormatException('缺少 cards 字段');
    }
    if (totalRaw is! int) {
      throw const FormatException('缺少 total 字段');
    }
    if (masteredCountRaw is! int) {
      throw const FormatException('缺少 mastered_count 字段');
    }

    final cards = cardsRaw
        .whereType<Map<String, dynamic>>()
        .map((e) => FlashCardDetail.fromJson(e))
        .toList(growable: false);

    return FlashCardListWithStatusResponse(
      noteId: noteIdRaw,
      cards: cards,
      total: totalRaw,
      masteredCount: masteredCountRaw,
    );
  }

  final String noteId;
  final List<FlashCardDetail> cards;
  final int total;
  final int masteredCount;
}

/// 笔记列表项响应模型
class NoteListItemResponse {
  const NoteListItemResponse({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.termCount,
    required this.masteredCount,
    required this.reviewCount,
  });

  factory NoteListItemResponse.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final titleRaw = json['title'];
    final createdAtRaw = json['createdAt'];
    final updatedAtRaw = json['updatedAt'];
    final termCountRaw = json['termCount'];
    final masteredCountRaw = json['masteredCount'];
    final reviewCountRaw = json['reviewCount'];

    if (idRaw is! String || idRaw.isEmpty) {
      throw const FormatException('缺少 id 字段');
    }
    if (createdAtRaw is! String) {
      throw const FormatException('缺少 createdAt 字段');
    }
    if (updatedAtRaw is! String) {
      throw const FormatException('缺少 updatedAt 字段');
    }

    final String? title =
        titleRaw is String && titleRaw.trim().isNotEmpty ? titleRaw : null;

    return NoteListItemResponse(
      id: idRaw,
      title: title,
      createdAt: DateTime.parse(createdAtRaw),
      updatedAt: DateTime.parse(updatedAtRaw),
      termCount: termCountRaw is int ? termCountRaw : 0,
      masteredCount: masteredCountRaw is int ? masteredCountRaw : 0,
      reviewCount: reviewCountRaw is int ? reviewCountRaw : 0,
    );
  }

  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int termCount;
  final int masteredCount;
  final int reviewCount;
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
    if (totalRaw is! int) {
      throw const FormatException('缺少 total 字段');
    }

    final notes = notesRaw
        .map((item) =>
            NoteListItemResponse.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    return NotesListResponse(
      notes: notes,
      total: totalRaw,
    );
  }

  final List<NoteListItemResponse> notes;
  final int total;
}

/// 闪词学习进度响应辅助函数（FlashCardProgress 类在 note_detail_state.dart 中定义）
FlashCardProgress flashCardProgressFromJson(Map<String, dynamic> json) {
  final totalRaw = json['total'];
  final masteredRaw = json['mastered'];
  final needsReviewRaw = json['needsReview'];
  final needsImproveRaw = json['needsImprove'];
  final notStartedRaw = json['notStarted'];

  if (totalRaw is! int) {
    throw const FormatException('缺少 total 字段');
  }

  return FlashCardProgress(
    total: totalRaw,
    mastered: masteredRaw is int ? masteredRaw : 0,
    needsReview: needsReviewRaw is int ? needsReviewRaw : 0,
    needsImprove: needsImproveRaw is int ? needsImproveRaw : 0,
    notStarted: notStartedRaw is int ? notStartedRaw : 0,
  );
}

/// 学习统计响应模型
class LearningStatisticsResponse {
  const LearningStatisticsResponse({
    required this.mastered,
    required this.totalTerms,
    required this.consecutiveDays,
    required this.totalMinutes,
  });

  factory LearningStatisticsResponse.fromJson(Map<String, dynamic> json) {
    final masteredRaw = json['mastered'];
    final totalTermsRaw = json['totalTerms'];
    final consecutiveDaysRaw = json['consecutiveDays'];
    final totalMinutesRaw = json['totalMinutes'];

    if (masteredRaw is! int) {
      throw const FormatException('缺少 mastered 字段');
    }
    if (totalTermsRaw is! int) {
      throw const FormatException('缺少 totalTerms 字段');
    }
    if (consecutiveDaysRaw is! int) {
      throw const FormatException('缺少 consecutiveDays 字段');
    }
    if (totalMinutesRaw is! int) {
      throw const FormatException('缺少 totalMinutes 字段');
    }

    return LearningStatisticsResponse(
      mastered: masteredRaw,
      totalTerms: totalTermsRaw,
      consecutiveDays: consecutiveDaysRaw,
      totalMinutes: totalMinutesRaw,
    );
  }

  final int mastered;
  final int totalTerms;
  final int consecutiveDays;
  final int totalMinutes;
}

/// 今日复习统计响应模型
class TodayReviewStatisticsResponse {
  const TodayReviewStatisticsResponse({
    required this.total,
    required this.needsReview,
    required this.needsImprove,
  });

  factory TodayReviewStatisticsResponse.fromJson(Map<String, dynamic> json) {
    final totalRaw = json['total'];
    final needsReviewRaw = json['needsReview'];
    final needsImproveRaw = json['needsImprove'];

    if (totalRaw is! int) {
      throw const FormatException('缺少 total 字段');
    }
    if (needsReviewRaw is! int) {
      throw const FormatException('缺少 needsReview 字段');
    }
    if (needsImproveRaw is! int) {
      throw const FormatException('缺少 needsImprove 字段');
    }

    return TodayReviewStatisticsResponse(
      total: totalRaw,
      needsReview: needsReviewRaw,
      needsImprove: needsImproveRaw,
    );
  }

  final int total;
  final int needsReview;
  final int needsImprove;
}

/// 复习闪词卡片响应模型
class ReviewFlashCardResponse {
  const ReviewFlashCardResponse({
    required this.id,
    required this.noteId,
    required this.noteTitle,
    required this.term,
    required this.status,
    required this.createdAt,
    required this.lastReviewedAt,
  });

  factory ReviewFlashCardResponse.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final noteIdRaw = json['noteId'];
    final noteTitleRaw = json['noteTitle'];
    final termRaw = json['term'];
    final statusRaw = json['status'];
    final createdAtRaw = json['createdAt'];
    final lastReviewedAtRaw = json['lastReviewedAt'];

    if (idRaw is! String || idRaw.isEmpty) {
      throw const FormatException('缺少 id 字段');
    }
    if (noteIdRaw is! String || noteIdRaw.isEmpty) {
      throw const FormatException('缺少 noteId 字段');
    }
    if (termRaw is! String || termRaw.isEmpty) {
      throw const FormatException('缺少 term 字段');
    }
    if (statusRaw is! String) {
      throw const FormatException('缺少 status 字段');
    }
    if (createdAtRaw is! String) {
      throw const FormatException('缺少 createdAt 字段');
    }

    return ReviewFlashCardResponse(
      id: idRaw,
      noteId: noteIdRaw,
      noteTitle: noteTitleRaw is String && noteTitleRaw.trim().isNotEmpty
          ? noteTitleRaw
          : null,
      term: termRaw,
      status: statusRaw,
      createdAt: DateTime.parse(createdAtRaw),
      lastReviewedAt: lastReviewedAtRaw != null && lastReviewedAtRaw is String
          ? DateTime.parse(lastReviewedAtRaw)
          : null,
    );
  }

  final String id;
  final String noteId;
  final String? noteTitle;
  final String term;
  final String status; // needsReview, needsImprove
  final DateTime createdAt;
  final DateTime? lastReviewedAt;
}

/// 复习闪词卡片列表响应模型
class ReviewFlashCardsResponse {
  const ReviewFlashCardsResponse({
    required this.cards,
    required this.total,
  });

  factory ReviewFlashCardsResponse.fromJson(Map<String, dynamic> json) {
    final cardsRaw = json['cards'];
    final totalRaw = json['total'];

    if (cardsRaw is! List) {
      throw const FormatException('缺少 cards 字段');
    }
    if (totalRaw is! int) {
      throw const FormatException('缺少 total 字段');
    }

    final cards = cardsRaw
        .map((e) => ReviewFlashCardResponse.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    return ReviewFlashCardsResponse(cards: cards, total: totalRaw);
  }

  final List<ReviewFlashCardResponse> cards;
  final int total;
}
