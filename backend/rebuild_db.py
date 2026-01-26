#!/usr/bin/env python3
"""
一键重建数据库脚本
删除所有表和数据，然后重新初始化
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from config import database_url
import asyncpg


async def rebuild_database():
    """重建数据库"""
    print("开始重建数据库...")
    print("这将删除所有表和数据！")

    response = input("确认继续？(输入 YES 确认): ").strip()
    if response != "YES":
        print("取消操作")
        return False

    conn = None
    try:
        conn = await asyncpg.connect(database_url)

        # 删除所有表（按外键逆序）
        print("\n删除现有表...")
        await conn.execute("DROP TABLE IF EXISTS learning_records CASCADE")
        await conn.execute("DROP TABLE IF EXISTS flash_cards CASCADE")
        await conn.execute("DROP TABLE IF EXISTS notes CASCADE")
        await conn.execute("DROP TABLE IF EXISTS users CASCADE")
        await conn.execute("DROP TYPE IF EXISTS card_status CASCADE")
        print("删除完成")

        # 创建枚举类型
        print("\n创建枚举类型...")
        await conn.execute("""
            CREATE TYPE card_status AS ENUM (
                'NOT_STARTED',
                'NEEDS_REVIEW',
                'NEEDS_IMPROVE',
                'NOT_MASTERED',
                'MASTERED'
            )
        """)

        # 创建 users 表
        print("创建 users 表...")
        await conn.execute("""
            CREATE TABLE users (
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
            CREATE TABLE notes (
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
            CREATE TABLE flash_cards (
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
            CREATE TABLE learning_records (
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
        await conn.execute("CREATE INDEX idx_notes_user_id ON notes(user_id)")
        await conn.execute("CREATE INDEX idx_flash_cards_note_id ON flash_cards(note_id)")
        await conn.execute("CREATE INDEX idx_learning_records_card_id ON learning_records(card_id)")
        await conn.execute("CREATE INDEX idx_learning_records_note_id ON learning_records(note_id)")

        # 创建默认用户
        print("\n创建默认用户...")
        await conn.execute("""
            INSERT INTO users (username, email)
            VALUES ('default_user', NULL)
        """)

        print("\n数据库重建完成！")
        print("默认用户: default_user")
        return True

    except Exception as e:
        print(f"重建失败: {e}")
        return False
    finally:
        if conn:
            await conn.close()


if __name__ == "__main__":
    import asyncio
    success = asyncio.run(rebuild_database())
    sys.exit(0 if success else 1)
