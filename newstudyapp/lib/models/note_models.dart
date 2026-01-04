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


