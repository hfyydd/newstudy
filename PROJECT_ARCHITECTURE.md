# NewStudy 鸿蒙App项目架构文档

## 项目概述

NewStudy 是一个基于费曼学习法的智能学习应用，采用前后端分离架构：
- **前端**: Flutter 社区版开发，支持鸿蒙OS
- **后端**: Python FastAPI + AI服务集成
- **核心功能**: AI驱动的闪词学习、笔记管理、智能问答

---

## 技术栈

### 前端 (Flutter)
- **框架**: Flutter 3.4.0+ (Dart 3.4.0+)
- **状态管理**: GetX
- **网络请求**: Dio
- **UI组件**: Material Design
- **平台支持**: Android, iOS, Web, 鸿蒙OS (ohos)

### 后端 (Python)
- **框架**: FastAPI
- **Python版本**: >=3.13
- **包管理**: uv
- **数据库**: SQLite
- **AI集成**: LangChain + Moonshot API (Kimi)

### 关键依赖
```python
# 后端主要依赖
fastapi>=0.121.1
langchain-openai>=1.0.2
langgraph>=1.0.3
openai>=1.0
pypdf>=6.0.0
python-docx>=1.1.2
uvicorn>=0.38.0
```

```yaml
# 前端主要依赖
dio: ^5.4.0
get: ^4.6.6
file_picker: ^8.1.7
image_picker: ^1.1.2
flutter_sound: ^9.2.13
```

---

## 项目结构

```
newstudy/
├── backend/                    # Python FastAPI 后端
│   ├── server.py              # 主服务器文件
│   ├── database.py            # SQLite 数据库操作
│   ├── curious_student_agent.py    # AI智能问答代理
│   ├── simple_explainer_agent.py   # AI简单解释代理
│   ├── note_terms_extractor.py     # 笔记词条提取
│   ├── file_text_extractor.py      # 文件文本提取
│   ├── terms_generator.py          # 术语生成器
│   ├── config.py             # 配置管理
│   ├── llm.py                # LLM接口封装
│   └── notes.db              # SQLite数据库文件
│
├── newstudyapp/              # Flutter 前端应用
│   ├── lib/
│   │   ├── app/             # 应用配置
│   │   ├── config/          # 配置文件
│   │   │   ├── api_config.dart     # API接口配置
│   │   │   ├── app_config.dart     # 应用配置
│   │   │   └── theme_controller.dart # 主题控制
│   │   ├── models/          # 数据模型
│   │   │   ├── agent_models.dart   # AI代理模型
│   │   │   └── note_models.dart    # 笔记模型
│   │   ├── pages/           # 页面组件
│   │   │   ├── home/         # 主页
│   │   │   ├── create_note/  # 创建笔记
│   │   │   ├── note_detail/  # 笔记详情
│   │   │   ├── feynman_card/ # 费曼卡片
│   │   │   ├── review/       # 复习页面
│   │   │   └── ...
│   │   ├── routes/          # 路由配置
│   │   ├── services/        # 服务层
│   │   ├── utils/           # 工具类
│   │   └── widgets/         # 通用组件
│   ├── pubspec.yaml         # 依赖配置
│   └── ohos/               # 鸿蒙OS配置
│
└── 文档/                    # 项目文档
    ├── README.md
    ├── 闪词学习产品文档.md
    ├── API_IMPLEMENTATION.md
    └── DATABASE.md
```

---

## 核心功能模块

### 1. AI智能问答系统
- **好奇学生Agent**: 生成学习问题和提取新词汇
- **简单解释Agent**: 提供概念解释和定义
- **集成**: Moonshot API (Kimi) + LangChain

### 2. 笔记管理系统
- **创建笔记**: 支持文本和文件上传
- **笔记管理**: 增删改查功能
- **词条提取**: AI自动提取核心概念
- **闪词生成**: 从笔记内容生成学习卡片

### 3. 费曼学习法
- **闪词卡片**: 基于提取词条的学习卡片
- **学习状态**: notStarted, needsReview, needsImprove, mastered
- **进度跟踪**: 实时学习统计
- **复习系统**: 间隔重复算法

### 4. 文件处理
- **支持格式**: PDF, DOCX, 图片 (OCR)
- **文本提取**: 自动提取文件内容
- **词条识别**: 从文件内容提取学习术语

---

## 数据库设计

### SQLite 表结构

#### notes 表
```sql
CREATE TABLE notes (
    id TEXT PRIMARY KEY,           -- UUID
    title TEXT,                    -- 笔记标题(可选)
    content TEXT NOT NULL,         -- 笔记内容
    created_at TEXT NOT NULL,      -- 创建时间(ISO 8601)
    updated_at TEXT NOT NULL       -- 更新时间(ISO 8601)
);
```

#### flash_cards 表
```sql
CREATE TABLE flash_cards (
    id TEXT PRIMARY KEY,           -- UUID
    note_id TEXT NOT NULL,         -- 关联笔记ID
    term TEXT NOT NULL,            -- 词条内容
    status TEXT NOT NULL,          -- 学习状态
    created_at TEXT NOT NULL,      -- 创建时间
    last_reviewed_at TEXT,         -- 最后复习时间
    FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
    UNIQUE(note_id, term)          -- 同一笔记中词条不重复
);
```

### 索引
- `idx_flash_cards_note_id`: 提高按笔记ID查询性能
- `idx_flash_cards_status`: 提高按状态查询性能

---

## API接口设计

### 基础配置
- **Base URL**: `http://192.168.1.105:8000` (可通过环境变量配置)
- **CORS**: 支持跨域访问
- **文档**: Swagger UI (`/docs`), ReDoc (`/redoc`)

### 主要接口

#### AI代理接口
```http
POST /agents/curious-student     # 好奇学生问答
POST /agents/simple-explainer    # 简单解释器
```

#### 笔记管理接口
```http
GET    /notes                    # 获取笔记列表
POST   /notes                    # 创建笔记
GET    /notes/{id}               # 获取笔记详情
PUT    /notes/{id}               # 更新笔记
DELETE /notes/{id}               # 删除笔记
```

#### 闪词卡片接口
```http
POST /notes/{id}/flash-cards/generate    # 生成闪词卡片
GET  /notes/{id}/flash-cards              # 获取卡片列表
GET  /notes/{id}/flash-cards/progress     # 学习进度
PUT  /notes/{id}/flash-cards/status       # 更新卡片状态
```

#### 词条提取接口
```http
POST /notes/extract-terms         # 从文本提取词条
POST /notes/extract-terms/file    # 从文件提取词条
```

---

## 前端架构模式

### GetX 状态管理
每个页面遵循标准的三层结构：
```
pages/{page_name}/
├── {page_name}_controller.dart   # 控制器(业务逻辑)
├── {page_name}_page.dart         # 页面组件(UI渲染)
└── {page_name}_state.dart        # 状态管理(数据状态)
```

### 路由管理
- 使用GetX路由系统
- 支持页面跳转和参数传递
- 统一的页面导航管理

### 服务层架构
- **API服务**: 封装网络请求
- **数据服务**: 本地数据管理
- **工具服务**: 通用功能函数

---

## 部署配置

### 后端部署
```bash
# 安装依赖
cd backend
uv sync

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件设置 API_KEY

# 启动服务
uv run uvicorn server:app --reload --host 0.0.0.0 --port 8000
```

### 前端部署
```bash
# 安装依赖
cd newstudyapp
flutter pub get

# 运行应用
flutter run

# 构建应用
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web
```

### 鸿蒙OS支持
- 项目包含 `ohos/` 目录配置
- 支持鸿蒙OS设备部署
- API地址需要配置为局域网IP

---

## 开发规范

### 代码规范
- **Dart**: 遵循 `analysis_options.yaml` 配置
- **Python**: 使用 `uv` 管理依赖和虚拟环境
- **命名**: 遵循各语言标准命名约定

### Git规范
- `.gitignore`: 排除敏感文件和构建产物
- 数据库文件 `notes.db` 不提交到版本控制
- 环境配置 `.env` 文件不提交

### 安全最佳实践
- API密钥通过环境变量管理
- 不在代码中硬编码敏感信息
- 使用参数化查询防止注入攻击

---

## 测试策略

### 后端测试
- **单元测试**: 测试核心业务逻辑
- **集成测试**: 测试API接口功能
- **数据库测试**: 验证数据操作正确性

### 前端测试
- **Widget测试**: 测试UI组件功能
- **单元测试**: 测试控制器逻辑
- **集成测试**: 测试完整用户流程

---

## 性能优化

### 后端优化
- SQLite索引优化查询性能
- 异步处理提高并发能力
- 缓存机制减少重复计算

### 前端优化
- 使用 `const` 构造函数减少重建
- 合理使用 `Obx` 和 `GetBuilder`
- 图片和资源懒加载

---

## 扩展性考虑

### 水平扩展
- 后端可部署为多实例
- 数据库可升级为PostgreSQL/MySQL
- 支持负载均衡配置

### 功能扩展
- 模块化设计便于添加新功能
- 插件化AI代理系统
- 多语言支持框架

---

## 监控与维护

### 日志管理
- 后端使用结构化日志
- 前端错误收集和上报
- 性能指标监控

### 数据备份
- SQLite数据库定期备份
- 配置文件版本控制
- 用户数据导出功能

---

## 总结

NewStudy项目是一个现代化的智能学习应用，采用成熟的技术栈和良好的架构设计：

1. **技术选型合理**: Flutter + FastAPI 提供强大的跨平台能力
2. **架构清晰**: 前后端分离，模块化设计
3. **AI集成深度**: 费曼学习法与AI技术结合
4. **扩展性强**: 支持多平台部署和功能扩展
5. **开发友好**: 完善的文档和代码规范

该项目为智能学习领域提供了一个完整的解决方案，具有良好的实用价值和推广前景。