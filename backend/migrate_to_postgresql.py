#!/usr/bin/env python3
"""
数据库迁移脚本：从SQLite迁移到PostgreSQL
"""

import asyncio
import sqlite3
from datetime import datetime
from pathlib import Path
from uuid import uuid4

import asyncpg
from config import database_url


async def migrate_sqlite_to_postgresql():
    """将SQLite数据迁移到PostgreSQL"""
    
    # 连接到PostgreSQL
    pg_conn = await asyncpg.connect(database_url)
    
    try:
        # 读取SQLite数据
        sqlite_path = Path(__file__).parent / "notes.db"
        if not sqlite_path.exists():
            print("SQLite数据库文件不存在，无需迁移")
            return
        
        sqlite_conn = sqlite3.connect(sqlite_path)
        sqlite_conn.row_factory = sqlite3.Row
        cursor = sqlite_conn.cursor()
        
        # 迁移notes表
        print("开始迁移notes表...")
        cursor.execute("SELECT * FROM notes")
        notes = cursor.fetchall()
        
        for note in notes:
            await pg_conn.execute(
                """
                INSERT INTO notes (id, title, content, created_at, updated_at)
                VALUES ($1, $2, $3, $4, $5)
                ON CONFLICT (id) DO NOTHING
                """,
                note['id'], note['title'], note['content'], 
                note['created_at'], note['updated_at']
            )
        
        print(f"迁移了 {len(notes)} 条笔记记录")
        
        # 迁移flash_cards表
        print("开始迁移flash_cards表...")
        cursor.execute("SELECT * FROM flash_cards")
        cards = cursor.fetchall()
        
        for card in cards:
            await pg_conn.execute(
                """
                INSERT INTO flash_cards (id, note_id, term, status, created_at, last_reviewed_at)
                VALUES ($1, $2, $3, $4, $5, $6)
                ON CONFLICT (id) DO NOTHING
                """,
                card['id'], card['note_id'], card['status'],
                card['term'], card['created_at'], card['last_reviewed_at']
            )
        
        print(f"迁移了 {len(cards)} 条闪词卡片记录")
        
        sqlite_conn.close()
        print("数据迁移完成！")
        
        # 备份SQLite文件
        backup_path = sqlite_path.with_suffix('.db.backup')
        sqlite_path.rename(backup_path)
        print(f"SQLite数据库已备份到: {backup_path}")
        
    except Exception as e:
        print(f"迁移过程中出现错误: {e}")
        raise
    finally:
        await pg_conn.close()


async def test_postgresql_connection():
    """测试PostgreSQL连接"""
    try:
        conn = await asyncpg.connect(database_url)
        await conn.execute("SELECT 1")
        await conn.close()
        print("PostgreSQL连接测试成功！")
        return True
    except Exception as e:
        print(f"PostgreSQL连接测试失败: {e}")
        return False


async def main():
    """主函数"""
    print("开始数据库迁移流程...")
    
    # 测试PostgreSQL连接
    if not await test_postgresql_connection():
        print("请检查PostgreSQL配置和连接")
        return
    
    # 执行迁移
    await migrate_sqlite_to_postgresql()
    
    print("迁移流程完成！")


if __name__ == "__main__":
    asyncio.run(main())