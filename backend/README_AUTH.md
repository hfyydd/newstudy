# 认证功能实现说明

## 一、数据库迁移

### 1. 执行迁移脚本

运行以下 SQL 脚本扩展 `users` 表并创建 `email_verification_codes` 表：

```bash
# 使用 psql 连接数据库
psql -U your_username -d your_database -f sql/auth_migration.sql
```

或者直接在数据库中执行 `sql/auth_migration.sql` 文件。

### 2. 新增字段说明

**users 表新增字段：**
- `display_name`: 用户显示名称
- `avatar_url`: 用户头像URL
- `auth_provider`: 认证提供商（google, apple, email）
- `email_verified`: 邮箱是否已验证
- `refresh_token`: 刷新Token（加密存储）
- `refresh_token_expires_at`: 刷新Token过期时间
- `last_login_at`: 最后登录时间

**新增表：**
- `email_verification_codes`: 邮箱验证码表

## 二、安装依赖

```bash
cd backend
uv sync  # 或 pip install -r requirements.txt
```

新增的依赖包：
- `python-jose[cryptography]`: JWT Token 生成和验证
- `passlib[bcrypt]`: 密码哈希（用于未来可能的密码登录）
- `google-auth`: Google ID Token 验证（可选）
- `cryptography`: 加密相关功能

## 三、环境变量配置

在 `.env` 文件中添加以下配置：

```env
# JWT 配置（必须）
JWT_SECRET_KEY=your-secret-key-change-in-production  # 生产环境必须修改

# Google OAuth 配置（可选，用于验证 Google ID Token）
GOOGLE_CLIENT_ID=your-google-client-id

# Apple OAuth 配置（可选，用于验证 Apple ID Token）
APPLE_CLIENT_ID=your-apple-client-id
APPLE_TEAM_ID=your-apple-team-id
APPLE_KEY_ID=your-apple-key-id
```

## 四、API 接口

### 1. Google 登录
```
POST /auth/google/login
Body: { "id_token": "..." }
```

### 2. Apple 登录
```
POST /auth/apple/login
Body: { "id_token": "...", "authorization_code": "..." }
```

### 3. 发送邮箱验证码
```
POST /auth/email/send-code
Body: { "email": "user@example.com" }
```

### 4. 邮箱验证码登录
```
POST /auth/email/verify-code
Body: { "email": "user@example.com", "code": "123456" }
```

### 5. 刷新 Token
```
POST /auth/refresh
Body: { "refresh_token": "..." }
```

### 6. 登出
```
POST /auth/logout
Headers: { "Authorization": "Bearer <access_token>" }
```

### 7. 获取当前用户信息
```
GET /auth/me
Headers: { "Authorization": "Bearer <access_token>" }
```

## 五、使用认证中间件

在需要登录的 API 中使用：

```python
from auth_middleware import get_current_user, get_current_user_id

@app.get("/protected")
def protected_route(current_user: dict = Depends(get_current_user)):
    user_id = current_user["id"]
    # 使用用户信息
    ...

# 或者只获取用户ID
@app.get("/protected")
def protected_route(user_id: int = Depends(get_current_user_id)):
    # 使用用户ID
    ...
```

## 六、注意事项

### 开发环境
- Google 和 Apple 登录目前使用占位符，未实现真正的 Token 验证
- 邮箱验证码仅打印到日志，未实现真正的邮件发送
- 生产环境需要实现：
  1. Google ID Token 验证
  2. Apple ID Token 验证
  3. 邮件发送功能

### 安全建议
1. 生产环境必须修改 `JWT_SECRET_KEY`
2. 使用 HTTPS
3. 实现 Token 轮换机制
4. 添加速率限制（防止验证码暴力破解）
5. 实现邮件发送功能

## 七、已实现的功能

### ✅ 已完成
1. **数据库迁移** - 扩展 users 表，创建 email_verification_codes 表
2. **JWT Token 管理** - Access Token 和 Refresh Token 生成/验证
3. **邮箱验证码登录** - 完整的邮箱验证码发送和登录流程
4. **邮件发送功能** - 支持 SMTP 邮件发送（开发环境打印到日志）
5. **Google 登录** - 支持 Google ID Token 验证（需配置 GOOGLE_CLIENT_ID）
6. **Apple 登录** - 支持 Apple ID Token 验证（需配置 APPLE_CLIENT_ID）
7. **Token 刷新** - Refresh Token 自动刷新 Access Token
8. **用户认证中间件** - 保护需要登录的 API
9. **向后兼容** - 现有 API 支持可选认证（未认证时使用默认用户）

### ⚠️ 开发环境限制
- Google/Apple Token 验证：如果未配置 CLIENT_ID，使用占位符（仅用于开发）
- 邮件发送：如果未配置 SMTP，验证码仅打印到日志
- 现有 API：支持向后兼容，未认证时使用默认用户

### 🔒 生产环境要求
1. 配置 `JWT_SECRET_KEY`（必须）
2. 配置 SMTP 服务器（用于发送验证码邮件）
3. 配置 `GOOGLE_CLIENT_ID`（如果使用 Google 登录）
4. 配置 `APPLE_CLIENT_ID`（如果使用 Apple 登录）
5. 使用 HTTPS
6. 实现 Token 轮换机制
7. 添加速率限制

## 八、测试

### 测试邮箱登录流程

1. 发送验证码：
```bash
curl -X POST http://localhost:8000/auth/email/send-code \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

2. 查看后端日志获取验证码（开发环境）

3. 使用验证码登录：
```bash
curl -X POST http://localhost:8000/auth/email/verify-code \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "code": "123456"}'
```

4. 使用返回的 access_token 访问受保护的接口：
```bash
curl -X GET http://localhost:8000/auth/me \
  -H "Authorization: Bearer <access_token>"
```
