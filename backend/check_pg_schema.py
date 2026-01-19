import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

def check_schema():
    if not DATABASE_URL:
        print("DATABASE_URL not found in .env")
        return

    print(f"Connecting to: {DATABASE_URL}")
    engine = create_engine(DATABASE_URL)
    
    try:
        with engine.connect() as conn:
            # Get table schema
            result = conn.execute(text("""
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_name = 'notes'
                ORDER BY ordinal_position;
            """))
            print("\n--- Notes Table Schema ---")
            for row in result:
                print(f"Column: {row[0]}, Type: {row[1]}, Nullable: {row[2]}, Default: {row[3]}")
                
            # Check constraints
            result = conn.execute(text("""
                SELECT conname, pg_get_constraintdef(c.oid)
                FROM pg_constraint c
                JOIN pg_namespace n ON n.oid = c.connamespace
                WHERE contype = 'p' AND conrelid = 'notes'::regclass;
            """))
            print("\n--- Primary Key Constraint ---")
            for row in result:
                print(f"Name: {row[0]}, Definition: {row[1]}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    check_schema()
