
import os
import psycopg2
from urllib.parse import urlparse

# 数据库连接 URL
DATABASE_URL = "postgresql://newstudy:newstudy123@localhost:5433/newstudy_db"

def add_column():
    print(f"Connecting to {DATABASE_URL}...")
    try:
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = True
        cur = conn.cursor()
        
        print("Adding column 'selected_role' to 'learning_records'...")
        sql = """
        ALTER TABLE learning_records 
        ADD COLUMN IF NOT EXISTS selected_role VARCHAR(50);
        """
        cur.execute(sql)
        print("✅ Column added successfully (or already existed).")
        
        cur.close()
        conn.close()
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    add_column()
