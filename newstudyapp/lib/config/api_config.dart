/// API 配置 - 后端服务地址和所有接口路径
class ApiConfig {
  ApiConfig._();

  /// 后端服务基础地址
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.117.18:8000',
  );

  // ==================== Agent 相关接口 ====================
  
  /// 好奇学生 Agent（提问获取新词汇）
  static const String curiousStudent = '/agents/curious-student';
  
  /// 简单解释器 Agent（获取词汇解释）
  static const String simpleExplainer = '/agents/simple-explainer';

  // ==================== Topic 相关接口 ====================
  
  /// 获取术语列表
  static const String fetchTerms = '/topics/terms';

  // ==================== 辅助方法 ====================
  
  /// 构建完整的 API URL
  static String buildUrl(String path) {
    return '$baseUrl$path';
  }
}

/// 兼容性导出（保持向后兼容）
const String apiBaseUrl = ApiConfig.baseUrl;
