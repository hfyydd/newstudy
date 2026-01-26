# 数据库设置指南

## 快速开始

```bash
# 1. 初始化数据库表结构
python backend/init_db_simple.py init

# 2. 创建默认用户
python backend/init_db_simple.py user

# 3. 查看状态
python backend/init_db_simple.py status
```

---

## 命令说明

| 命令 | 说明 |
|------|------|
| `init` | 初始化数据库表结构 |
| `user` | 创建默认用户 |
| `reset` | 重置数据库（删除所有数据） |
| `status` | 查看数据库状态 |

---

## 数据库结构

```
users
  ├── id
  ├── username
  ├── email
  └── created_at, updated_at

notes
  ├── id
  ├── user_id (外键 → users)
  ├── title
  ├── content
  ├── markdown_content
  └── created_at, updated_at

flash_cards
  ├── id
  ├── note_id (外键 → notes)
  ├── term
  ├── status (枚举: NOT_STARTED, NEEDS_REVIEW, etc.)
  ├── review_count
  ├── last_reviewed_at
  ├── mastered_at
  └── created_at, updated_at

learning_records
  ├── id
  ├── card_id (外键 → flash_cards)
  ├── note_id (外键 → notes)
  ├── selected_role
  ├── user_explanation
  ├── score
  ├── ai_feedback
  ├── status
  ├── attempt_number
  └── attempted_at
```
