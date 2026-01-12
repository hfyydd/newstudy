#!/usr/bin/env python3
"""
数据库迁移脚本：添加学习历史表

此脚本用于给现有数据库添加 learning_history 表，用于记录学习历史和计算统计信息。

运行方式：
    python migrate_add_learning_history.py
"""

import sqlite3
import sys
from pathlib import Path


def migrate_database(db_path: str = "notes.db"):
    """执行数据库迁移"""
    
    print(f"🔄 开始迁移数据库: {db_path}")
    
    # 检查数据库文件是否存在
    if not Path(db_path).exists():
        print(f"❌ 数据库文件不存在: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # 检查表是否已存在
        cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name='learning_history'
        """)
        
        if cursor.fetchone():
            print("ℹ️  learning_history 表已存在，跳过创建")
        else:
            # 创建学习历史表
            print("📝 创建 learning_history 表...")
            cursor.execute("""
                CREATE TABLE learning_history (
                    id TEXT PRIMARY KEY,
                    card_id TEXT NOT NULL,
                    note_id TEXT NOT NULL,
                    status TEXT NOT NULL,
                    duration_seconds INTEGER DEFAULT 0,
                    studied_at TEXT NOT NULL,
                    FOREIGN KEY (card_id) REFERENCES flash_cards(id) ON DELETE CASCADE,
                    FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
                )
            """)
            print("✅ learning_history 表创建成功")
        
        # 检查索引是否存在
        cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='index' AND name='idx_learning_history_card_id'
        """)
        
        if cursor.fetchone():
            print("ℹ️  索引 idx_learning_history_card_id 已存在")
        else:
            print("📝 创建索引 idx_learning_history_card_id...")
            cursor.execute("""
                CREATE INDEX idx_learning_history_card_id 
                ON learning_history(card_id)
            """)
            print("✅ 索引创建成功")
        
        # 检查第二个索引
        cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='index' AND name='idx_learning_history_studied_at'
        """)
        
        if cursor.fetchone():
            print("ℹ️  索引 idx_learning_history_studied_at 已存在")
        else:
            print("📝 创建索引 idx_learning_history_studied_at...")
            cursor.execute("""
                CREATE INDEX idx_learning_history_studied_at 
                ON learning_history(studied_at)
            """)
            print("✅ 索引创建成功")
        
        conn.commit()
        
        # 显示表结构
        print("\n📊 learning_history 表结构：")
        cursor.execute("PRAGMA table_info(learning_history)")
        columns = cursor.fetchall()
        for col in columns:
            print(f"  - {col[1]} ({col[2]})")
        
        # 统计现有数据
        cursor.execute("SELECT COUNT(*) FROM notes")
        note_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM flash_cards")
        card_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM learning_history")
        history_count = cursor.fetchone()[0]
        
        print(f"\n📈 数据库统计：")
        print(f"  - 笔记数量: {note_count}")
        print(f"  - 闪词卡片数量: {card_count}")
        print(f"  - 学习历史记录数量: {history_count}")
        
        conn.close()
        print(f"\n✅ 数据库迁移完成！")
        return True
        
    except Exception as e:
        print(f"\n❌ 迁移失败: {e}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    # 支持自定义数据库路径
    db_path = sys.argv[1] if len(sys.argv) > 1 else "notes.db"
    
    success = migrate_database(db_path)
    sys.exit(0 if success else 1)
