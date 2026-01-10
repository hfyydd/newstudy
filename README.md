# NewStudy 项目

一个集成了 AI 智能学习助手的前后端分离应用，支持Docker部署和PostgreSQL数据库。

## 项目结构

```
.
├── backend/          # Python FastAPI 后端服务
│   ├── Dockerfile          # Docker镜像构建文件
│   ├── docker-compose.yml   # Docker Compose配置
│   ├── init.sql           # PostgreSQL初始化脚本
│   └── database_async.py   # PostgreSQL异步数据库实现
└── newstudyapp/      # Flutter 前端应用
```

## 技术栈

- **后端**: FastAPI + Python 3.13+ + LangChain + PostgreSQL
- **前端**: Flutter 3.4.0+
- **数据库**: PostgreSQL 16
- **容器化**: Docker + Docker Compose
- **包管理**:
  - 后端: `uv`
  - 前端: `flutter pub`

## 环境要求

### 后端
- Python >= 3.13
- [uv](https://github.com/astral-sh/uv) (Python 包管理器)

### 前端
- Flutter SDK >= 3.4.0
- Dart SDK >= 3.4.0

## 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd newstudy
```

### 2. Docker部署（推荐）

#### 2.1 环境配置

复制环境变量模板文件：

```bash
cp backend/.env.example backend/.env
```

编辑 `backend/.env` 文件：

```env
# AI配置
BASE_URL=https://api.moonshot.cn/v1
API_KEY=your-api-key-here
MODEL=kimi-k2-turbo-preview

# 数据库配置
DATABASE_URL=postgresql+asyncpg://newstudy_user:newstudy_password@localhost:5432/newstudy
```

#### 2.2 启动Docker服务

```bash
cd backend
docker-compose up -d
```

这将启动：
- PostgreSQL数据库（端口5432）
- FastAPI后端（端口8000）
- Redis缓存（端口6379）

#### 2.3 验证服务

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 测试API
curl http://localhost:8000/docs
```

### 3. 本地开发部署

#### 3.1 后端部署

安装依赖：

```bash
cd backend
uv sync
```

配置环境变量（同Docker部署）

启动后端服务：

```bash
# 使用 uv 运行
uv run uvicorn server:app --reload --host 0.0.0.0 --port 8000
```

#### 3.2 验证后端服务

访问 API 文档：
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

### 3. 前端部署

#### 3.1 安装依赖

```bash
cd newstudyapp
flutter pub get
```

#### 3.2 配置 API 地址（可选）

默认情况下，前端会连接到 `http://localhost:8000`。如果需要修改 API 地址：

**方法 1**: 通过环境变量运行
```bash
flutter run --dart-define=API_BASE_URL=http://your-backend-url:8000
```

**方法 2**: 修改 `lib/config/api_config.dart` 文件

#### 3.3 运行应用

```bash
# 开发模式运行
flutter run

# 指定设备运行
flutter devices                    # 查看可用设备
flutter run -d <device-id>        # 在指定设备运行

# Web 平台
flutter run -d chrome

# 生产构建
flutter build apk                 # Android APK
flutter build ios                 # iOS
flutter build web                 # Web
```

#### 3.4 平台特定说明

**Android**:
```bash
cd android
./gradlew build
```

**iOS** (需要 macOS):
```bash
cd ios
pod install
```

## API 接口

### 智能助手接口

- `POST /agents/curious-student` - 好奇学生助手
- `POST /agents/simple-explainer` - 简单解释助手

**请求示例**:
```bash
curl -X POST "http://localhost:8000/agents/curious-student" \
  -H "Content-Type: application/json" \
  -d '{"text": "什么是人工智能？"}'
```

### 术语库接口

- `GET /topics/terms?category=economics` - 获取术语列表

## 开发说明

### 后端开发

项目使用 `uv` 管理依赖和虚拟环境：

```bash
# 添加新依赖
uv add package-name

# 移除依赖
uv remove package-name

# 更新依赖
uv sync --upgrade
```

### 前端开发

项目使用 Flutter 标准包管理：

```bash
# 添加依赖
flutter pub add package-name

# 更新依赖
flutter pub upgrade

# 运行测试
flutter test
```

## 常见问题

### 后端问题

**Q: 启动时提示找不到 dotenv 模块**
```bash
cd backend
uv sync
```

**Q: API key 未设置错误**
- 确保 `.env` 文件存在于 `backend/` 目录
- 检查 `.env` 文件中的 `API_KEY` 是否正确配置

### 前端问题

**Q: 无法连接到后端 API**
- 确认后端服务已启动并运行在 `http://localhost:8000`
- 检查防火墙设置
- 如果是真机调试，确保手机和电脑在同一网络，并使用电脑的局域网 IP 地址

**Q: Flutter 版本不匹配**
```bash
flutter doctor
flutter upgrade
```

## 安全说明

- ⚠️ **不要**将 `.env` 文件提交到 Git
- ⚠️ **不要**在代码中硬编码 API key
- ✅ 使用 `.env.example` 作为配置模板
- ✅ 在生产环境中使用安全的密钥管理服务

## 生产部署

### Docker生产部署（推荐）

#### 1. 创建生产配置

```bash
# 复制生产环境配置
cp backend/docker-compose.yml backend/docker-compose.prod.yml
```

#### 2. 配置生产环境变量

创建 `.env.prod` 文件：

```env
API_KEY=your-production-api-key
DB_USER=your_db_user
DB_PASSWORD=your_secure_password
BASE_URL=https://api.moonshot.cn/v1
MODEL=kimi-k2-turbo-preview
```

#### 3. 启动生产服务

```bash
cd backend
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

### 传统部署

```bash
# 使用 gunicorn 作为 WSGI 服务器
pip install gunicorn
gunicorn server:app -w 4 -k uvicorn.workers.UvicornWorker
```

### 数据库迁移

从SQLite迁移到PostgreSQL：

```bash
cd backend
uv run python migrate_to_postgresql.py
```

数据备份和恢复：

```bash
# 备份数据库
uv run python backup_restore.py backup

# 恢复数据库
uv run python backup_restore.py restore
```

### 前端生产构建

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

[在此添加许可证信息]

