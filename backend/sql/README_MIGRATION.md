# 数据库迁移说明

## 导出脚本

| 文件 | 说明 |
|------|------|
| `migration_export.sql` | 导出的完整迁移脚本，幂等，可重复执行 |
| `init.sql` | 初始化 DDL（与 `migration_export.sql` 逻辑一致，可作参考） |

## 执行方式

### 1. 使用 psql

```bash
# 在 backend 目录下，并已设置 DATABASE_URL
cd backend
psql "$DATABASE_URL" -f sql/migration_export.sql

# 或显式指定连接
psql -h localhost -p 5433 -U newstudy -d newstudy_db -f sql/migration_export.sql
```

### 2. 使用 Python（读取 .env 中的 DATABASE_URL）

```bash
cd backend
psql "$(grep DATABASE_URL .env | cut -d= -f2-)" -f sql/migration_export.sql
```

## 适用场景

| 场景 | 操作 |
|------|------|
| **全新数据库** | 直接执行 `migration_export.sql` |
| **已有库，且 `flash_cards.status` / `learning_records.status` 仍为 VARCHAR** | 先执行 `uv run python migrations/migrate_card_status_enum.py`，再执行 `migration_export.sql` |
| **未安装 pgvector** | 在 `migration_export.sql` 中注释掉 `CREATE EXTENSION IF NOT EXISTS vector;` |

## 脚本内容概要

1. **扩展**：`vector`（可选）
2. **枚举**：`card_status`（NOT_STARTED, NEEDS_REVIEW, NEEDS_IMPROVE, NOT_MASTERED, MASTERED）
3. **表**：`users` → `notes` → `flash_cards` → `learning_records`
4. **增量列**：对已存在的 `notes`、`flash_cards` 做 `ADD COLUMN IF NOT EXISTS` 补列
5. **触发器**：`notes`、`flash_cards` 的 `updated_at` 自动更新
6. **默认数据**：用户 `default_user`

## 相关迁移脚本（Python）

- `migrations/add_learning_records.py`：创建 `learning_records`（已并入导出脚本）
- `migrations/add_note_default_role.py`：为 `notes` 添加 `default_role`（已并入导出脚本）
- `migrations/migrate_card_status_enum.py`：将 `status` 从 VARCHAR 转为 `card_status` 枚举（需在导出脚本之前执行的情况见上表）
