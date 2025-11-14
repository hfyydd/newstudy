class AgentResponse {
  const AgentResponse({required this.reply});

  factory AgentResponse.fromJson(Map<String, dynamic> json) {
    final reply = json['reply'];
    if (reply is String) {
      return AgentResponse(reply: reply);
    }
    throw const FormatException('缺少 reply 字段');
  }

  final String reply;
}

class TermsResponse {
  const TermsResponse({required this.category, required this.terms});

  factory TermsResponse.fromJson(Map<String, dynamic> json) {
    final categoryRaw = json['category'];
    final termsRaw = json['terms'];

    if (categoryRaw is! String || categoryRaw.isEmpty) {
      throw const FormatException('缺少 category 字段');
    }

    if (termsRaw is! List) {
      throw const FormatException('缺少 terms 字段');
    }

    final terms = termsRaw.whereType<String>().toList(growable: false);
    if (terms.isEmpty) {
      throw const FormatException('terms 列表为空');
    }

    return TermsResponse(category: categoryRaw, terms: terms);
  }

  final String category;
  final List<String> terms;
}
