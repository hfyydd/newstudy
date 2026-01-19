import os
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

def check_notes():
    if not DATABASE_URL:
        print("DATABASE_URL not found in .env")
        return

    # User explicitly mentioned PostgreSQL, so we use DATABASE_URL from .env
    print(f"Connecting to: {DATABASE_URL}")
    engine = create_engine(DATABASE_URL)
    Session = sessionmaker(bind=engine)
    session = Session()

    try:
        # Check if notes table exists and its content
        result = session.execute(text("SELECT id, title, created_at FROM notes ORDER BY created_at DESC LIMIT 10;"))
        rows = result.fetchall()
        print(f"\n--- Recent Notes (PostgreSQL) ---")
        print(f"Total notes found: {len(rows)}")
        for row in rows:
            print(f"ID: {row[0]}, Title: {row[1]}, Created At: {row[2]}")
            
        # Also check card count
        result = session.execute(text("SELECT count(*) FROM flash_cards;"))
        card_count = result.scalar()
        print(f"Total flash cards: {card_count}")
        
    except Exception as e:
        print(f"Error querying database: {e}")
    finally:
        session.close()

if __name__ == "__main__":
    check_notes()
