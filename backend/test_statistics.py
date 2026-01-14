#!/usr/bin/env python3
"""
测试学习统计功能

测试学习历史记录和统计计算是否正常工作
"""

from database import db
from datetime import datetime, timedelta
import sys


def test_statistics():
    """测试统计功能"""
    
    print("=" * 60)
    print("📊 测试学习统计功能")
    print("=" * 60)
    
    # 1. 获取当前统计
    print("\n1️⃣  获取当前统计信息：")
    stats = db.get_learning_statistics()
    print(f"   ✅ 已掌握词条: {stats['mastered']}")
    print(f"   📚 累计学习词条: {stats['totalTerms']}")
    print(f"   🔥 连续学习天数: {stats['consecutiveDays']}")
    print(f"   ⏱️  累计学习时长: {stats['totalMinutes']} 分钟")
    
    # 2. 测试学习历史记录
    print("\n2️⃣  测试学习历史记录功能：")
    
    # 获取第一个卡片用于测试
    notes = db.list_notes()
    if not notes:
        print("   ⚠️  没有找到笔记，无法测试")
        return False
    
    first_note = notes[0]
    flash_cards = db.get_flash_cards(first_note.id)
    
    if not flash_cards:
        print("   ⚠️  没有找到闪词卡片，无法测试")
        return False
    
    test_card = flash_cards[0]
    print(f"   📝 测试卡片: {test_card.term} (note_id: {first_note.id})")
    
    # 3. 更新卡片状态（这会自动记录学习历史）
    print("\n3️⃣  更新卡片状态（自动记录学习历史）：")
    success = db.update_flash_card_status(
        first_note.id, 
        test_card.term, 
        'needsReview'
    )
    
    if success:
        print("   ✅ 卡片状态更新成功")
    else:
        print("   ❌ 卡片状态更新失败")
        return False
    
    # 4. 再次获取统计，看是否有变化
    print("\n4️⃣  更新后的统计信息：")
    new_stats = db.get_learning_statistics()
    print(f"   ✅ 已掌握词条: {new_stats['mastered']}")
    print(f"   📚 累计学习词条: {new_stats['totalTerms']}")
    print(f"   🔥 连续学习天数: {new_stats['consecutiveDays']}")
    print(f"   ⏱️  累计学习时长: {new_stats['totalMinutes']} 分钟")
    
    # 5. 检查学习历史记录
    print("\n5️⃣  验证学习历史记录：")
    conn = db._get_connection()
    try:
        cursor = conn.cursor()
        cursor.execute("""
            SELECT COUNT(*) as count FROM learning_history
        """)
        history_count = cursor.fetchone()["count"]
        print(f"   📊 学习历史记录数: {history_count}")
        
        # 显示最近5条记录
        cursor.execute("""
            SELECT lh.*, fc.term
            FROM learning_history lh
            JOIN flash_cards fc ON lh.card_id = fc.id
            ORDER BY lh.studied_at DESC
            LIMIT 5
        """)
        records = cursor.fetchall()
        
        if records:
            print(f"   📝 最近 {len(records)} 条学习记录：")
            for record in records:
                studied_time = datetime.fromisoformat(record["studied_at"]).strftime("%Y-%m-%d %H:%M:%S")
                print(f"      - {record['term']}: {record['status']} ({record['duration_seconds']}秒) - {studied_time}")
        else:
            print("   ℹ️  暂无学习记录")
            
    finally:
        conn.close()
    
    # 6. 统计对比
    print("\n6️⃣  统计变化对比：")
    if new_stats['totalMinutes'] > stats['totalMinutes']:
        print(f"   ✅ 学习时长增加: {stats['totalMinutes']}分钟 → {new_stats['totalMinutes']}分钟")
    else:
        print(f"   ℹ️  学习时长: {new_stats['totalMinutes']}分钟")
    
    if new_stats['consecutiveDays'] > 0:
        print(f"   ✅ 连续学习天数: {new_stats['consecutiveDays']}天")
    else:
        print(f"   ℹ️  连续学习天数: 0天（今天首次学习或中断超过1天）")
    
    print("\n" + "=" * 60)
    print("✅ 统计功能测试完成！")
    print("=" * 60)
    
    return True


def test_consecutive_days_logic():
    """测试连续天数计算逻辑"""
    print("\n" + "=" * 60)
    print("🧪 测试连续天数计算逻辑")
    print("=" * 60)
    
    conn = db._get_connection()
    try:
        cursor = conn.cursor()
        
        # 测试 _calculate_consecutive_days 方法
        consecutive_days = db._calculate_consecutive_days(cursor)
        
        print(f"\n当前连续学习天数: {consecutive_days} 天")
        
        # 查看有学习记录的日期（SQLite不支持DATE函数，使用Python处理）
        cursor.execute("""
            SELECT studied_at
            FROM learning_history
            ORDER BY studied_at DESC
        """)
        
        rows = cursor.fetchall()
        if rows:
            # 按日期分组统计
            from collections import defaultdict
            date_counts = defaultdict(int)
            for row in rows:
                study_datetime = datetime.fromisoformat(row["studied_at"])
                study_date = study_datetime.date()
                date_counts[str(study_date)] += 1
            
            dates = sorted(date_counts.items(), reverse=True)[:10]
            print(f"\n最近 {len(dates)} 天的学习记录：")
            for date_str, count in dates:
                print(f"   - {date_str}: {count} 次学习")
        else:
            print("\n暂无学习记录")
            
    finally:
        conn.close()


if __name__ == "__main__":
    try:
        # 运行基本测试
        success = test_statistics()
        
        # 运行连续天数逻辑测试
        test_consecutive_days_logic()
        
        sys.exit(0 if success else 1)
        
    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
