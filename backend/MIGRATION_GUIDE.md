# 数据库迁移指南

## 方法一：使用 Python 脚本（推荐）✨

最简单的方式，自动从 `.env` 文件读取数据库连接信息：

```bash
cd backend
python run_migration.py
```

这个脚本会：
1. 自动读取 `.env` 文件中的 `DATABASE_URL`
2. 连接数据库
3. 执行 `sql/auth_migration.sql` 迁移脚本

## 方法二：使用 psql 命令行

如果你知道数据库连接信息，可以直接使用 `psql` 命令：

### 从 DATABASE_URL 解析参数

如果你的 `.env` 文件中有：
```
DATABASE_URL=postgresql://username:password@host:port/database
```

那么对应的 psql 命令是：

```bash
psql -h host -p port -U username -d database -f sql/auth_migration.sql
```

### 示例

假设你的 `.env` 文件中有：
```
DATABASE_URL=postgresql://newstudy:newstudy123@localhost:5433/newstudy_db
```

那么命令是：

```bash
cd backend
psql -h localhost -p 5433 -U newstudy -d newstudy_db -f sql/auth_migration.sql
```

系统会提示输入密码：`newstudy123`

### 或者使用环境变量

```bash
export PGPASSWORD=your_password
psql -h localhost -p 5433 -U newstudy -d newstudy_db -f sql/auth_migration.sql
```

## 方法三：直接在 psql 中执行

1. 连接到数据库：
```bash
psql -h localhost -p 5433 -U newstudy -d newstudy_db
```

2. 在 psql 中执行：
```sql
\i sql/auth_migration.sql
```

或者直接复制粘贴 `sql/auth_migration.sql` 的内容。

## 验证迁移是否成功

执行迁移后，可以验证：

```sql
-- 检查 users 表是否有新字段
\d users

-- 检查 email_verification_codes 表是否存在
\d email_verification_codes

-- 或者查询表结构
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name IN ('display_name', 'auth_provider', 'email_verified', 'refresh_token');
```

## 常见问题

### 1. 连接被拒绝
- 检查数据库服务是否运行
- 检查主机、端口是否正确
- 检查防火墙设置

### 2. 认证失败
- 检查用户名和密码是否正确
- 检查数据库用户是否有权限

### 3. 表已存在错误
- 迁移脚本使用了 `IF NOT EXISTS`，不会报错
- 如果字段已存在，会跳过添加

### 4. 权限不足
- 确保数据库用户有 `ALTER TABLE` 和 `CREATE TABLE` 权限
- 可能需要使用超级用户（postgres）执行

## 回滚（如果需要）

如果需要回滚迁移，可以执行：

```sql
-- 删除邮箱验证码表
DROP TABLE IF EXISTS email_verification_codes CASCADE;

-- 删除 users 表的新字段（注意：这会删除数据）
ALTER TABLE users 
DROP COLUMN IF EXISTS display_name,
DROP COLUMN IF EXISTS avatar_url,
DROP COLUMN IF EXISTS auth_provider,
DROP COLUMN IF EXISTS email_verified,
DROP COLUMN IF EXISTS refresh_token,
DROP COLUMN IF EXISTS refresh_token_expires_at,
DROP COLUMN IF EXISTS last_login_at;
```

⚠️ **警告**: 回滚会删除相关数据，请谨慎操作！
