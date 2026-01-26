#!/usr/bin/env python3
"""
数据库迁移脚本：从SQLite迁移到PostgreSQL
增强版：添加错误处理、数据验证和回滚机制
"""

import asyncio
import sqlite3
from datetime import datetime
from pathlib import Path
from uuid import uuid4
import logging
import sys
from typing import Optional, Dict, Any, List

import asyncpg
from config import database_url

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('migration.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


def validate_sqlite_data(sqlite_conn: sqlite3.Connection) -> Dict[str, Any]:
    """验证SQLite数据完整性"""
    cursor = sqlite_conn.cursor()
    
    validation_result = {
        'valid': True,
        'errors': [],
        'stats': {}
    }
    
    try:
        # 检查表是否存在
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [row[0] for row in cursor.fetchall()]
        
        required_tables = ['notes', 'flash_cards']
        for table in required_tables:
            if table not in tables:
                validation_result['errors'].append(f"缺少表: {table}")
                validation_result['valid'] = False
        
        # 检查数据完整性
        if 'notes' in tables:
            cursor.execute("SELECT COUNT(*) FROM notes")
            notes_count = cursor.fetchone()[0]
            validation_result['stats']['notes_count'] = notes_count
            
            # 检查必要字段
            cursor.execute("PRAGMA table_info(notes)")
            note_columns = [col[1] for col in cursor.fetchall()]
            required_note_columns = ['id', 'title', 'content', 'created_at', 'updated_at']
            for col in required_note_columns:
                if col not in note_columns:
                    validation_result['errors'].append(f"notes表缺少字段: {col}")
                    validation_result['valid'] = False
        
        if 'flash_cards' in tables:
            cursor.execute("SELECT COUNT(*) FROM flash_cards")
            cards_count = cursor.fetchone()[0]
            validation_result['stats']['cards_count'] = cards_count
            
            # 检查外键完整性
            cursor.execute("""
                SELECT COUNT(*) FROM flash_cards f
                LEFT JOIN notes n ON f.note_id = n.id
                WHERE n.id IS NULL
            """)
            orphaned_cards = cursor.fetchone()[0]
            if orphaned_cards > 0:
                validation_result['errors'].append(f"发现 {orphaned_cards} 条孤立卡片")
                validation_result['valid'] = False
            
            # 检查必要字段
            cursor.execute("PRAGMA table_info(flash_cards)")
            card_columns = [col[1] for col in cursor.fetchall()]
            required_card_columns = ['id', 'note_id', 'term', 'status', 'created_at', 'last_reviewed_at']
            for col in required_card_columns:
                if col not in card_columns:
                    validation_result['errors'].append(f"flash_cards表缺少字段: {col}")
                    validation_result['valid'] = False
    
    except Exception as e:
        validation_result['errors'].append(f"验证过程出错: {e}")
        validation_result['valid'] = False
    
    return validation_result

async def migrate_sqlite_to_postgresql():
    """增强版将SQLite数据迁移到PostgreSQL"""
    logger.info("开始SQLite到PostgreSQL数据迁移...")
    
    pg_conn = None
    sqlite_conn = None
    
    try:
        # 连接到PostgreSQL
        pg_conn = await asyncpg.connect(database_url)
        
        # 读取SQLite数据
        sqlite_path = Path(__file__).parent / "notes.db"
        if not sqlite_path.exists():
            logger.info("SQLite数据库文件不存在，无需迁移")
            return True
        
        sqlite_conn = sqlite3.connect(sqlite_path)
        sqlite_conn.row_factory = sqlite3.Row
        cursor = sqlite_conn.cursor()
        
        # 验证SQLite数据
        logger.info("验证SQLite数据完整性...")
        validation = validate_sqlite_data(sqlite_conn)
        
        if not validation['valid']:
            logger.error("SQLite数据验证失败:")
            for error in validation['errors']:
                logger.error(f"  - {error}")
            return False
        
        logger.info(f"SQLite数据统计: {validation['stats']}")
        
        # 开始迁移事务
        async with pg_conn.transaction():
            logger.info("开始迁移notes表...")
            cursor.execute("SELECT * FROM notes ORDER BY created_at")
            notes = cursor.fetchall()
            
            if notes:
                # 批量插入notes
                notes_data = [
                    (note['id'], note['title'], note['content'], 
                     note['created_at'], note['updated_at'])
                    for note in notes
                ]
                
                await pg_conn.executemany(
                    """
                    INSERT INTO notes (id, title, content, created_at, updated_at)
                    VALUES ($1, $2, $3, $4, $5)
                    ON CONFLICT (id) DO NOTHING
                    """,
                    notes_data
                )
            
            logger.info(f"迁移了 {len(notes)} 条笔记记录")
            
            logger.info("开始迁移flash_cards表...")
            cursor.execute("SELECT * FROM flash_cards ORDER BY created_at")
            cards = cursor.fetchall()
            
            if cards:
                # 批量插入flash_cards，修复参数顺序问题
                cards_data = [
                    (card['id'], card['note_id'], card['term'], card['status'],
                     card['created_at'], card['last_reviewed_at'])
                    for card in cards
                ]
                
                await pg_conn.executemany(
                    """
                    INSERT INTO flash_cards (id, note_id, term, status, created_at, last_reviewed_at)
                    VALUES ($1, $2, $3, $4, $5, $6)
                    ON CONFLICT (id) DO NOTHING
                    """,
                    cards_data
                )
            
            logger.info(f"迁移了 {len(cards)} 条闪词卡片记录")
        
        # 验证迁移结果
        pg_notes_count = await pg_conn.fetchval("SELECT COUNT(*) FROM notes")
        pg_cards_count = await pg_conn.fetchval("SELECT COUNT(*) FROM flash_cards")
        
        logger.info(f"PostgreSQL数据统计: {pg_notes_count} 笔记, {pg_cards_count} 卡片")
        
        # 检查数据一致性
        if pg_notes_count != len(notes) or pg_cards_count != len(cards):
            logger.error("数据迁移不一致！请检查迁移日志。")
            return False
        
        logger.info("数据迁移完成！")
        
        # 备份SQLite文件
        backup_path = sqlite_path.with_suffix('.db.backup')
        sqlite_path.rename(backup_path)
        logger.info(f"SQLite数据库已备份到: {backup_path}")
        
        return True
        
    except Exception as e:
        logger.error(f"迁移过程中出现错误: {e}")
        import traceback
        logger.error(f"错误详情: {traceback.format_exc()}")
        return False
    finally:
        if sqlite_conn:
            sqlite_conn.close()
        if pg_conn:
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
    """增强版主函数"""
    logger.info("开始数据库迁移流程...")
    
    # 测试PostgreSQL连接
    if not await test_postgresql_connection():
        logger.error("请检查PostgreSQL配置和连接")
        sys.exit(1)
    
    # 执行迁移
    migration_success = await migrate_sqlite_to_postgresql()
    
    if migration_success:
        logger.info("迁移流程完成！")
        sys.exit(0)
    else:
        logger.error("迁移流程失败！")
        sys.exit(1)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("迁移被用户中断")
        sys.exit(1)
    except Exception as e:
        logger.error(f"未预期的错误: {e}")
        import traceback
        logger.error(f"错误详情: {traceback.format_exc()}")
        sys.exit(1)