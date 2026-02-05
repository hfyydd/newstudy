/// 认证相关数据模型

/// 用户信息模型
class User {
  final int id;
  final String? email;
  final String? displayName;
  final String? avatarUrl;
  final String authProvider; // 'google', 'apple', 'email'
  final bool emailVerified;

  User({
    required this.id,
    this.email,
    this.displayName,
    this.avatarUrl,
    required this.authProvider,
    this.emailVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String?,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      authProvider: json['auth_provider'] as String? ?? 'email',
      emailVerified: json['email_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'auth_provider': authProvider,
      'email_verified': emailVerified,
    };
  }
}

/// 登录响应模型
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime tokenExpiresAt;
  final User user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenExpiresAt,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenExpiresAt: DateTime.parse(json['token_expires_at'] as String),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// 刷新 Token 响应模型
class RefreshTokenResponse {
  final String accessToken;
  final String? refreshToken; // 可选，可能复用旧的
  final DateTime tokenExpiresAt;

  RefreshTokenResponse({
    required this.accessToken,
    this.refreshToken,
    required this.tokenExpiresAt,
  });

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      tokenExpiresAt: DateTime.parse(json['token_expires_at'] as String),
    );
  }
}

/// 发送验证码响应模型
class SendCodeResponse {
  final bool success;
  final String message;
  final int expiresIn; // 秒

  SendCodeResponse({
    required this.success,
    required this.message,
    required this.expiresIn,
  });

  factory SendCodeResponse.fromJson(Map<String, dynamic> json) {
    return SendCodeResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }
}
