"""
PostgreSQL 数据库实现
用于存储笔记和闪词卡片数据
"""

from datetime import datetime, timedelta
from typing import Dict, List, Optional
from uuid import uuid4
import asyncpg
from contextlib import asynccontextmanager

from config import database_url


class Note:
    """笔记模型"""

    def __init__(
        self,
        note_id: str,
        title: Optional[str],
        content: str,
        created_at: datetime,
        updated_at: datetime,
    ):
        self.id = note_id
        self.title = title
        self.content = content
        self.created_at = created_at
        self.updated_at = updated_at


class FlashCard:
    """闪词卡片模型"""

    def __init__(
        self,
        card_id: str,
        note_id: str,
        term: str,
        status: str = "notStarted",
        created_at: Optional[datetime] = None,
        last_reviewed_at: Optional[datetime] = None,
    ):
        self.id = card_id
        self.note_id = note_id
        self.term = term
        self.status = status
        self.created_at = created_at or datetime.now()
        self.last_reviewed_at = last_reviewed_at


class Database:
    """PostgreSQL 异步数据库"""

    def __init__(self, db_url: str = database_url):
        """
        初始化数据库连接
        
        Args:
            db_url: PostgreSQL数据库连接URL
        """
        self.db_url = db_url
        self._connection_pool = None

    async def init_pool(self):
        """初始化连接池"""
        self._connection_pool = await asyncpg.create_pool(
            self.db_url,
            min_size=2,
            max_size=10,
            command_timeout=60
        )
        await self._init_db()

    @asynccontextmanager
    async def get_connection(self):
        """获取数据库连接的上下文管理器"""
        if not self._connection_pool:
            await self.init_pool()
        
        async with self._connection_pool.acquire() as connection:
            yield connection

    async def _init_db(self):
        """初始化数据库表结构"""
        async with self.get_connection() as conn:
            # 创建笔记表
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS notes (
                    id TEXT PRIMARY KEY,
                    title TEXT,
                    content TEXT NOT NULL,
                    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
                )
            """)

            # 创建闪词卡片表
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS flash_cards (
                    id TEXT PRIMARY KEY,
                    note_id TEXT NOT NULL,
                    term TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'notStarted',
                    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
                    last_reviewed_at TIMESTAMP WITH TIME ZONE,
                    FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
                    UNIQUE(note_id, term)
                )
            """)

            # 创建索引
            await conn.execute("CREATE INDEX IF NOT EXISTS idx_flash_cards_note_id ON flash_cards(note_id)")
            await conn.execute("CREATE INDEX IF NOT EXISTS idx_flash_cards_status ON flash_cards(status)")
            await conn.execute("CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at)")

            # 创建更新时间触发器函数
            await conn.execute("""
                CREATE OR REPLACE FUNCTION update_updated_at_column()
                RETURNS TRIGGER AS $$
                BEGIN
                    NEW.updated_at = NOW();
                    RETURN NEW;
                END;
                $$ language 'plpgsql'
            """)

            # 创建触发器
            await conn.execute("""
                DROP TRIGGER IF EXISTS update_notes_updated_at ON notes
            """)
            await conn.execute("""
                CREATE TRIGGER update_notes_updated_at 
                    BEFORE UPDATE ON notes 
                    FOR EACH ROW 
                    EXECUTE FUNCTION update_updated_at_column()
            """)

    async def create_note(self, title: Optional[str], content: str) -> Note:
        """创建笔记"""
        note_id = str(uuid4())
        now = datetime.now()
        
        async with self.get_connection() as conn:
            await conn.execute(
                """
                INSERT INTO notes (id, title, content, created_at, updated_at)
                VALUES ($1, $2, $3, $4, $5)
                """,
                note_id, title, content, now, now
            )
        
        return Note(note_id, title, content, now, now)

    async def get_note(self, note_id: str) -> Optional[Note]:
        """获取笔记"""
        async with self.get_connection() as conn:
            row = await conn.fetchrow(
                "SELECT id, title, content, created_at, updated_at FROM notes WHERE id = $1",
                note_id
            )
            
            if row:
                return Note(
                    row['id'],
                    row['title'],
                    row['content'],
                    row['created_at'],
                    row['updated_at']
                )
            return None

    async def update_note(self, note_id: str, title: Optional[str] = None, content: Optional[str] = None) -> Optional[Note]:
        """更新笔记"""
        if title is None and content is None:
            return await self.get_note(note_id)
        
        set_clauses = []
        params = []
        param_index = 1
        
        if title is not None:
            set_clauses.append(f"title = ${param_index}")
            params.append(title)
            param_index += 1
            
        if content is not None:
            set_clauses.append(f"content = ${param_index}")
            params.append(content)
            param_index += 1
        
        params.append(note_id)
        
        async with self.get_connection() as conn:
            await conn.execute(
                f"UPDATE notes SET {', '.join(set_clauses)} WHERE id = ${param_index}",
                *params
            )
        
        return await self.get_note(note_id)

    async def delete_note(self, note_id: str) -> bool:
        """删除笔记"""
        async with self.get_connection() as conn:
            result = await conn.execute(
                "DELETE FROM notes WHERE id = $1",
                note_id
            )
            return result != "DELETE 0"

    async def list_notes(self, limit: int = 50, offset: int = 0) -> List[Note]:
        """获取笔记列表"""
        async with self.get_connection() as conn:
            rows = await conn.fetch(
                """
                SELECT id, title, content, created_at, updated_at 
                FROM notes 
                ORDER BY created_at DESC 
                LIMIT $1 OFFSET $2
                """,
                limit, offset
            )
            
            return [
                Note(
                    row['id'],
                    row['title'],
                    row['content'],
                    row['created_at'],
                    row['updated_at']
                )
                for row in rows
            ]

    async def get_note_count(self) -> int:
        """获取笔记总数"""
        async with self.get_connection() as conn:
            row = await conn.fetchrow("SELECT COUNT(*) as count FROM notes")
            return row['count']

    async def create_flash_cards(self, note_id: str, terms: List[str]) -> List[FlashCard]:
        """创建闪词卡片"""
        cards = []
        now = datetime.now()
        
        async with self.get_connection() as conn:
            async with conn.transaction():
                for term in terms:
                    try:
                        card_id = str(uuid4())
                        await conn.execute(
                            """
                            INSERT INTO flash_cards (id, note_id, term, status, created_at)
                            VALUES ($1, $2, $3, $4, $5)
                            ON CONFLICT (note_id, term) DO NOTHING
                            """,
                            card_id, note_id, term, "notStarted", now
                        )
                        cards.append(FlashCard(card_id, note_id, term, "notStarted", now))
                    except Exception:
                        pass
        
        return cards

    async def get_flash_cards(self, note_id: str) -> List[FlashCard]:
        """获取闪词卡片"""
        async with self.get_connection() as conn:
            rows = await conn.fetch(
                """
                SELECT id, note_id, term, status, created_at, last_reviewed_at 
                FROM flash_cards 
                WHERE note_id = $1 
                ORDER BY created_at
                """,
                note_id
            )
            
            return [
                FlashCard(
                    row['id'],
                    row['note_id'],
                    row['term'],
                    row['status'],
                    row['created_at'],
                    row['last_reviewed_at']
                )
                for row in rows
            ]

    async def update_flash_card_status(self, card_id: str, status: str) -> bool:
        """更新闪词卡片状态"""
        async with self.get_connection() as conn:
            result = await conn.execute(
                """
                UPDATE flash_cards 
                SET status = $1, last_reviewed_at = $2 
                WHERE id = $3
                """,
                status, datetime.now(), card_id
            )
            return result != "UPDATE 0"

    async def get_flash_card_progress(self, note_id: str) -> Dict[str, int]:
        """获取闪词学习进度"""
        async with self.get_connection() as conn:
            rows = await conn.fetch(
                """
                SELECT status, COUNT(*) as count 
                FROM flash_cards 
                WHERE note_id = $1 
                GROUP BY status
                """,
                note_id
            )
            
            progress = {
                "total": 0,
                "notStarted": 0,
                "needsReview": 0,
                "needsImprove": 0,
                "mastered": 0
            }
            
            for row in rows:
                status = row['status']
                count = row['count']
                progress[status] = count
                progress["total"] += count
            
            return progress

    async def get_review_cards(self, limit: int = 50) -> List[FlashCard]:
        """获取需要复习的卡片"""
        async with self.get_connection() as conn:
            rows = await conn.fetch(
                """
                SELECT id, note_id, term, status, created_at, last_reviewed_at
                FROM flash_cards
                WHERE status IN ('NEEDS_REVIEW', 'NEEDS_IMPROVE')
                   OR (status = 'MASTERED' AND last_reviewed_at < NOW() - INTERVAL '7 days')
                   OR (status = 'NOT_STARTED' AND created_at < NOW() - INTERVAL '1 day')
                ORDER BY last_reviewed_at ASC NULLS FIRST, created_at ASC
                LIMIT $1
                """,
                limit
            )
            
            return [
                FlashCard(
                    row['id'],
                    row['note_id'],
                    row['term'],
                    row['status'],
                    row['created_at'],
                    row['last_reviewed_at']
                )
                for row in rows
            ]

    async def close(self):
        """关闭连接池"""
        if self._connection_pool:
            await self._connection_pool.close()


# 创建全局数据库实例
db = Database()