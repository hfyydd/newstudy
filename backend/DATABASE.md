# SQLite 数据库说明

## 概述

项目使用 SQLite 作为数据存储，数据库文件存储在 `backend/notes.db`。

## 数据库表结构

### notes 表
存储笔记信息

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT | 主键，笔记ID（UUID） |
| title | TEXT | 笔记标题（可为NULL） |
| content | TEXT | 笔记内容 |
| created_at | TEXT | 创建时间（ISO 8601格式） |
| updated_at | TEXT | 更新时间（ISO 8601格式） |

### flash_cards 表
存储闪词卡片信息

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT | 主键，卡片ID（UUID） |
| note_id | TEXT | 外键，关联笔记ID |
| term | TEXT | 词条内容 |
| status | TEXT | 学习状态：notStarted, needsReview, needsImprove, mastered |
| created_at | TEXT | 创建时间 |
| last_reviewed_at | TEXT | 最后复习时间（可为NULL） |

**约束**：
- UNIQUE(note_id, term)：同一笔记中词条不能重复
- FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE：级联删除

### 索引
- `idx_flash_cards_note_id`：提高按笔记ID查询的性能
- `idx_flash_cards_status`：提高按状态查询的性能

## 数据库初始化

数据库会在首次使用时自动创建。当 `Database` 类被实例化时，会：

1. 检查数据库文件是否存在
2. 创建数据库文件（如果不存在）
3. 创建所有必需的表和索引

## 使用方法

```python
from database import db

# 创建笔记
note = db.create_note(title="我的笔记", content="笔记内容")

# 获取笔记
note = db.get_note(note_id)

# 创建闪词卡片
cards = db.create_flash_cards(note_id, ["词条1", "词条2"])

# 获取闪词卡片
cards = db.get_flash_cards(note_id)

# 获取学习进度
progress = db.get_flash_card_progress(note_id)
```

## 数据持久化

- 数据存储在 `backend/notes.db` 文件中
- 数据库文件已被 `.gitignore` 忽略，不会提交到版本控制
- 服务重启后数据仍然保留

## 备份和恢复

### 备份数据库
```bash
cp backend/notes.db backend/notes.db.backup
```

### 恢复数据库
```bash
cp backend/notes.db.backup backend/notes.db
```

### 重置数据库（删除所有数据）
```bash
rm backend/notes.db
# 下次启动服务时会自动创建新数据库
```

## 注意事项

1. **并发访问**：SQLite 支持并发读取，但写入时会锁定数据库。对于单机部署的 FastAPI 应用，性能足够。
2. **数据迁移**：如果需要修改表结构，需要手动执行 SQL 迁移脚本。
3. **性能**：如果数据量很大（>10万条记录），建议考虑升级到 PostgreSQL 或 MySQL。

## 从内存存储迁移

如果你之前使用的是内存存储，所有数据会在服务重启后丢失。现在使用 SQLite 后：

1. 数据会持久化保存
2. 服务重启后数据仍然存在
3. 可以手动备份数据库文件
