"""
创建默认用户脚本（纯 SQL 方式）
用于本地调试，创建一个默认用户
"""
import sys
from pathlib import Path

# 添加项目根目录到路径
sys.path.insert(0, str(Path(__file__).parent))

from db_sql import execute_one, execute_insert_return_id

def create_default_user():
    """创建默认用户（纯 SQL 方式）"""
    try:
        # 检查是否已存在默认用户
        existing_user = execute_one(
            "SELECT id, username FROM users WHERE username = %s",
            ("default_user",)
        )
        
        if existing_user:
            print(f"✅ 默认用户已存在: ID={existing_user['id']}, username={existing_user['username']}")
            return existing_user
        
        # 使用 SQL INSERT 创建默认用户
        insert_sql = """
            INSERT INTO users (username, email, created_at, updated_at)
            VALUES (%s, %s, NOW(), NOW())
            RETURNING id
        """
        user_id = execute_insert_return_id(insert_sql, ("default_user", "default@example.com"))
        
        # 查询创建的用户信息
        user = execute_one(
            "SELECT id, username, email FROM users WHERE id = %s",
            (user_id,)
        )
        
        print(f"✅ 默认用户创建成功!")
        print(f"   - ID: {user['id']}")
        print(f"   - Username: {user['username']}")
        print(f"   - Email: {user['email']}")
        
        return user
    except Exception as e:
        print(f"❌ 创建默认用户失败: {e}")
        raise


if __name__ == "__main__":
    print("🚀 开始创建默认用户...")
    create_default_user()
    print("✨ 完成！")

