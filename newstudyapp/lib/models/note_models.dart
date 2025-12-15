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


