# 数据库备份迁移文档

## 版本历史

| 版本 | 发布日期 | 数据表 | 说明 |
|------|---------|--------|------|
| 3.0 | 2026-01 | 4张表 | 完整备份：users, notes, flash_cards, learning_records |
| 2.0 | 2025 | 2张表 | notes + flash_cards（字段不完整） |
| 1.0 | 2025 | 2张表 | notes + flash_cards（早期版本） |

---

## 版本 3.0 变更内容

### 新增表

**users 表**
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
);
```

**learning_records 表**
```sql
CREATE TABLE learning_records (
    id SERIAL PRIMARY KEY,
    card_id INTEGER REFERENCES flash_cards(id) ON DELETE CASCADE,
    note_id INTEGER REFERENCES notes(id) ON DELETE CASCADE,
    selected_role VARCHAR(50) NOT NULL,
    user_explanation TEXT NOT NULL,
    score INTEGER NOT NULL,
    ai_feedback TEXT NOT NULL,
    status card_status NOT NULL,
    attempt_number INTEGER DEFAULT 1,
    attempted_at TIMESTAMP WITH TIME ZONE
);
```

### 字段补充

**notes 表新增字段**
- `user_id` INTEGER (外键 → users.id)
- `markdown_content` TEXT

**flash_cards 表新增字段**
- `review_count` INTEGER DEFAULT 0
- `mastered_at` TIMESTAMP WITH TIME ZONE
- `updated_at` TIMESTAMP WITH TIME ZONE

---

## 迁移指南

### 从旧版本备份迁移到新数据库

如果你有旧版本（1.0 或 2.0）的备份文件，恢复到新数据库时需要注意：

#### 步骤 1：确认数据库表结构

确保数据库已执行最新迁移，包含所有4张表：

```bash
# 检查表结构
python backend/check_pg_schema.py
```

#### 步骤 2：恢复旧版本备份

旧版本备份文件可以直接恢复，系统会自动兼容：

```bash
# 列出可用备份
python backend/backup_restore.py list

# 恢复旧版本备份（系统会自动处理缺失字段）
python backend/backup_restore.py restore
# 选择备份文件编号
```

#### 步骤 3：处理缺失数据

恢复后需要手动补充以下数据：

1. **users 表**：如果旧备份没有用户数据，需要创建默认用户

   ```bash
   python backend/init_default_user.py
   ```

2. **user_id 外键**：为已恢复的 notes 记录关联用户

   ```sql
   -- 将所有笔记关联到默认用户（通常是 id=1）
   UPDATE notes SET user_id = 1 WHERE user_id IS NULL;
   ```

3. **flash_cards 新字段**：设置默认值

   ```sql
   UPDATE flash_cards SET review_count = 0 WHERE review_count IS NULL;
   UPDATE flash_cards SET updated_at = created_at WHERE updated_at IS NULL;
   ```

---

## 完整迁移示例

### 场景：从 2.0 版本迁移

```bash
# 1. 列出现有备份
python backend/backup_restore.py list

# 输出示例：
# 1. backup_20250115_120000.json
#    备份时间: 2025-01-15T12:00:00
#    版本: 2.0
#    笔记: 10
#    卡片: 50
#    (注: 旧版本备份，不包含用户和学习记录)

# 2. 恢复备份
python backend/backup_restore.py restore
# 输入: 1
# 确认: YES

# 3. 创建默认用户
python backend/init_default_user.py

# 4. 关联用户数据
psql -d your_database -c "UPDATE notes SET user_id = 1 WHERE user_id IS NULL;"

# 5. 补充默认值
psql -d your_database -c "UPDATE flash_cards SET review_count = 0 WHERE review_count IS NULL;"
psql -d your_database -c "UPDATE flash_cards SET updated_at = created_at WHERE updated_at IS NULL;"

# 6. 创建新的完整备份
python backend/backup_restore.py backup
```

---

## 备份文件格式

### 版本 3.0 格式

```json
{
  "timestamp": "2026-01-26T10:00:00",
  "users": [
    {
      "id": 1,
      "username": "default_user",
      "email": null,
      "created_at": "2026-01-01T00:00:00",
      "updated_at": "2026-01-01T00:00:00"
    }
  ],
  "notes": [
    {
      "id": 1,
      "user_id": 1,
      "title": "笔记标题",
      "content": "原始内容",
      "markdown_content": "Markdown 格式内容",
      "created_at": "2026-01-01T00:00:00",
      "updated_at": "2026-01-01T00:00:00"
    }
  ],
  "flash_cards": [
    {
      "id": 1,
      "note_id": 1,
      "term": "闪词内容",
      "status": "NOT_STARTED",
      "review_count": 0,
      "last_reviewed_at": null,
      "mastered_at": null,
      "created_at": "2026-01-01T00:00:00",
      "updated_at": "2026-01-01T00:00:00"
    }
  ],
  "learning_records": [
    {
      "id": 1,
      "card_id": 1,
      "note_id": 1,
      "selected_role": "5岁孩子",
      "user_explanation": "用户解释",
      "score": 85,
      "ai_feedback": "AI反馈",
      "status": "NEEDS_REVIEW",
      "attempt_number": 1,
      "attempted_at": "2026-01-26T10:00:00"
    }
  ],
  "metadata": {
    "timestamp": "2026-01-26T10:00:00",
    "users_count": 1,
    "notes_count": 1,
    "cards_count": 1,
    "learning_records_count": 1,
    "checksum": "abc123...",
    "version": "3.0"
  }
}
```

---

## 常见问题

### Q1：旧版本备份能直接恢复吗？

A：可以。恢复脚本会自动兼容，但缺失的字段会使用默认值或 NULL。

### Q2：如何确认备份版本？

A：使用 `list` 命令查看，会显示备份版本和内容统计。

```bash
python backend/backup_restore.py list
```

### Q3：恢复后数据不完整怎么办？

A：按照上面的"完整迁移示例"步骤，补充缺失的数据。

### Q4：新备份能否在旧系统恢复？

A：不能。新版本（3.0）备份只能在包含完整表结构的数据库中恢复。

---

## 自动迁移脚本

如果你需要自动化迁移过程，可以创建以下脚本：

```python
#!/usr/bin/env python3
"""
自动迁移旧版本备份到新数据库
"""
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from backup_restore import restore_database
import asyncpg
from config import database_url


async def migrate_old_backup(backup_file: str):
    """迁移旧版本备份"""
    print(f"开始迁移: {backup_file}")

    # 1. 恢复备份
    success = await restore_database(backup_file, force=True)
    if not success:
        print("恢复失败")
        return False

    # 2. 补充用户数据
    print("创建默认用户...")
    from init_default_user import create_default_user
    create_default_user()

    # 3. 关联用户
    print("关联用户数据...")
    conn = await asyncpg.connect(database_url)
    try:
        await conn.execute("UPDATE notes SET user_id = 1 WHERE user_id IS NULL")
        await conn.execute("UPDATE flash_cards SET review_count = 0 WHERE review_count IS NULL")
        await conn.execute("UPDATE flash_cards SET updated_at = created_at WHERE updated_at IS NULL")
        print("迁移完成！")
    finally:
        await conn.close()

    return True


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python migrate_backup.py <backup_file>")
        sys.exit(1)

    asyncio.run(migrate_old_backup(sys.argv[1]))
```

保存为 `backend/migrate_backup.py`，使用方法：

```bash
python backend/migrate_backup.py backup_20250115_120000.json
```
