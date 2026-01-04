# 笔记管理API实现说明

## 已实现的接口

### 1. POST /notes - 创建笔记
- **功能**: 创建新笔记
- **请求体**:
  ```json
  {
    "title": "笔记标题（可选）",
    "content": "笔记内容（必需）"
  }
  ```
- **响应**:
  ```json
  {
    "id": "笔记ID",
    "title": "笔记标题",
    "content": "笔记内容",
    "createdAt": "2025-01-01T00:00:00",
    "updatedAt": "2025-01-01T00:00:00",
    "termCount": 0
  }
  ```

### 2. GET /notes/{note_id} - 获取笔记详情
- **功能**: 根据笔记ID获取笔记详细信息
- **路径参数**: `note_id` - 笔记ID
- **响应**:
  ```json
  {
    "id": "笔记ID",
    "title": "笔记标题",
    "content": "笔记内容",
    "createdAt": "2025-01-01T00:00:00",
    "updatedAt": "2025-01-01T00:00:00",
    "termCount": 25
  }
  ```

### 3. POST /notes/{note_id}/flash-cards/generate - 生成闪词卡片
- **功能**: 从笔记内容中提取词条并创建闪词卡片
- **路径参数**: `note_id` - 笔记ID
- **请求体（可选）**:
  ```json
  {
    "max_terms": 30
  }
  ```
- **响应**:
  ```json
  {
    "note_id": "笔记ID",
    "terms": ["词条1", "词条2", ...],
    "total": 25
  }
  ```
- **说明**: 如果笔记已有词条，新词条会追加到现有列表中（自动去重，保留已有词条的学习状态）

### 4. GET /notes/{note_id}/flash-cards/progress - 获取闪词学习进度
- **功能**: 获取笔记的闪词学习进度统计
- **路径参数**: `note_id` - 笔记ID
- **响应**:
  ```json
  {
    "total": 30,
    "mastered": 12,
    "needsReview": 8,
    "needsImprove": 5,
    "notStarted": 5
  }
  ```

## 数据存储

使用 SQLite 数据库存储（`database.py`），数据持久化到 `notes.db` 文件中。数据库会在首次使用时自动创建表和索引。

### 数据库表结构

#### notes 表
- `id` (TEXT PRIMARY KEY): 笔记ID
- `title` (TEXT): 笔记标题（可为空）
- `content` (TEXT NOT NULL): 笔记内容
- `created_at` (TEXT NOT NULL): 创建时间（ISO 8601 格式）
- `updated_at` (TEXT NOT NULL): 更新时间（ISO 8601 格式）

#### flash_cards 表
- `id` (TEXT PRIMARY KEY): 卡片ID
- `note_id` (TEXT NOT NULL): 笔记ID（外键）
- `term` (TEXT NOT NULL): 词条
- `status` (TEXT NOT NULL): 学习状态（notStarted, needsReview, needsImprove, mastered）
- `created_at` (TEXT NOT NULL): 创建时间
- `last_reviewed_at` (TEXT): 最后复习时间（可为空）
- UNIQUE(note_id, term): 唯一约束，确保同一笔记中词条不重复

### 数据库文件位置
数据库文件默认存储在 `backend/notes.db`，可以通过修改 `Database` 类的初始化参数来指定其他路径。

## 注意事项

1. 所有时间字段使用 ISO 8601 格式（datetime）
2. 字段名使用 camelCase 以匹配前端
3. 闪词卡片状态: `notStarted`, `needsReview`, `needsImprove`, `mastered`
4. 生成闪词卡片时会自动去重，不会覆盖已有词条的学习状态

## 测试建议

可以使用以下命令测试接口：

```bash
# 创建笔记
curl -X POST http://localhost:8000/notes \
  -H "Content-Type: application/json" \
  -d '{"title": "测试笔记", "content": "这是一段测试内容"}'

# 获取笔记详情（使用上面返回的 note_id）
curl http://localhost:8000/notes/{note_id}

# 生成闪词卡片
curl -X POST http://localhost:8000/notes/{note_id}/flash-cards/generate \
  -H "Content-Type: application/json" \
  -d '{"max_terms": 30}'

# 获取学习进度
curl http://localhost:8000/notes/{note_id}/flash-cards/progress
```
