import 'package:get/get.dart';

/// 登录页面状态
class LoginState {
  // 邮箱登录相关
  final email = ''.obs;
  final verificationCode = ''.obs;
  final isCodeSent = false.obs;
  final codeCountdown = 0.obs; // 倒计时秒数
  final canResendCode = true.obs;

  // 加载状态
  final isLoading = false.obs;
  final isSendingCode = false.obs;

  // 错误信息
  final errorMessage = Rxn<String>();

  /// 重置邮箱登录状态
  void resetEmailLogin() {
    email.value = '';
    verificationCode.value = '';
    isCodeSent.value = false;
    codeCountdown.value = 0;
    canResendCode.value = true;
    errorMessage.value = null;
  }

  /// 开始倒计时
  void startCountdown(int seconds) {
    codeCountdown.value = seconds;
    canResendCode.value = false;
    
    // 简单的倒计时实现（实际应该使用 Timer）
    // 这里简化处理，实际应该在 Controller 中使用 Timer
  }

  /// 清除错误信息
  void clearError() {
    errorMessage.value = null;
  }
}
