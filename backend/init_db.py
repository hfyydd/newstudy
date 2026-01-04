"""
数据库初始化脚本
用于创建数据库表和启用 pgvector 扩展
"""
import sys
from pathlib import Path

# 添加项目根目录到路径
sys.path.insert(0, str(Path(__file__).parent))

from database import engine, init_db
from sqlalchemy import text

try:
    from init_default_user import create_default_user
except ImportError:
    # 如果相对导入失败，尝试绝对导入
    import init_default_user
    create_default_user = init_default_user.create_default_user

def enable_pgvector():
    """启用 pgvector 扩展"""
    try:
        with engine.connect() as conn:
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
            conn.commit()
            print("✅ pgvector 扩展已启用")
    except Exception as e:
        print(f"⚠️ 启用 pgvector 扩展失败: {e}")
        print("   如果数据库不支持 pgvector，可以忽略此错误")


if __name__ == "__main__":
    print("🚀 开始初始化数据库...")
    
    # 启用 pgvector 扩展
    enable_pgvector()
    
    # 创建所有表
    init_db()
    
    # 创建默认用户
    print("\n" + "="*50)
    create_default_user()
    
    print("\n✨ 数据库初始化完成！")

