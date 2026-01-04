"""
删除数据库中笔记测试数据的脚本
"""
import sys
from pathlib import Path

# 添加项目根目录到路径
sys.path.insert(0, str(Path(__file__).parent))

from db_sql import get_db_connection

def delete_test_notes():
    """删除所有笔记测试数据（包括关联的闪词卡片）"""
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                # 先删除所有闪词卡片（由于外键约束，需要先删除子表）
                delete_flashcards_sql = "DELETE FROM flash_cards"
                cur.execute(delete_flashcards_sql)
                flashcard_count = cur.rowcount
                print(f"✅ 已删除 {flashcard_count} 条闪词卡片记录")
                
                # 再删除所有笔记
                delete_notes_sql = "DELETE FROM notes"
                cur.execute(delete_notes_sql)
                note_count = cur.rowcount
                print(f"✅ 已删除 {note_count} 条笔记记录")
            
            # 提交事务（get_db_connection 会自动提交）
            print(f"\n✨ 清理完成！共删除 {note_count} 条笔记和 {flashcard_count} 条闪词卡片")
            
    except Exception as e:
        print(f"❌ 删除失败: {e}")
        raise


if __name__ == "__main__":
    print("🚀 开始删除笔记测试数据...")
    print("⚠️  警告：此操作将删除所有笔记和闪词卡片数据！")
    
    # 确认操作
    confirm = input("\n确认删除？(输入 'yes' 继续): ")
    if confirm.lower() != 'yes':
        print("❌ 操作已取消")
        sys.exit(0)
    
    delete_test_notes()
    print("\n✨ 数据库清理完成！")

