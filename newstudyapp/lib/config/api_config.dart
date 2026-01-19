/// API 配置 - 后端服务地址和所有接口路径
class ApiConfig {
  ApiConfig._();

  /// 后端服务基础地址
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.101.30:8000',
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
  static String getNoteDetail(String noteId) => '/notes/$noteId';

  /// 获取笔记（通用方法）
  static String getNote(String noteId) => '/notes/$noteId';

  /// 更新笔记
  static String updateNote(String noteId) => '/notes/$noteId';

  /// 删除笔记
  static String deleteNote(String noteId) => '/notes/$noteId';

  /// 设置笔记默认角色
  static String setNoteDefaultRole(String noteId) => '/notes/$noteId/default-role';

  // ==================== 学习相关接口 ====================

  /// 获取学习角色列表
  static const String learningRoles = '/learning/roles';

  /// 评估用户解释
  static const String evaluateExplanation = '/learning/evaluate';

  // ==================== 闪卡相关接口 ====================

  /// 生成闪卡
  static String generateFlashCards(String noteId) =>
      '/notes/$noteId/flash-cards/generate';

  /// 获取笔记的闪卡列表
  static String getFlashCards(String noteId) => '/notes/$noteId/flash-cards';

  /// 获取笔记的闪卡列表（含状态）
  static String getFlashCardsWithStatus(String noteId) =>
      '/notes/$noteId/flash-cards/with-status';

  /// 获取闪卡学习进度
  static String getFlashCardProgress(String noteId) =>
      '/notes/$noteId/flash-cards/progress';

  /// 更新闪卡状态（批量）
  static String updateFlashCardStatus(String noteId) =>
      '/notes/$noteId/flash-cards/status';

  /// 添加混淆术语
  static String addConfusedTerms(String noteId) =>
      '/notes/$noteId/confused-terms';

  /// 更新闪词卡片状态（单个）
  static String updateCardStatus(String cardId) =>
      '/flash-cards/$cardId/status';

  /// 获取闪词卡片详情
  static String getCardDetail(String cardId) => '/flash-cards/$cardId';

  // ==================== 学习中心相关接口 ====================

  /// 获取学习中心统计数据
  static const String studyCenterStatistics = '/study-center/statistics';

  /// 获取今日复习词条列表
  static const String todayReviewCards = '/study-center/today-review';

  /// 获取复习闪卡列表
  static const String getReviewFlashCards = '/review/cards';

  /// 获取薄弱词条列表（需巩固、需改进、未掌握）
  static const String weakCards = '/study-center/weak-cards';

  /// 获取已掌握词条列表
  static const String masteredCards = '/study-center/mastered-cards';

  /// 获取全部词条列表
  static const String allCards = '/study-center/all-cards';

  /// 按笔记分类获取词条列表
  static const String cardsByNote = '/study-center/cards-by-note';

  // ==================== 首页学习统计 ====================

  /// 获取首页学习统计数据（含趋势、streak、周进度）
  static const String homeStatistics = '/home/statistics';

  /// 获取学习统计数据（掌握数、总术语数、连续天数、学习时长）
  static const String getStatistics = '/statistics';

  /// 获取今日复习统计数据（待复习数、已完成数）
  static const String getTodayReviewStatistics = '/review/today';

  // ==================== 辅助方法 ====================

  /// 构建完整的 API URL
  static String buildUrl(String path) {
    return '$baseUrl$path';
  }
}

/// 兼容性导出（保持向后兼容）
const String apiBaseUrl = ApiConfig.baseUrl;
