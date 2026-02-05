import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/models/auth_models.dart';
import 'package:newstudyapp/services/auth_service.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:newstudyapp/config/api_config.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:dio/dio.dart';

/// 全局认证状态控制器
/// 管理用户登录状态、Token、用户信息等
class AuthController extends GetxController {
  static AuthController get to => Get.find();

  // 登录状态
  final isAuthenticated = false.obs;
  
  // 当前用户信息
  final currentUser = Rxn<User>();
  
  // Token
  final accessToken = Rxn<String>();
  final refreshToken = Rxn<String>();
  
  // 加载状态
  final isLoading = false.obs;
  final isRefreshing = false.obs;

  final AuthService _authService = AuthService();
  final HttpService _httpService = HttpService();

  @override
  void onInit() {
    super.onInit();
    // 启动时检查登录状态
    checkAuthStatus();
  }

  /// 检查认证状态（启动时调用）
  Future<void> checkAuthStatus() async {
    isLoading.value = true;
    try {
      // 1. 检查本地是否有 Refresh Token
      final storedRefreshToken = await _authService.getRefreshToken();
      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        isAuthenticated.value = false;
        return;
      }

      // 2. 检查 Access Token 是否过期
      final isExpired = await _authService.isTokenExpired();
      if (isExpired) {
        // Token 过期，尝试刷新
        final success = await refreshAccessToken();
        if (!success) {
          isAuthenticated.value = false;
          return;
        }
      } else {
        // Token 未过期，直接使用
        accessToken.value = await _authService.getAccessToken();
      }

      // 3. 获取用户信息
      await loadUserInfo();
      isAuthenticated.value = true;
      
      // 4. 如果当前在登录页，自动跳转到主页
      if (Get.currentRoute == AppRoutes.login) {
        Future.microtask(() {
          Get.offAllNamed(AppRoutes.main);
        });
      }
    } catch (e) {
      debugPrint('检查认证状态失败: $e');
      await _authService.clearTokens();
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 加载用户信息
  Future<void> loadUserInfo() async {
    try {
      final token = accessToken.value;
      if (token == null || token.isEmpty) {
        debugPrint('Access Token 为空，无法加载用户信息');
        return;
      }

      final response = await _httpService.dio.get(
        ApiConfig.getCurrentUser,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        currentUser.value = User.fromJson(response.data as Map<String, dynamic>);
        // 保存用户信息到本地
        await _authService.saveUserInfo(currentUser.value!);
      }
    } catch (e) {
      debugPrint('加载用户信息失败: $e');
      // 忽略错误，不影响登录状态
    }
  }

  /// Google 登录
  Future<bool> loginWithGoogle(String idToken) async {
    try {
      isLoading.value = true;
      final response = await _httpService.dio.post(
        ApiConfig.googleLogin,
        data: {'id_token': idToken},
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        await _handleLoginSuccess(loginResponse);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Google 登录失败: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Apple 登录
  Future<bool> loginWithApple(String idToken, {String? authorizationCode}) async {
    try {
      isLoading.value = true;
      final data = <String, dynamic>{
        'id_token': idToken,
      };
      if (authorizationCode != null) {
        data['authorization_code'] = authorizationCode;
      }

      final response = await _httpService.dio.post(
        ApiConfig.appleLogin,
        data: data,
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        await _handleLoginSuccess(loginResponse);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Apple 登录失败: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 发送邮箱验证码
  Future<bool> sendEmailCode(String email) async {
    try {
      final response = await _httpService.dio.post(
        ApiConfig.sendEmailCode,
        data: {'email': email},
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('发送邮箱验证码失败: $e');
      return false;
    }
  }

  /// 邮箱验证码登录
  Future<bool> loginWithEmail(String email, String code) async {
    try {
      isLoading.value = true;
      final response = await _httpService.dio.post(
        ApiConfig.emailLogin,
        data: {
          'email': email,
          'code': code,
        },
      );

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        await _handleLoginSuccess(loginResponse);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('邮箱登录失败: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// 处理登录成功
  Future<void> _handleLoginSuccess(LoginResponse loginResponse) async {
    // 保存 Token
    accessToken.value = loginResponse.accessToken;
    refreshToken.value = loginResponse.refreshToken;
    await _authService.saveTokens(
      accessToken: loginResponse.accessToken,
      refreshToken: loginResponse.refreshToken,
      expiresAt: loginResponse.tokenExpiresAt,
    );

    // 保存用户信息
    currentUser.value = loginResponse.user;
    await _authService.saveUserInfo(loginResponse.user);

    // 更新登录状态
    isAuthenticated.value = true;
  }

  /// 刷新 Access Token
  Future<bool> refreshAccessToken() async {
    if (isRefreshing.value) {
      // 正在刷新，等待
      return false;
    }

    try {
      isRefreshing.value = true;
      final storedRefreshToken = await _authService.getRefreshToken();
      if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
        return false;
      }

      final response = await _httpService.dio.post(
        ApiConfig.refreshToken,
        data: {'refresh_token': storedRefreshToken},
      );

      if (response.statusCode == 200) {
        final refreshResponse = RefreshTokenResponse.fromJson(
          response.data as Map<String, dynamic>,
        );

        // 更新 Token
        accessToken.value = refreshResponse.accessToken;
        if (refreshResponse.refreshToken != null) {
          refreshToken.value = refreshResponse.refreshToken;
        }

        await _authService.saveTokens(
          accessToken: refreshResponse.accessToken,
          refreshToken: refreshResponse.refreshToken ?? storedRefreshToken,
          expiresAt: refreshResponse.tokenExpiresAt,
        );

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('刷新 Token 失败: $e');
      return false;
    } finally {
      isRefreshing.value = false;
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      // 调用后端登出接口（可选）
      if (accessToken.value != null) {
        try {
          await _httpService.dio.post(
            ApiConfig.logout,
            options: Options(
              headers: {
                'Authorization': 'Bearer ${accessToken.value}',
              },
            ),
          );
        } catch (e) {
          // 忽略登出接口错误
          debugPrint('登出接口调用失败: $e');
        }
      }

      // 清除本地 Token 和用户信息
      await _authService.clearTokens();
      
      // 清除状态
      accessToken.value = null;
      refreshToken.value = null;
      currentUser.value = null;
      isAuthenticated.value = false;
    } catch (e) {
      debugPrint('登出失败: $e');
    }
  }

  /// 清除认证信息（用于强制登出）
  Future<void> clearAuth() async {
    await _authService.clearTokens();
    accessToken.value = null;
    refreshToken.value = null;
    currentUser.value = null;
    isAuthenticated.value = false;
  }
}
