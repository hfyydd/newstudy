#!/usr/bin/env python3
"""
数据库快速初始化脚本
适用于团队开发者快速设置本地数据库
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from config import database_url
import asyncpg


async def init_database():
    """初始化数据库表结构"""
    print("正在初始化数据库...")

    conn = None
    try:
        conn = await asyncpg.connect(database_url)

        # 创建 card_status 枚举类型
        print("创建枚举类型...")
        await conn.execute("""
            DO $$
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'card_status') THEN
                    CREATE TYPE card_status AS ENUM (
                        'NOT_STARTED',
                        'NEEDS_REVIEW',
                        'NEEDS_IMPROVE',
                        'NOT_MASTERED',
                        'MASTERED'
                    );
                END IF;
            END $$;
        """)

        # 创建 users 表
        print("创建 users 表...")
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                username VARCHAR(50) UNIQUE NOT NULL,
                email VARCHAR(100) UNIQUE,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 创建 notes 表
        print("创建 notes 表...")
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS notes (
                id SERIAL PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                title VARCHAR(200) NOT NULL,
                content TEXT,
                markdown_content TEXT,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 创建 flash_cards 表
        print("创建 flash_cards 表...")
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS flash_cards (
                id SERIAL PRIMARY KEY,
                note_id INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
                term VARCHAR(100) NOT NULL,
                status card_status DEFAULT 'NOT_STARTED' NOT NULL,
                review_count INTEGER DEFAULT 0 NOT NULL,
                last_reviewed_at TIMESTAMP WITH TIME ZONE,
                mastered_at TIMESTAMP WITH TIME ZONE,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 创建 learning_records 表
        print("创建 learning_records 表...")
        await conn.execute("""
            CREATE TABLE IF NOT EXISTS learning_records (
                id SERIAL PRIMARY KEY,
                card_id INTEGER NOT NULL REFERENCES flash_cards(id) ON DELETE CASCADE,
                note_id INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
                selected_role VARCHAR(50) NOT NULL,
                user_explanation TEXT NOT NULL,
                score INTEGER NOT NULL,
                ai_feedback TEXT NOT NULL,
                status card_status NOT NULL,
                attempt_number INTEGER DEFAULT 1 NOT NULL,
                attempted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            )
        """)

        # 创建索引
        print("创建索引...")
        indexes = [
            "CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id)",
            "CREATE INDEX IF NOT EXISTS idx_flash_cards_note_id ON flash_cards(note_id)",
            "CREATE INDEX IF NOT EXISTS idx_learning_records_card_id ON learning_records(card_id)",
            "CREATE INDEX IF NOT EXISTS idx_learning_records_note_id ON learning_records(note_id)",
        ]
        for idx in indexes:
            await conn.execute(idx)

        print("\n数据库初始化完成！")
        return True

    except Exception as e:
        print(f"初始化失败: {e}")
        return False
    finally:
        if conn:
            await conn.close()


async def create_default_user():
    """创建默认用户"""
    print("创建默认用户...")

    conn = None
    try:
        conn = await asyncpg.connect(database_url)

        # 检查是否已有用户
        count = await conn.fetchval("SELECT COUNT(*) FROM users")
        if count > 0:
            print(f"已存在 {count} 个用户，跳过创建")
            return True

        # 创建默认用户
        await conn.execute("""
            INSERT INTO users (username, email)
            VALUES ('default_user', NULL)
        """)

        print("默认用户创建成功 (username: default_user)")
        return True

    except Exception as e:
        print(f"创建默认用户失败: {e}")
        return False
    finally:
        if conn:
            await conn.close()


async def reset_database():
    """重置数据库（删除所有数据）"""
    print("警告：这将删除所有数据！")

    response = input("确认重置？(输入 YES 确认): ").strip()
    if response != "YES":
        print("取消重置")
        return False

    print("正在重置数据库...")

    conn = None
    try:
        conn = await asyncpg.connect(database_url)

        # 按外键顺序删除
        await conn.execute("DELETE FROM learning_records")
        await conn.execute("DELETE FROM flash_cards")
        await conn.execute("DELETE FROM notes")
        await conn.execute("DELETE FROM users")

        print("数据库已重置")
        return True

    except Exception as e:
        print(f"重置失败: {e}")
        return False
    finally:
        if conn:
            await conn.close()


async def show_status():
    """显示数据库状态"""
    conn = None
    try:
        conn = await asyncpg.connect(database_url)

        users = await conn.fetchval("SELECT COUNT(*) FROM users")
        notes = await conn.fetchval("SELECT COUNT(*) FROM notes")
        cards = await conn.fetchval("SELECT COUNT(*) FROM flash_cards")
        records = await conn.fetchval("SELECT COUNT(*) FROM learning_records")

        print("\n数据库状态:")
        print(f"  用户: {users}")
        print(f"  笔记: {notes}")
        print(f"  卡片: {cards}")
        print(f"  学习记录: {records}")

    except Exception as e:
        print(f"查询失败: {e}")
    finally:
        if conn:
            await conn.close()


async def main():
    """主函数"""
    if len(sys.argv) < 2:
        print("用法:")
        print("  python init_db_simple.py init    # 初始化数据库表结构")
        print("  python init_db_simple.py user    # 创建默认用户")
        print("  python init_db_simple.py reset   # 重置数据库（删除所有数据）")
        print("  python init_db_simple.py status  # 查看数据库状态")
        print("\n快速开始:")
        print("  1. python init_db_simple.py init")
        print("  2. python init_db_simple.py user")
        return

    command = sys.argv[1]

    if command == "init":
        await init_database()
    elif command == "user":
        await create_default_user()
    elif command == "reset":
        await reset_database()
    elif command == "status":
        await show_status()
    else:
        print(f"未知命令: {command}")


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
