#!/usr/bin/env python3
"""
数据库迁移脚本
自动从 .env 文件读取 DATABASE_URL 并执行迁移
"""
import os
import sys
from pathlib import Path
from dotenv import load_dotenv
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

# 加载 .env 文件
env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=env_path)

# 获取数据库连接 URL
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    print("❌ 错误: DATABASE_URL 未配置！")
    print("请在 .env 文件中设置 DATABASE_URL")
    print("示例: DATABASE_URL=postgresql://user:password@host:port/database")
    sys.exit(1)

# 读取迁移 SQL 文件
migration_file = Path(__file__).parent / "sql" / "auth_migration.sql"
if not migration_file.exists():
    print(f"❌ 错误: 迁移文件不存在: {migration_file}")
    sys.exit(1)

print(f"📖 读取迁移文件: {migration_file}")
with open(migration_file, 'r', encoding='utf-8') as f:
    migration_sql = f.read()

print(f"🔌 连接数据库...")
print(f"   DATABASE_URL: {DATABASE_URL.split('@')[0]}@***")  # 隐藏密码

try:
    # 连接数据库
    conn = psycopg2.connect(DATABASE_URL)
    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    cur = conn.cursor()
    
    print("✅ 数据库连接成功")
    print("🚀 开始执行迁移...")
    
    # 执行迁移 SQL
    cur.execute(migration_sql)
    
    print("✅ 迁移执行成功！")
    print("\n已完成的迁移:")
    print("  - 扩展 users 表，添加认证相关字段")
    print("  - 创建 email_verification_codes 表")
    print("  - 创建相关索引")
    
    cur.close()
    conn.close()
    
except psycopg2.Error as e:
    print(f"❌ 数据库错误: {e}")
    sys.exit(1)
except Exception as e:
    print(f"❌ 错误: {e}")
    sys.exit(1)
