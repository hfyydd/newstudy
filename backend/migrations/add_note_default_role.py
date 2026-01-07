"""
数据库迁移：为 notes 表添加 default_role 字段
"""
import os
import psycopg2
import argparse
from dotenv import load_dotenv
from pathlib import Path

# Load environment variables
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(dotenv_path=env_path)

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError("DATABASE_URL not configured!")

def parse_database_url(url: str):
    import re
    pattern = r'postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)'
    match = re.match(pattern, url)
    if not match:
        raise ValueError(f"Invalid DATABASE_URL: {url}")
    return {
        'user': match.group(1),
        'password': match.group(2),
        'host': match.group(3),
        'port': match.group(4),
        'database': match.group(5),
    }

db_params = parse_database_url(DATABASE_URL)

def get_db_connection():
    return psycopg2.connect(**db_params)

def apply_migration():
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        print("🚀 Applying migration: Adding default_role to notes table...")
        
        # 添加 default_role 字段
        add_column_sql = """
            ALTER TABLE notes 
            ADD COLUMN IF NOT EXISTS default_role VARCHAR(50);
        """
        cur.execute(add_column_sql)
        
        # 添加注释
        comment_sql = """
            COMMENT ON COLUMN notes.default_role IS '笔记的默认学习角色（如：5岁孩子、小学生、中学生、大学生、研究生）';
        """
        cur.execute(comment_sql)
        
        conn.commit()
        print("✅ Migration applied: default_role column added to notes table!")

    except Exception as e:
        print(f"❌ Error applying migration: {e}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()

def rollback_migration():
    conn = None
    try:
        conn = get_db_connection()
        cur = conn.cursor()

        print("⏪ Rolling back migration: Removing default_role from notes table...")
        drop_column_sql = "ALTER TABLE notes DROP COLUMN IF EXISTS default_role;"
        cur.execute(drop_column_sql)
        conn.commit()
        print("✅ Rollback complete: default_role column removed.")

    except Exception as e:
        print(f"❌ Error rolling back migration: {e}")
        if conn:
            conn.rollback()
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Apply or rollback note default_role migration.")
    parser.add_argument("--rollback", action="store_true", help="Rollback the migration (drop column).")
    args = parser.parse_args()

    if args.rollback:
        rollback_migration()
    else:
        apply_migration()

