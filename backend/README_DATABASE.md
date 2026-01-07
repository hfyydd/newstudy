# 数据库使用指南

## 数据库表结构

### 1. 用户表 (users)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键，自增 |
| username | VARCHAR(50) | 用户名，唯一 |
| email | VARCHAR(100) | 邮箱，唯一，可选 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |

### 2. 笔记表 (notes)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键，自增 |
| user_id | INTEGER | 用户ID，外键关联 users.id |
| title | VARCHAR(200) | 笔记标题 |
| content | TEXT | 原始内容 |
| markdown_content | TEXT | Markdown格式的笔记内容 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |

### 3. 闪词表 (flash_cards)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | INTEGER | 主键，自增 |
| note_id | INTEGER | 笔记ID，外键关联 notes.id |
| term | VARCHAR(100) | 闪词内容 |
| status | VARCHAR(20) | 学习状态：not_started, needs_review（需巩固）, needs_improve, not_mastered, mastered |
| review_count | INTEGER | 复习次数，默认0 |
| last_reviewed_at | TIMESTAMP | 最后复习时间，可选 |
| mastered_at | TIMESTAMP | 掌握时间，可选 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |

## 关系说明

```
User (1) ──< (N) Note (1) ──< (N) FlashCard
```

- 一个用户可以有多个笔记
- 一个笔记可以有多个闪词
- 删除用户时，会级联删除该用户的所有笔记
- 删除笔记时，会级联删除该笔记的所有闪词

## 默认用户

为了方便本地调试，系统会自动创建一个默认用户：

- **Username**: `default_user`
- **Email**: `default@example.com`
- **ID**: 自动生成（通常是 1）

在代码中获取默认用户：

```python
from get_default_user import get_default_user_id, get_default_user

# 获取默认用户ID
user_id = get_default_user_id()

# 获取默认用户对象
user = get_default_user()
```

## 初始化数据库

### 方式一：使用 Python 脚本（推荐）

```bash
# 确保 PostgreSQL 已启动
docker compose up -d postgres

# 运行初始化脚本（会自动创建默认用户）
python init_db.py
```

### 单独创建默认用户

如果只想创建默认用户（表已存在）：

```bash
python init_default_user.py
```

### 方式二：使用 SQL 脚本

```bash
# 执行 SQL 脚本
docker compose exec postgres psql -U newstudy -d newstudy_db -f /path/to/sql/init.sql

# 或者从本地文件执行
cat sql/init.sql | docker compose exec -T postgres psql -U newstudy -d newstudy_db
```

### 方式三：在代码中初始化

```python
from database import init_db

# 初始化数据库（创建所有表）
init_db()
```

## 使用数据库模型

### 使用默认用户（推荐用于本地调试）

```python
from get_default_user import get_default_user_id

# 获取默认用户ID
user_id = get_default_user_id()  # 返回 1（通常是第一个用户）

# 创建笔记时使用默认用户
from models import Note
note = Note(
    user_id=user_id,
    title="我的笔记",
    content="..."
)
```

### 创建新用户

```python
from database import SessionLocal
from models import User

db = SessionLocal()
user = User(username="test_user", email="test@example.com")
db.add(user)
db.commit()
db.close()
```

### 创建笔记

```python
from models import Note

note = Note(
    user_id=1,
    title="经济学基础",
    content="原始内容...",
    markdown_content="# 经济学基础\n\n..."
)
db.add(note)
db.commit()
```

### 创建闪词

```python
from models import FlashCard, CardStatus

flash_card = FlashCard(
    note_id=1,
    term="通货膨胀",
    status=CardStatus.NOT_STARTED
)
db.add(flash_card)
db.commit()
```

### 查询数据

```python
# 查询用户的所有笔记
user = db.query(User).filter(User.id == 1).first()
notes = user.notes

# 查询笔记的所有闪词
note = db.query(Note).filter(Note.id == 1).first()
flash_cards = note.flash_cards

# 查询特定状态的闪词（需巩固状态）
needs_consolidation = db.query(FlashCard).filter(
    FlashCard.status == CardStatus.NEEDS_REVIEW  # 需巩固状态（70-89分）
).all()
```

## 在 FastAPI 中使用

```python
from fastapi import Depends
from sqlalchemy.orm import Session
from database import get_db

@app.get("/notes/{note_id}")
def get_note(note_id: int, db: Session = Depends(get_db)):
    note = db.query(Note).filter(Note.id == note_id).first()
    if not note:
        raise HTTPException(status_code=404, detail="Note not found")
    return note
```

## 验证表结构

```bash
# 进入数据库
docker compose exec postgres psql -U newstudy -d newstudy_db

# 查看所有表
\dt

# 查看表结构
\d users
\d notes
\d flash_cards

# 查看数据
SELECT * FROM users;
SELECT * FROM notes;
SELECT * FROM flash_cards;
```

## 注意事项

1. **外键约束**：删除用户或笔记时，会级联删除相关数据
2. **索引**：已为常用查询字段创建索引，提升查询性能
3. **时间戳**：created_at 和 updated_at 会自动管理
4. **状态枚举**：闪词状态使用枚举类型，确保数据一致性

