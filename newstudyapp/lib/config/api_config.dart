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

  /// 从URL创建笔记
  static const String createNoteFromUrl = '/notes/create-from-url';

  /// 从图片创建笔记
  static const String createNoteFromImage = '/notes/create-from-image';

  /// 从YouTube创建笔记
  static const String createNoteFromYoutube = '/notes/create-from-youtube';

  /// 从Bilibili创建笔记
  static const String createNoteFromBilibili = '/notes/create-from-bilibili';

  /// 从PDF创建笔记
  static const String createNoteFromPdf = '/notes/create-from-pdf';

  /// 获取笔记列表
  static const String listNotes = '/notes/list';

  /// 获取笔记详情
  static String getNoteDetail(int noteId) => '/notes/$noteId';

  /// 设置笔记默认角色
  static String setNoteDefaultRole(int noteId) => '/notes/$noteId/default-role';

  // ==================== 学习相关接口 ====================

  /// 获取学习角色列表
  static const String learningRoles = '/learning/roles';

  /// 评估用户解释
  static const String evaluateExplanation = '/learning/evaluate';

  /// 更新闪词卡片状态
  static String updateCardStatus(int cardId) => '/flash-cards/$cardId/status';

  /// 获取闪词卡片详情
  static String getCardDetail(int cardId) => '/flash-cards/$cardId';

  // ==================== 学习中心相关接口 ====================

  /// 获取学习中心统计数据
  static const String studyCenterStatistics = '/study-center/statistics';

  /// 获取今日复习闪词列表
  static const String todayReviewCards = '/study-center/today-review';

  /// 获取薄弱闪词列表（需巩固、需改进、未掌握）
  static const String weakCards = '/study-center/weak-cards';

  /// 获取已掌握闪词列表
  static const String masteredCards = '/study-center/mastered-cards';

  /// 获取全部闪词列表
  static const String allCards = '/study-center/all-cards';

  /// 按笔记分类获取闪词列表
  static const String cardsByNote = '/study-center/cards-by-note';

  // ==================== 首页学习统计 ====================

  /// 获取首页学习统计数据（含趋势、streak、周进度）
  static const String homeStatistics = '/home/statistics';

  // ==================== 认证相关接口 ====================

  /// Google 登录
  static const String googleLogin = '/auth/google/login';

  /// Apple 登录
  static const String appleLogin = '/auth/apple/login';

  /// 发送邮箱验证码
  static const String sendEmailCode = '/auth/email/send-code';

  /// 邮箱验证码登录
  static const String emailLogin = '/auth/email/verify-code';

  /// 刷新 Token
  static const String refreshToken = '/auth/refresh';

  /// 登出
  static const String logout = '/auth/logout';

  /// 获取当前用户信息
  static const String getCurrentUser = '/auth/me';

  // ==================== 辅助方法 ====================

  /// 构建完整的 API URL
  static String buildUrl(String path) {
    return '$baseUrl$path';
  }
}

/// 兼容性导出（保持向后兼容）
const String apiBaseUrl = ApiConfig.baseUrl;
