import 'package:newstudyapp/config/api_config.dart';

/// 应用全局配置
class AppConfig {
  AppConfig._();

  /// 后端服务地址
  static const String backendBaseUrl = apiBaseUrl;

  /// 应用标题
  static const String appTitle = '费曼学习法';
}
