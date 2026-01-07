"""
数据库迁移脚本：添加学习记录表 (learning_records)
"""
import sys
from pathlib import Path

# 添加项目根目录到路径
sys.path.insert(0, str(Path(__file__).parent.parent))

from db_sql import get_db_connection

def migrate():
    """执行迁移：创建 learning_records 表"""
    print("🚀 开始迁移：添加学习记录表...")
    
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                # 检查表是否已存在
                cur.execute("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables 
                        WHERE table_name = 'learning_records'
                    )
                """)
                exists = cur.fetchone()[0]
                
                if exists:
                    print("⚠️  learning_records 表已存在，跳过创建")
                    return
                
                # 创建学习记录表
                cur.execute("""
                    CREATE TABLE learning_records (
                        id SERIAL PRIMARY KEY,
                        card_id INTEGER NOT NULL REFERENCES flash_cards(id) ON DELETE CASCADE,
                        note_id INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
                        selected_role VARCHAR(50) NOT NULL,
                        user_explanation TEXT NOT NULL,
                        score INTEGER NOT NULL,
                        ai_feedback TEXT NOT NULL,
                        status VARCHAR(20) NOT NULL,
                        attempt_number INTEGER NOT NULL DEFAULT 1,
                        attempted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                print("✅ 创建 learning_records 表成功")
                
                # 创建索引
                cur.execute("""
                    CREATE INDEX idx_learning_records_card_id ON learning_records(card_id)
                """)
                cur.execute("""
                    CREATE INDEX idx_learning_records_note_id ON learning_records(note_id)
                """)
                cur.execute("""
                    CREATE INDEX idx_learning_records_attempted_at ON learning_records(attempted_at DESC)
                """)
                print("✅ 创建索引成功")
                
                # 添加注释
                cur.execute("COMMENT ON TABLE learning_records IS '学习记录表'")
                cur.execute("COMMENT ON COLUMN learning_records.card_id IS '闪词卡片ID'")
                cur.execute("COMMENT ON COLUMN learning_records.note_id IS '笔记ID（冗余，便于查询）'")
                cur.execute("COMMENT ON COLUMN learning_records.selected_role IS '选择的角色（如5岁孩子、同事等）'")
                cur.execute("COMMENT ON COLUMN learning_records.user_explanation IS '用户的解释内容'")
                cur.execute("COMMENT ON COLUMN learning_records.score IS 'AI评估分数（0-100）'")
                cur.execute("COMMENT ON COLUMN learning_records.ai_feedback IS 'AI反馈内容'")
                cur.execute("COMMENT ON COLUMN learning_records.status IS '本次评估的状态'")
                cur.execute("COMMENT ON COLUMN learning_records.attempt_number IS '第几次尝试（同一卡片）'")
                cur.execute("COMMENT ON COLUMN learning_records.attempted_at IS '尝试时间'")
                print("✅ 添加注释成功")
                
        print("\n✨ 迁移完成！learning_records 表已创建")
        
    except Exception as e:
        print(f"❌ 迁移失败: {e}")
        raise


def rollback():
    """回滚迁移：删除 learning_records 表"""
    print("🔄 开始回滚：删除学习记录表...")
    
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("DROP TABLE IF EXISTS learning_records CASCADE")
        print("✅ 回滚成功：learning_records 表已删除")
        
    except Exception as e:
        print(f"❌ 回滚失败: {e}")
        raise


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="学习记录表迁移脚本")
    parser.add_argument("--rollback", action="store_true", help="回滚迁移（删除表）")
    args = parser.parse_args()
    
    if args.rollback:
        rollback()
    else:
        migrate()

