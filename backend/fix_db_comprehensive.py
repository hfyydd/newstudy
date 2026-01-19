
import psycopg2

# 数据库连接 URL
DATABASE_URL = "postgresql://newstudy:newstudy123@localhost:5433/newstudy_db"

def fix_schema():
    print(f"Connecting to {DATABASE_URL}...")
    try:
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = True
        cur = conn.cursor()
        
        print("Checking 'learning_records' table columns and adding if missing...")
        
        # 定义需要检查/添加的列
        columns_to_add = [
            ("selected_role", "VARCHAR(50)"),
            ("user_explanation", "TEXT"),
            ("score", "INTEGER"),
            ("ai_feedback", "TEXT"),  # 存储 JSON 字符串
            ("status", "VARCHAR(20)"), # 存储 'MASTERED' 等
            ("attempt_number", "INTEGER DEFAULT 1"),
            ("attempted_at", "TIMESTAMP DEFAULT NOW()"),
            ("card_id", "INTEGER"), # 假设 card.id 是 bigserial/integer? server.py 使用 payload.card_id (str?) 
            ("note_id", "VARCHAR(50)"), # UUID string
        ]
        
        # 注意: card_id 和 note_id 可能已经存在且有外键。如果不存在再添加。
        # 这里主要补全后面加的业务字段。

        for col_name, col_type in columns_to_add:
            try:
                # 尝试添加列。如果已存在，PostgreSQL 会报错，我们捕获忽略。
                # 更好的方式是查询 information_schema，但简单粗暴也可以。
                # ALTER TABLE ... ADD COLUMN IF NOT EXISTS ... (Postgres 9.6+)
                
                print(f"Ensuring column '{col_name}' exists...")
                sql = f"ALTER TABLE learning_records ADD COLUMN IF NOT EXISTS {col_name} {col_type};"
                cur.execute(sql)
                print(f"✅ Checked/Added {col_name}")
                
            except Exception as e:
                print(f"⚠️ Error check/add {col_name}: {e}")

        cur.close()
        conn.close()
        print("\n🎉 Schema update complete!")
        
    except Exception as e:
        print(f"❌ Connection Failed: {e}")

if __name__ == "__main__":
    fix_schema()
