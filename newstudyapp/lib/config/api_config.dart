/// API 配置 - 后端服务地址和所有接口路径
class ApiConfig {
  ApiConfig._();

  /// 后端服务基础地址
  ///
  /// 注意：在 HarmonyOS 设备上，需要使用本机的局域网 IP 地址而不是 127.0.0.1
  /// 如果 IP 地址发生变化，可以通过 --dart-define=API_BASE_URL=http://192.168.x.x:8000 来设置
  ///
  /// 获取本机 IP 地址的命令：
  /// macOS/Linux: ifconfig | grep "inet " | grep -v 127.0.0.1
  /// Windows: ipconfig
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.105:8000',
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

  /// 获取笔记列表
  static const String listNotes = '/notes';

  /// 创建笔记
  static const String createNote = '/notes';

  /// 获取笔记详情
  static String getNote(String noteId) => '/notes/$noteId';

  /// 更新笔记
  static String updateNote(String noteId) => '/notes/$noteId';

  /// 删除笔记
  static String deleteNote(String noteId) => '/notes/$noteId';

  /// 生成闪词卡片
  static String generateFlashCards(String noteId) =>
      '/notes/$noteId/flash-cards/generate';

  /// 获取闪词卡片列表
  static String getFlashCards(String noteId) => '/notes/$noteId/flash-cards';

  /// 获取闪词学习进度
  static String getFlashCardProgress(String noteId) =>
      '/notes/$noteId/flash-cards/progress';

  /// 更新闪词卡片状态
  static String updateFlashCardStatus(String noteId) =>
      '/notes/$noteId/flash-cards/status';

  /// 获取学习统计
  static const String getStatistics = '/statistics';

  /// 获取今日复习统计
  static const String getTodayReviewStatistics = '/review/today';

  /// 获取需要复习的闪词卡片列表
  static const String getReviewFlashCards = '/review/cards';

  // ==================== 辅助方法 ====================

  /// 构建完整的 API URL
  static String buildUrl(String path) {
    return '$baseUrl$path';
  }
}

/// 兼容性导出（保持向后兼容）
const String apiBaseUrl = ApiConfig.baseUrl;
