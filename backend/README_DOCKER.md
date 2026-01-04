# Docker 使用指南

## 快速开始

### 1. 启动 PostgreSQL 数据库

```bash
# 启动 PostgreSQL（后台运行）
docker compose up -d postgres

# 查看运行状态
docker compose ps

# 查看日志
docker compose logs -f postgres
```

### 2. 配置环境变量

复制环境变量示例文件：

```bash
cp env.example .env
```

编辑 `.env` 文件，填入你的 API Key：

```env
API_KEY=your_actual_api_key_here
BASE_URL=https://api.moonshot.cn/v1
MODEL=kimi-k2-turbo-preview
DATABASE_URL=postgresql://newstudy:newstudy123@localhost:5432/newstudy_db
```

### 3. 在 PyCharm 中调试

1. **启动 PostgreSQL**（如果还没启动）：
   ```bash
   docker compose up -d postgres
   ```

2. **配置 PyCharm Run Configuration**：
   - Run → Edit Configurations...
   - 点击 + → Python
   - Script path: 选择 `server.py`
   - Working directory: 选择 `backend` 目录
   - Environment variables: 从 `.env` 文件加载（或手动设置）

3. **设置断点并开始调试**

### 4. 停止服务

```bash
# 停止 PostgreSQL
docker compose down

# 停止并删除数据卷（清空数据库）
docker compose down -v
```

## 数据库连接信息

- **Host**: localhost
- **Port**: 5432
- **Database**: newstudy_db
- **Username**: newstudy
- **Password**: newstudy123

## 常用命令

```bash
# 启动服务
docker compose up -d postgres

# 查看日志
docker compose logs -f postgres

# 停止服务
docker compose down

# 进入数据库容器
docker compose exec postgres psql -U newstudy -d newstudy_db

# 查看数据库表
docker compose exec postgres psql -U newstudy -d newstudy_db -c "\dt"

# 重启服务
docker compose restart postgres
```

## 在 PyCharm 中连接数据库

1. View → Tool Windows → Database
2. 点击 + → Data Source → PostgreSQL
3. 配置连接：
   - Host: localhost
   - Port: 5432
   - Database: newstudy_db
   - User: newstudy
   - Password: newstudy123
4. Test Connection → OK

## 故障排查

### 端口被占用

```bash
# Mac/Linux
lsof -i :5432

# 如果端口被占用，可以修改 docker-compose.yml 中的端口映射
# 例如改为 "5433:5432"
```

### 数据库连接失败

1. 检查 PostgreSQL 是否运行：`docker compose ps`
2. 检查日志：`docker compose logs postgres`
3. 验证连接：`docker compose exec postgres pg_isready -U newstudy`

