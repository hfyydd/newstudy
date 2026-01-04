/// API 配置 - 后端服务地址和所有接口路径
class ApiConfig {
  ApiConfig._();

  /// 后端服务基础地址
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // ==================== Agent 相关接口 ====================

  /// 好奇学生 Agent（提问获取新词汇）
  static const String curiousStudent = '/agents/curious-student';

  /// 简单解释器 Agent（获取词汇解释）
  static const String simpleExplainer = '/agents/simple-explainer';

  // ==================== Topic 相关接口 ====================

  /// 获取术语列表
  static const String fetchTerms = '/topics/terms';

  // ==================== Notes 相关接口 ====================

  /// 从笔记文本中抽取待学习词语
  static const String extractNoteTerms = '/notes/extract-terms';

  /// 从笔记文件中抽取待学习词语（multipart/form-data）
  static const String extractNoteTermsFile = '/notes/extract-terms/file';

  /// 生成智能笔记（AI生成markdown笔记+闪词列表）
  static const String generateSmartNote = '/notes/generate-smart-note';

  /// 创建笔记（生成并保存到数据库）
  static const String createNote = '/notes/create';

  /// 获取笔记列表
  static const String listNotes = '/notes/list';

  /// 获取笔记详情
  static String getNoteDetail(int noteId) => '/notes/$noteId';

  // ==================== 辅助方法 ====================

  /// 构建完整的 API URL
  static String buildUrl(String path) {
    return '$baseUrl$path';
  }
}

/// 兼容性导出（保持向后兼容）
const String apiBaseUrl = ApiConfig.baseUrl;
