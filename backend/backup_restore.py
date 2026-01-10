#!/usr/bin/env python3
"""
数据库备份和恢复脚本
"""

import asyncio
import asyncpg
from datetime import datetime
from pathlib import Path
import json

from config import database_url


async def backup_database():
    """备份数据库到JSON文件"""
    
    conn = await asyncpg.connect(database_url)
    
    try:
        # 备份notes表
        notes = await conn.fetch("SELECT * FROM notes ORDER BY created_at")
        
        # 备份flash_cards表
        cards = await conn.fetch("SELECT * FROM flash_cards ORDER BY created_at")
        
        backup_data = {
            "timestamp": datetime.now().isoformat(),
            "notes": [
                {
                    "id": note["id"],
                    "title": note["title"],
                    "content": note["content"],
                    "created_at": note["created_at"].isoformat(),
                    "updated_at": note["updated_at"].isoformat()
                }
                for note in notes
            ],
            "flash_cards": [
                {
                    "id": card["id"],
                    "note_id": card["note_id"],
                    "term": card["term"],
                    "status": card["status"],
                    "created_at": card["created_at"].isoformat(),
                    "last_reviewed_at": card["last_reviewed_at"].isoformat() if card["last_reviewed_at"] else None
                }
                for card in cards
            ]
        }
        
        # 保存到文件
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = Path(f"backup_{timestamp}.json")
        
        with open(backup_file, 'w', encoding='utf-8') as f:
            json.dump(backup_data, f, ensure_ascii=False, indent=2)
        
        print(f"数据库已备份到: {backup_file}")
        print(f"备份了 {len(notes)} 条笔记和 {len(cards)} 条闪词卡片")
        
        return backup_file
        
    except Exception as e:
        print(f"备份失败: {e}")
        raise
    finally:
        await conn.close()


async def restore_database(backup_file: str):
    """从JSON备份文件恢复数据库"""
    
    conn = await asyncpg.connect(database_url)
    
    try:
        # 读取备份文件
        with open(backup_file, 'r', encoding='utf-8') as f:
            backup_data = json.load(f)
        
        print(f"开始恢复数据库备份: {backup_file}")
        print(f"备份时间: {backup_data['timestamp']}")
        
        async with conn.transaction():
            # 清空现有数据
            await conn.execute("DELETE FROM flash_cards")
            await conn.execute("DELETE FROM notes")
            
            # 恢复notes表
            for note in backup_data["notes"]:
                await conn.execute(
                    """
                    INSERT INTO notes (id, title, content, created_at, updated_at)
                    VALUES ($1, $2, $3, $4, $5)
                    """,
                    note["id"], note["title"], note["content"],
                    note["created_at"], note["updated_at"]
                )
            
            # 恢复flash_cards表
            for card in backup_data["flash_cards"]:
                await conn.execute(
                    """
                    INSERT INTO flash_cards (id, note_id, term, status, created_at, last_reviewed_at)
                    VALUES ($1, $2, $3, $4, $5, $6)
                    """,
                    card["id"], card["note_id"], card["status"],
                    card["created_at"], card["last_reviewed_at"]
                )
        
        print(f"恢复了 {len(backup_data['notes'])} 条笔记和 {len(backup_data['flash_cards'])} 条闪词卡片")
        print("数据库恢复完成！")
        
    except Exception as e:
        print(f"恢复失败: {e}")
        raise
    finally:
        await conn.close()


async def list_backups():
    """列出所有备份文件"""
    
    backup_dir = Path(".")
    backup_files = list(backup_dir.glob("backup_*.json"))
    
    if not backup_files:
        print("没有找到备份文件")
        return []
    
    backup_files.sort(key=lambda x: x.stat().st_mtime, reverse=True)
    
    print("可用备份文件:")
    for i, backup_file in enumerate(backup_files, 1):
        with open(backup_file, 'r', encoding='utf-8') as f:
            backup_data = json.load(f)
        
        print(f"{i}. {backup_file.name}")
        print(f"   备份时间: {backup_data['timestamp']}")
        print(f"   笔记数量: {len(backup_data['notes'])}")
        print(f"   卡片数量: {len(backup_data['flash_cards'])}")
        print()
    
    return backup_files


async def main():
    """主函数"""
    import sys
    
    if len(sys.argv) < 2:
        print("用法:")
        print("  python backup_restore.py backup    # 备份数据库")
        print("  python backup_restore.py restore   # 恢复数据库")
        print("  python backup_restore.py list     # 列出备份文件")
        return
    
    command = sys.argv[1]
    
    if command == "backup":
        await backup_database()
    elif command == "restore":
        backup_files = await list_backups()
        if backup_files:
            try:
                choice = int(input("请选择要恢复的备份文件编号: ")) - 1
                if 0 <= choice < len(backup_files):
                    await restore_database(str(backup_files[choice]))
                else:
                    print("无效的选择")
            except ValueError:
                print("请输入有效的数字")
    elif command == "list":
        await list_backups()
    else:
        print(f"未知命令: {command}")


if __name__ == "__main__":
    asyncio.run(main())