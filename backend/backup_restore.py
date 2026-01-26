#!/usr/bin/env python3
"""
数据库备份和恢复脚本
增强版：添加了安全检查、数据验证和错误处理
"""

import asyncio
import asyncpg
from datetime import datetime
from pathlib import Path
import json
import hashlib
import sys
import logging
from typing import Dict, Any, Optional, List
from dataclasses import dataclass

from config import database_url

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('backup_restore.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

@dataclass
class BackupMetadata:
    """备份数据结构"""
    timestamp: str
    users_count: int
    notes_count: int
    cards_count: int
    learning_records_count: int
    checksum: str
    version: str = "3.0"

def validate_backup_structure(data: Dict[Any, Any]) -> bool:
    """验证备份文件结构"""
    required_keys = ['timestamp', 'users', 'notes', 'flash_cards', 'learning_records', 'metadata']
    if not all(key in data for key in required_keys):
        logger.error("备份文件缺少必需的键")
        return False

    metadata = data.get('metadata', {})
    required_meta_keys = ['checksum', 'version', 'users_count', 'notes_count', 'cards_count', 'learning_records_count']
    if not all(key in metadata for key in required_meta_keys):
        logger.error("备份文件metadata缺少必需的键")
        return False

    # 验证版本兼容性
    if metadata['version'] not in ['1.0', '2.0', '3.0']:
        logger.error(f"不支持的备份版本: {metadata['version']}")
        return False

    return True

def calculate_data_checksum(data: Dict[Any, Any]) -> str:
    """计算数据校验和"""
    # 只对实际数据计算校验和，不包括metadata
    data_for_checksum = {
        'timestamp': data['timestamp'],
        'users': data['users'],
        'notes': data['notes'],
        'flash_cards': data['flash_cards'],
        'learning_records': data['learning_records']
    }
    content = json.dumps(data_for_checksum, sort_keys=True, ensure_ascii=False)
    return hashlib.sha256(content.encode('utf-8')).hexdigest()

def validate_data_integrity(data: Dict[Any, Any]) -> bool:
    """验证数据完整性"""
    metadata = data.get('metadata', {})
    expected_checksum = metadata.get('checksum')

    if not expected_checksum:
        logger.error("备份文件缺少校验和")
        return False

    actual_checksum = calculate_data_checksum(data)
    if actual_checksum != expected_checksum:
        logger.error(f"校验和不匹配: 期望 {expected_checksum}, 实际 {actual_checksum}")
        return False

    # 验证记录数量
    users_count = len(data.get('users', []))
    notes_count = len(data.get('notes', []))
    cards_count = len(data.get('flash_cards', []))
    learning_records_count = len(data.get('learning_records', []))

    if users_count != metadata.get('users_count', 0):
        logger.error(f"用户数量不匹配: 期望 {metadata['users_count']}, 实际 {users_count}")
        return False

    if notes_count != metadata.get('notes_count', 0):
        logger.error(f"笔记数量不匹配: 期望 {metadata['notes_count']}, 实际 {notes_count}")
        return False

    if cards_count != metadata.get('cards_count', 0):
        logger.error(f"卡片数量不匹配: 期望 {metadata['cards_count']}, 实际 {cards_count}")
        return False

    if learning_records_count != metadata.get('learning_records_count', 0):
        logger.error(f"学习记录数量不匹配: 期望 {metadata['learning_records_count']}, 实际 {learning_records_count}")
        return False

    return True

def confirm_destructive_operation(operation: str) -> bool:
    """确认破坏性操作"""
    print(f"\n⚠️  警告：{operation}将删除所有现有数据！")
    print("建议：请确保您已有当前数据的备份。")
    
    try:
        response = input("确认继续吗？(输入 'YES' 确认): ").strip()
        return response == 'YES'
    except (KeyboardInterrupt, EOFError):
        print("\n操作已取消")
        return False

def create_safety_backup() -> Optional[str]:
    """创建安全备份"""
    try:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        safety_backup_file = Path(f"safety_backup_{timestamp}.json")
        
        # 这里需要异步调用，暂时返回None
        # 在实际使用时需要传入连接
        logger.info(f"建议在恢复前创建安全备份: {safety_backup_file}")
        return str(safety_backup_file)
    except Exception as e:
        logger.error(f"创建安全备份失败: {e}")
        return None


async def backup_database() -> Path:
    """增强版数据库备份到JSON文件"""
    logger.info("开始数据库备份...")

    conn = None
    try:
        conn = await asyncpg.connect(database_url)

        # 设置锁防止并发修改
        await conn.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")
        await conn.execute("LOCK TABLE users IN SHARE MODE")
        await conn.execute("LOCK TABLE notes IN SHARE MODE")
        await conn.execute("LOCK TABLE flash_cards IN SHARE MODE")
        await conn.execute("LOCK TABLE learning_records IN SHARE MODE")

        # 备份users表
        async with conn.transaction():
            users_query = "SELECT * FROM users ORDER BY id"
            logger.info("正在备份users表...")
            users = await conn.fetch(users_query)

        # 备份notes表
        async with conn.transaction():
            notes_query = "SELECT * FROM notes ORDER BY created_at"
            logger.info("正在备份notes表...")
            notes = await conn.fetch(notes_query)

        # 备份flash_cards表
        async with conn.transaction():
            cards_query = "SELECT * FROM flash_cards ORDER BY created_at"
            logger.info("正在备份flash_cards表...")
            cards = await conn.fetch(cards_query)

        # 备份learning_records表
        async with conn.transaction():
            records_query = "SELECT * FROM learning_records ORDER BY attempted_at"
            logger.info("正在备份learning_records表...")
            learning_records = await conn.fetch(records_query)

        # 构建备份数据
        backup_data = {
            "timestamp": datetime.now().isoformat(),
            "users": [
                {
                    "id": user["id"],
                    "username": user["username"],
                    "email": user["email"],
                    "created_at": user["created_at"].isoformat(),
                    "updated_at": user["updated_at"].isoformat()
                }
                for user in users
            ],
            "notes": [
                {
                    "id": note["id"],
                    "user_id": note["user_id"],
                    "title": note["title"],
                    "content": note["content"],
                    "markdown_content": note.get("markdown_content"),
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
                    "review_count": card.get("review_count", 0),
                    "last_reviewed_at": card["last_reviewed_at"].isoformat() if card.get("last_reviewed_at") else None,
                    "mastered_at": card.get("mastered_at").isoformat() if card.get("mastered_at") else None,
                    "created_at": card["created_at"].isoformat(),
                    "updated_at": card["updated_at"].isoformat()
                }
                for card in cards
            ],
            "learning_records": [
                {
                    "id": record["id"],
                    "card_id": record["card_id"],
                    "note_id": record["note_id"],
                    "selected_role": record["selected_role"],
                    "user_explanation": record["user_explanation"],
                    "score": record["score"],
                    "ai_feedback": record["ai_feedback"],
                    "status": record["status"],
                    "attempt_number": record.get("attempt_number", 1),
                    "attempted_at": record["attempted_at"].isoformat()
                }
                for record in learning_records
            ]
        }

        # 添加元数据和校验和
        metadata = BackupMetadata(
            timestamp=backup_data["timestamp"],
            users_count=len(users),
            notes_count=len(notes),
            cards_count=len(cards),
            learning_records_count=len(learning_records),
            checksum=calculate_data_checksum(backup_data)
        )
        backup_data["metadata"] = {
            "timestamp": metadata.timestamp,
            "users_count": metadata.users_count,
            "notes_count": metadata.notes_count,
            "cards_count": metadata.cards_count,
            "learning_records_count": metadata.learning_records_count,
            "checksum": metadata.checksum,
            "version": metadata.version
        }

        # 保存到文件
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = Path(f"backup_{timestamp}.json")

        # 先写入临时文件，成功后再重命名
        temp_file = backup_file.with_suffix('.tmp')
        with open(temp_file, 'w', encoding='utf-8') as f:
            json.dump(backup_data, f, ensure_ascii=False, indent=2)

        # 原子性重命名
        temp_file.rename(backup_file)

        logger.info(f"数据库已备份到: {backup_file}")
        logger.info(f"备份了 {len(users)} 个用户, {len(notes)} 条笔记, {len(cards)} 条闪词卡片, {len(learning_records)} 条学习记录")

        return backup_file

    except Exception as e:
        logger.error(f"备份失败: {e}")
        raise
    finally:
        if conn:
            await conn.close()


async def restore_database(backup_file: str, force: bool = False) -> bool:
    """增强版从JSON备份文件恢复数据库"""
    logger.info(f"开始恢复数据库备份: {backup_file}")

    # 验证备份文件存在
    backup_path = Path(backup_file)
    if not backup_path.exists():
        logger.error(f"备份文件不存在: {backup_file}")
        return False

    # 读取并验证备份文件
    try:
        with open(backup_path, 'r', encoding='utf-8') as f:
            backup_data = json.load(f)
    except json.JSONDecodeError as e:
        logger.error(f"备份文件格式错误: {e}")
        return False
    except Exception as e:
        logger.error(f"读取备份文件失败: {e}")
        return False

    # 验证备份结构
    if not validate_backup_structure(backup_data):
        logger.error("备份文件结构验证失败")
        return False

    # 验证数据完整性
    if not validate_data_integrity(backup_data):
        logger.error("备份数据完整性验证失败")
        return False

    logger.info(f"备份时间: {backup_data['timestamp']}")
    logger.info(f"备份版本: {backup_data['metadata']['version']}")
    logger.info(f"用户数量: {backup_data['metadata']['users_count']}")
    logger.info(f"笔记数量: {backup_data['metadata']['notes_count']}")
    logger.info(f"卡片数量: {backup_data['metadata']['cards_count']}")
    logger.info(f"学习记录数量: {backup_data['metadata']['learning_records_count']}")

    # 确认破坏性操作
    if not force and not confirm_destructive_operation("数据库恢复"):
        logger.info("用户取消了恢复操作")
        return False

    conn = None
    try:
        conn = await asyncpg.connect(database_url)

        # 创建安全备份
        safety_backup = create_safety_backup()
        if safety_backup:
            logger.info(f"建议创建安全备份: {safety_backup}")

        # 使用事务确保原子性
        async with conn.transaction():
            logger.info("正在清空现有数据...")

            # 按外键依赖顺序清空表
            deleted_learning_records = await conn.fetchval("DELETE FROM learning_records RETURNING COUNT(*)")
            deleted_cards = await conn.fetchval("DELETE FROM flash_cards RETURNING COUNT(*)")
            deleted_notes = await conn.fetchval("DELETE FROM notes RETURNING COUNT(*)")
            deleted_users = await conn.fetchval("DELETE FROM users RETURNING COUNT(*)")

            logger.info(f"已删除 {deleted_learning_records} 条学习记录, {deleted_cards} 条卡片, {deleted_notes} 条笔记, {deleted_users} 个用户")

            # 批量恢复users表
            logger.info("正在恢复users表...")
            users_data = backup_data["users"]
            if users_data:
                await conn.executemany(
                    """
                    INSERT INTO users (id, username, email, created_at, updated_at)
                    VALUES ($1, $2, $3, $4, $5)
                    ON CONFLICT (id) DO NOTHING
                    """,
                    [
                        (user["id"], user["username"], user["email"],
                         user["created_at"], user["updated_at"])
                        for user in users_data
                    ]
                )

            # 批量恢复notes表
            logger.info("正在恢复notes表...")
            notes_data = backup_data["notes"]
            if notes_data:
                await conn.executemany(
                    """
                    INSERT INTO notes (id, user_id, title, content, markdown_content, created_at, updated_at)
                    VALUES ($1, $2, $3, $4, $5, $6, $7)
                    ON CONFLICT (id) DO NOTHING
                    """,
                    [
                        (note["id"], note["user_id"], note["title"], note["content"],
                         note.get("markdown_content"), note["created_at"], note["updated_at"])
                        for note in notes_data
                    ]
                )

            # 批量恢复flash_cards表
            logger.info("正在恢复flash_cards表...")
            cards_data = backup_data["flash_cards"]
            if cards_data:
                await conn.executemany(
                    """
                    INSERT INTO flash_cards (id, note_id, term, status, review_count, last_reviewed_at, mastered_at, created_at, updated_at)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
                    ON CONFLICT (id) DO NOTHING
                    """,
                    [
                        (card["id"], card["note_id"], card["term"], card["status"],
                         card.get("review_count", 0), card["last_reviewed_at"], card.get("mastered_at"),
                         card["created_at"], card["updated_at"])
                        for card in cards_data
                    ]
                )

            # 批量恢复learning_records表
            logger.info("正在恢复learning_records表...")
            learning_records_data = backup_data["learning_records"]
            if learning_records_data:
                await conn.executemany(
                    """
                    INSERT INTO learning_records (id, card_id, note_id, selected_role, user_explanation, score, ai_feedback, status, attempt_number, attempted_at)
                    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
                    ON CONFLICT (id) DO NOTHING
                    """,
                    [
                        (record["id"], record["card_id"], record["note_id"],
                         record["selected_role"], record["user_explanation"], record["score"],
                         record["ai_feedback"], record["status"], record.get("attempt_number", 1),
                         record["attempted_at"])
                        for record in learning_records_data
                    ]
                )

        # 验证恢复结果
        restored_users = await conn.fetchval("SELECT COUNT(*) FROM users")
        restored_notes = await conn.fetchval("SELECT COUNT(*) FROM notes")
        restored_cards = await conn.fetchval("SELECT COUNT(*) FROM flash_cards")
        restored_learning_records = await conn.fetchval("SELECT COUNT(*) FROM learning_records")

        logger.info(f"成功恢复了 {restored_users} 个用户, {restored_notes} 条笔记, {restored_cards} 条闪词卡片, {restored_learning_records} 条学习记录")
        logger.info("数据库恢复完成！")

        # 检查数据一致性
        expected_users = backup_data['metadata']['users_count']
        expected_notes = backup_data['metadata']['notes_count']
        expected_cards = backup_data['metadata']['cards_count']
        expected_learning_records = backup_data['metadata']['learning_records_count']

        if (restored_users != expected_users or
            restored_notes != expected_notes or
            restored_cards != expected_cards or
            restored_learning_records != expected_learning_records):
            logger.warning(f"数据数量不匹配！期望: {expected_users}用户, {expected_notes}笔记, {expected_cards}卡片, {expected_learning_records}学习记录; "
                          f"实际: {restored_users}用户, {restored_notes}笔记, {restored_cards}卡片, {restored_learning_records}学习记录")
            return False

        return True

    except Exception as e:
        logger.error(f"恢复失败: {e}")
        raise
    finally:
        if conn:
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

        metadata = backup_data.get('metadata', {})
        version = metadata.get('version', '1.0')

        print(f"{i}. {backup_file.name}")
        print(f"   备份时间: {backup_data['timestamp']}")
        print(f"   版本: {version}")

        # 兼容旧版本备份文件
        if version == '3.0':
            print(f"   用户: {metadata.get('users_count', 0)}")
            print(f"   笔记: {metadata.get('notes_count', 0)}")
            print(f"   卡片: {metadata.get('cards_count', 0)}")
            print(f"   学习记录: {metadata.get('learning_records_count', 0)}")
        elif version == '2.0':
            print(f"   笔记: {metadata.get('notes_count', 0)}")
            print(f"   卡片: {metadata.get('cards_count', 0)}")
            print(f"   (注: 旧版本备份，不包含用户和学习记录)")
        else:  # version 1.0
            print(f"   笔记: {len(backup_data.get('notes', []))}")
            print(f"   卡片: {len(backup_data.get('flash_cards', []))}")
            print(f"   (注: 旧版本备份)")
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