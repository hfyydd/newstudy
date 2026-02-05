import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:newstudyapp/config/auth_controller.dart';
import 'package:newstudyapp/pages/auth/login_state.dart';
import 'package:newstudyapp/utils/region_detector.dart';
import 'package:newstudyapp/routes/app_routes.dart';
import 'package:newstudyapp/services/http_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// 登录页面控制器
class LoginController extends GetxController {
  final LoginState state = LoginState();
  
  AuthController get authController {
    if (Get.isRegistered<AuthController>()) {
      return Get.find<AuthController>();
    }
    return Get.put(AuthController());
  }
  
  final HttpService httpService = HttpService();

  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    // 调试：打印区域信息
    RegionDetector.debugPrintRegionInfo();
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  /// 获取 AppLocalizations 实例
  AppLocalizations? get _l10n {
    try {
      final context = Get.context;
      if (context != null) {
        return AppLocalizations.of(context);
      }
    } catch (_) {}
    return null;
  }

  /// Google 登录
  Future<void> loginWithGoogle() async {
    try {
      state.isLoading.value = true;
      state.clearError();

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        // 用户取消登录
        state.isLoading.value = false;
        return;
      }

      final GoogleSignInAuthentication authentication =
          await account.authentication;
      final String? idToken = authentication.idToken;

      if (idToken == null) {
        throw Exception('无法获取 Google ID Token');
      }

      // 调用后端登录
      final success = await authController.loginWithGoogle(idToken);
      if (success) {
        // 登录成功，跳转到主页
        Get.offAllNamed(AppRoutes.main);
      } else {
        state.errorMessage.value = _l10n?.loginFailed('') ?? '登录失败';
      }
    } catch (e) {
      debugPrint('Google 登录错误: $e');
      state.errorMessage.value = _l10n?.loginFailed(e.toString()) ?? 
          '登录失败: $e';
    } finally {
      state.isLoading.value = false;
    }
  }

  /// Apple 登录
  Future<void> loginWithApple() async {
    try {
      state.isLoading.value = true;
      state.clearError();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('无法获取 Apple ID Token');
      }

      // 调用后端登录
      final success = await authController.loginWithApple(
        idToken,
        authorizationCode: credential.authorizationCode,
      );

      if (success) {
        // 登录成功，跳转到主页
        Get.offAllNamed(AppRoutes.main);
      } else {
        state.errorMessage.value = _l10n?.loginFailed('') ?? '登录失败';
      }
    } catch (e) {
      debugPrint('Apple 登录错误: $e');
      if (e is SignInWithAppleAuthorizationException) {
        if (e.code == AuthorizationErrorCode.canceled) {
          // 用户取消登录，不显示错误
          state.isLoading.value = false;
          return;
        }
      }
      state.errorMessage.value = _l10n?.loginFailed(e.toString()) ?? 
          '登录失败: $e';
    } finally {
      state.isLoading.value = false;
    }
  }

  /// 发送邮箱验证码
  Future<void> sendEmailCode() async {
    final email = state.email.value.trim();
    if (email.isEmpty) {
      state.errorMessage.value = _l10n?.pleaseEnterEmail ?? '请输入邮箱';
      return;
    }

    // 简单的邮箱格式验证
    if (!email.contains('@') || !email.contains('.')) {
      state.errorMessage.value = _l10n?.pleaseEnterValidEmail ?? '请输入有效的邮箱地址';
      return;
    }

    try {
      state.isSendingCode.value = true;
      state.clearError();

      final success = await authController.sendEmailCode(email);
      if (success) {
        state.isCodeSent.value = true;
        _startCountdown(60); // 60秒倒计时
      } else {
        state.errorMessage.value = _l10n?.sendCodeFailed('') ?? '发送验证码失败';
      }
    } catch (e) {
      debugPrint('发送验证码错误: $e');
      state.errorMessage.value = _l10n?.sendCodeFailed(e.toString()) ?? 
          '发送验证码失败: $e';
    } finally {
      state.isSendingCode.value = false;
    }
  }

  /// 邮箱验证码登录
  Future<void> loginWithEmail() async {
    final email = state.email.value.trim();
    final code = state.verificationCode.value.trim();

    if (email.isEmpty) {
      state.errorMessage.value = _l10n?.pleaseEnterEmail ?? '请输入邮箱';
      return;
    }

    if (code.isEmpty) {
      state.errorMessage.value = _l10n?.pleaseEnterCode ?? '请输入验证码';
      return;
    }

    if (code.length != 6) {
      state.errorMessage.value = _l10n?.pleaseEnterValidCode ?? '请输入6位验证码';
      return;
    }

    try {
      state.isLoading.value = true;
      state.clearError();

      final success = await authController.loginWithEmail(email, code);
      if (success) {
        // 登录成功，跳转到主页
        Get.offAllNamed(AppRoutes.main);
      } else {
        state.errorMessage.value = _l10n?.loginFailed('') ?? '登录失败';
      }
    } catch (e) {
      debugPrint('邮箱登录错误: $e');
      state.errorMessage.value = _l10n?.loginFailed(e.toString()) ?? 
          '登录失败: $e';
    } finally {
      state.isLoading.value = false;
    }
  }

  /// 开始倒计时
  void _startCountdown(int seconds) {
    state.codeCountdown.value = seconds;
    state.canResendCode.value = false;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.codeCountdown.value > 0) {
        state.codeCountdown.value--;
      } else {
        timer.cancel();
        state.canResendCode.value = true;
      }
    });
  }

  /// 是否应该显示 Google 登录
  bool get shouldShowGoogleLogin => !RegionDetector.shouldHideGoogleSignIn;

  /// 是否应该显示 Apple 登录
  bool get shouldShowAppleLogin => Platform.isIOS || Platform.isMacOS;
}
