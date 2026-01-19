
import psycopg2

DATABASE_URL = "postgresql://newstudy:newstudy123@localhost:5433/newstudy_db"

def fix_id():
    print(f"Connecting to {DATABASE_URL}...")
    try:
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = True
        cur = conn.cursor()
        
        # Check column type
        cur.execute("SELECT data_type FROM information_schema.columns WHERE table_name = 'learning_records' AND column_name = 'id';")
        res = cur.fetchone()
        if not res:
            print("❌ ID column not found!")
            return
            
        dtype = res[0]
        print(f"ID column type: {dtype}")
        
        if 'int' in dtype:
            print("Configuring ID as SERIAL (Sequence)...")
            try:
                # Create sequence if not exists
                cur.execute("CREATE SEQUENCE IF NOT EXISTS learning_records_id_seq;")
                # Set default
                cur.execute("ALTER TABLE learning_records ALTER COLUMN id SET DEFAULT nextval('learning_records_id_seq');")
                # Sync sequence (optional, just in case)
                cur.execute("SELECT setval('learning_records_id_seq', COALESCE((SELECT MAX(id) FROM learning_records), 1));")
                print("✅ ID default set to nextval sequence.")
            except Exception as e:
                print(f"⚠️ Error setting sequence: {e}")
                
        elif 'uuid' in dtype or 'text' in dtype or 'varchar' in dtype:
            print(f"Configuring ID ({dtype}) as UUID DEFAULT...")
            try:
                cur.execute("CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";")
                # 需要 cast 为 text
                cur.execute("ALTER TABLE learning_records ALTER COLUMN id SET DEFAULT gen_random_uuid()::text;")
                print("✅ ID default set to gen_random_uuid()::text.")
            except Exception as e:
                print(f"⚠️ Error setting UUID default: {e}")
                
        cur.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    fix_id()
