"""
迁移脚本：为现有词条初始化复习计划
"""
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path

def migrate_review_schedule():
    """为现有的闪词卡片创建复习计划"""
    db_path = Path(__file__).parent / "notes.db"
    conn = sqlite3.connect(str(db_path))
    cursor = conn.cursor()
    
    try:
        # 检查 review_schedule 表是否存在
        cursor.execute("""
            SELECT name FROM sqlite_master 
            WHERE type='table' AND name='review_schedule'
        """)
        if not cursor.fetchone():
            print("✗ review_schedule 表不存在，请先运行数据库初始化")
            return
        
        # 获取所有没有复习计划的词条
        cursor.execute("""
            SELECT fc.id, fc.status, fc.last_reviewed_at, fc.created_at
            FROM flash_cards fc
            LEFT JOIN review_schedule rs ON fc.id = rs.card_id
            WHERE rs.card_id IS NULL
        """)
        cards = cursor.fetchall()
        
        if not cards:
            print("✓ 所有词条都已存在复习计划")
            return
        
        print(f"找到 {len(cards)} 个需要初始化复习计划的词条")
        
        now = datetime.now()
        migrated_count = 0
        
        for card_id, status, last_reviewed_at, created_at in cards:
            # 根据状态计算下次复习时间
            if status == 'NEEDS_REVIEW':
                next_review = now + timedelta(days=1)  # 1天后
            elif status == 'NEEDS_IMPROVE':
                next_review = now + timedelta(days=3)  # 3天后
            elif status == 'MASTERED':
                next_review = now + timedelta(days=7)  # 7天后
            else:  # NOT_STARTED 或其他状态
                next_review = now + timedelta(hours=4)  # 4小时后
            
            next_review_str = next_review.isoformat()
            
            # 创建复习计划
            cursor.execute("""
                INSERT INTO review_schedule (id, card_id, next_review_at, review_count)
                VALUES (?, ?, ?, 0)
            """, (str(uuid4()), card_id, next_review_str))
            
            migrated_count += 1
        
        conn.commit()
        print(f"✓ 成功为 {migrated_count} 个词条创建复习计划")
        
    except Exception as e:
        print(f"✗ 迁移失败: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    from uuid import uuid4
    migrate_review_schedule()
