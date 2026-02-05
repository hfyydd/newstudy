import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/auth/login_controller.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginController controller;
  late final TextEditingController emailController;
  late final TextEditingController codeController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LoginController());
    emailController = TextEditingController();
    codeController = TextEditingController();
    
    // 绑定响应式更新
    ever(controller.state.email, (value) {
      if (emailController.text != value) {
        emailController.text = value;
      }
    });
    ever(controller.state.verificationCode, (value) {
      if (codeController.text != value) {
        codeController.text = value;
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Logo/App Name
              _buildHeader(isDark),
              
              const SizedBox(height: 60),
              
              // 第三方登录按钮
              _buildThirdPartyLogin(controller, isDark, l10n),
              
              const SizedBox(height: 32),
              
              // 分隔线
              _buildDivider(isDark, l10n),
              
              const SizedBox(height: 32),
              
              // 邮箱登录
              _buildEmailLogin(controller, isDark, l10n),
              
              const SizedBox(height: 40),
              
              // 隐私政策和服务条款
              _buildFooter(l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建头部（Logo/App Name）
  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // 可以在这里添加 Logo
        Icon(
          Icons.school_rounded,
          size: 80,
          color: AppTheme.darkPrimary,
        ),
        const SizedBox(height: 16),
        Text(
          'FlashMind',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Learn smarter, not harder',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 构建第三方登录按钮
  Widget _buildThirdPartyLogin(
    LoginController controller,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Obx(() {
      if (controller.state.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      return Column(
        children: [
          // Google 登录（中国区域隐藏）
          if (controller.shouldShowGoogleLogin)
            _buildSocialLoginButton(
              icon: Icons.g_mobiledata,
              label: l10n.googleLogin,
              color: Colors.white,
              textColor: Colors.black87,
              onTap: controller.loginWithGoogle,
              isDark: isDark,
            ),
          
          if (controller.shouldShowGoogleLogin) const SizedBox(height: 16),
          
          // Apple 登录（仅 iOS/macOS）
          if (controller.shouldShowAppleLogin)
            _buildSocialLoginButton(
              icon: Icons.apple,
              label: l10n.appleLogin,
              color: isDark ? Colors.white : Colors.black,
              textColor: isDark ? Colors.black : Colors.white,
              onTap: controller.loginWithApple,
              isDark: isDark,
            ),
        ],
      );
    });
  }

  /// 构建社交登录按钮
  Widget _buildSocialLoginButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建分隔线
  Widget _buildDivider(bool isDark, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.or,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
        ),
      ],
    );
  }

  /// 构建邮箱登录
  Widget _buildEmailLogin(
    LoginController controller,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.emailLogin,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        
        // 邮箱输入框
        TextField(
          controller: emailController,
          onChanged: (value) => controller.state.email.value = value,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.enterEmail,
            hintText: l10n.enterEmail,
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
          ),
        ),
        const SizedBox(height: 16),
        
        // 发送验证码按钮
        Obx(() {
          final isCodeSent = controller.state.isCodeSent.value;
          final isSending = controller.state.isSendingCode.value;
          final countdown = controller.state.codeCountdown.value;
          final canResend = controller.state.canResendCode.value;

          if (!isCodeSent) {
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSending ? null : controller.sendEmailCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(l10n.sendCode),
              ),
            );
          }

          // 验证码输入框
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: codeController,
                      onChanged: (value) =>
                          controller.state.verificationCode.value = value,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: l10n.enterCode,
                        hintText: '000000',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextButton(
                      onPressed: canResend ? controller.sendEmailCode : null,
                      child: Text(
                        canResend
                            ? l10n.resendCode
                            : l10n.codeCountdown(countdown),
                        style: TextStyle(
                          color: canResend
                              ? AppTheme.darkPrimary
                              : (isDark ? Colors.grey[600] : Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.loginWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Obx(() {
                    if (controller.state.isLoading.value) {
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    }
                    return Text(l10n.loginButton);
                  }),
                ),
              ),
            ],
          );
        }),
        
        // 错误提示
        Obx(() {
          final error = controller.state.errorMessage.value;
          if (error == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error,
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 构建页脚（隐私政策和服务条款）
  Widget _buildFooter(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            // TODO: 打开隐私政策页面
          },
          child: Text(
            l10n.privacyPolicy,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const Text(' | ', style: TextStyle(fontSize: 12)),
        TextButton(
          onPressed: () {
            // TODO: 打开服务条款页面
          },
          child: Text(
            l10n.termsOfService,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
