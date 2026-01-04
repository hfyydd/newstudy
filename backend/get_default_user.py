"""
获取默认用户的工具函数（纯 SQL 方式）
用于在代码中快速获取默认用户ID
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from db_sql import execute_one


def get_default_user_id() -> int:
    """
    获取默认用户的ID（纯 SQL 方式）
    
    Returns:
        int: 默认用户的ID
        
    Raises:
        ValueError: 如果默认用户不存在
    """
    user = execute_one(
        "SELECT id FROM users WHERE username = %s",
        ("default_user",)
    )
    if not user:
        raise ValueError("默认用户不存在，请先运行 init_db.py 或 init_default_user.py")
    return user['id']


def get_default_user() -> dict:
    """
    获取默认用户对象（纯 SQL 方式）
    
    Returns:
        dict: 默认用户字典，包含 id, username, email 等字段
        
    Raises:
        ValueError: 如果默认用户不存在
    """
    user = execute_one(
        "SELECT id, username, email, created_at, updated_at FROM users WHERE username = %s",
        ("default_user",)
    )
    if not user:
        raise ValueError("默认用户不存在，请先运行 init_db.py 或 init_default_user.py")
    return user


if __name__ == "__main__":
    try:
        user_id = get_default_user_id()
        user = get_default_user()
        print(f"✅ 默认用户信息:")
        print(f"   - ID: {user_id}")
        print(f"   - Username: {user.username}")
        print(f"   - Email: {user.email}")
    except ValueError as e:
        print(f"❌ {e}")

