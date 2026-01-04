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

    final String? title = titleRaw is String && titleRaw.trim().isNotEmpty
        ? titleRaw
        : null;

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

    return NoteExtractResponse(title: title, terms: terms, totalChars: totalCharsRaw);
  }

  final String? title;
  final List<String> terms;
  final int totalChars;
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

    if (noteIdRaw is! int || noteIdRaw < 0) {
      throw const FormatException('缺少 note_id 字段');
    }

    if (titleRaw is! String || titleRaw.isEmpty) {
      throw const FormatException('缺少 title 字段');
    }

    if (flashCardCountRaw is! int || flashCardCountRaw < 0) {
      throw const FormatException('缺少 flash_card_count 字段');
    }

    return CreateNoteResponse(
      noteId: noteIdRaw,
      title: titleRaw,
      flashCardCount: flashCardCountRaw,
    );
  }

  final int noteId;
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
  });

  factory NoteListItem.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final titleRaw = json['title'];
    final createdAtRaw = json['created_at'];
    final flashCardCountRaw = json['flash_card_count'];
    final masteredCountRaw = json['mastered_count'] ?? 0;
    final needsReviewCountRaw = json['needs_review_count'] ?? 0;

    if (idRaw is! int || idRaw < 0) {
      throw const FormatException('缺少 id 字段');
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
      id: idRaw,
      title: titleRaw,
      createdAt: createdAtRaw,
      flashCardCount: flashCardCountRaw,
      masteredCount: masteredCountRaw is int ? masteredCountRaw : 0,
      needsReviewCount: needsReviewCountRaw is int ? needsReviewCountRaw : 0,
    );
  }

  final int id;
  final String title;
  final String createdAt;
  final int flashCardCount;
  final int masteredCount;
  final int needsReviewCount;
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


