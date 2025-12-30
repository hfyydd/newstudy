import 'package:newstudyapp/pages/note_detail/note_detail_state.dart';

class NoteExtractResponse {
  const NoteExtractResponse({
    required this.title,
    required this.terms,
    required this.totalChars,
  });

  factory NoteExtractResponse.fromJson(Map<String, dynamic> json) {
    final titleRaw = json['title'];
    final termsRaw = json['terms'];
    final totalCharsRaw = json['total_chars'];

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

    return NoteExtractResponse(
        title: title, terms: terms, totalChars: totalCharsRaw);
  }

  final String? title;
  final List<String> terms;
  final int totalChars;
}

/// 笔记响应模型（用于创建和获取笔记）
class NoteResponse {
  const NoteResponse({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.termCount,
  });

  factory NoteResponse.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final titleRaw = json['title'];
    final contentRaw = json['content'];
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

    return NoteResponse(
      id: idRaw,
      title: title,
      content: contentRaw,
      createdAt: DateTime.parse(createdAtRaw),
      updatedAt: DateTime.parse(updatedAtRaw),
      termCount: termCountRaw is int ? termCountRaw : 0,
    );
  }

  final String id;
  final String? title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int termCount;

  /// 转换为 NoteModel
  NoteModel toNoteModel() {
    return NoteModel(
      id: id,
      title: title ?? '',
      content: content,
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
