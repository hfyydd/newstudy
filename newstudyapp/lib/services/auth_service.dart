import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:newstudyapp/models/auth_models.dart';

/// 认证服务
/// 负责 Token 的存储、读取和管理
class AuthService {
  static const AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  const AuthService._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Token 存储键名
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyTokenExpiresAt = 'token_expires_at';
  static const String _keyUserInfo = 'user_info';

  /// 保存 Token
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _keyAccessToken, value: accessToken),
        _storage.write(key: _keyRefreshToken, value: refreshToken),
        _storage.write(
          key: _keyTokenExpiresAt,
          value: expiresAt.toIso8601String(),
        ),
      ]);
    } catch (e) {
      throw Exception('保存 Token 失败: $e');
    }
  }

  /// 获取 Access Token
  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (e) {
      return null;
    }
  }

  /// 获取 Refresh Token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e) {
      return null;
    }
  }

  /// 获取 Token 过期时间
  Future<DateTime?> getTokenExpiresAt() async {
    try {
      final expiresAtStr = await _storage.read(key: _keyTokenExpiresAt);
      if (expiresAtStr == null) return null;
      return DateTime.parse(expiresAtStr);
    } catch (e) {
      return null;
    }
  }

  /// 检查 Token 是否过期
  Future<bool> isTokenExpired() async {
    final expiresAt = await getTokenExpiresAt();
    if (expiresAt == null) return true;
    return DateTime.now().isAfter(expiresAt);
  }

  /// 保存用户信息
  Future<void> saveUserInfo(User user) async {
    try {
      // 将用户信息转换为 JSON 字符串存储
      final userJson = user.toJson();
      final userStr = jsonEncode(userJson);
      await _storage.write(key: _keyUserInfo, value: userStr);
    } catch (e) {
      // 忽略错误，用户信息不是关键数据
    }
  }

  /// 获取用户信息
  Future<User?> getUserInfo() async {
    try {
      final userStr = await _storage.read(key: _keyUserInfo);
      if (userStr == null) return null;
      final userJson = jsonDecode(userStr) as Map<String, dynamic>;
      return User.fromJson(userJson);
    } catch (e) {
      return null;
    }
  }

  /// 清除所有 Token 和用户信息
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyAccessToken),
        _storage.delete(key: _keyRefreshToken),
        _storage.delete(key: _keyTokenExpiresAt),
        _storage.delete(key: _keyUserInfo),
      ]);
    } catch (e) {
      // 忽略错误，继续清除
    }
  }

  /// 检查是否有有效的 Refresh Token
  Future<bool> hasValidRefreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }
    // 可以进一步验证 Refresh Token 是否过期
    // 这里简化处理，假设 Refresh Token 长期有效
    return true;
  }
}
