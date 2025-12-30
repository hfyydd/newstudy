"""
SQLite 数据库实现
用于存储笔记和闪词卡片数据
"""

import sqlite3
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional
from uuid import uuid4


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
        self.status = status  # notStarted, needsReview, needsImprove, mastered
        self.created_at = created_at or datetime.now()
        self.last_reviewed_at = last_reviewed_at


class Database:
    """SQLite 数据库"""

    def __init__(self, db_path: str = "notes.db"):
        """
        初始化数据库连接
        
        Args:
            db_path: 数据库文件路径，默认为 notes.db
        """
        self.db_path = db_path
        self._init_db()

    def _get_connection(self) -> sqlite3.Connection:
        """获取数据库连接"""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row  # 使用 Row 工厂，可以通过列名访问
        return conn

    def _init_db(self):
        """初始化数据库表结构"""
        conn = self._get_connection()
        try:
            cursor = conn.cursor()

            # 创建笔记表
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS notes (
                    id TEXT PRIMARY KEY,
                    title TEXT,
                    content TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                )
            """)

            # 创建闪词卡片表
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS flash_cards (
                    id TEXT PRIMARY KEY,
                    note_id TEXT NOT NULL,
                    term TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'notStarted',
                    created_at TEXT NOT NULL,
                    last_reviewed_at TEXT,
                    FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
                    UNIQUE(note_id, term)
                )
            """)

            # 创建索引以提高查询性能
            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_flash_cards_note_id 
                ON flash_cards(note_id)
            """)
            
            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_flash_cards_status 
                ON flash_cards(status)
            """)

            conn.commit()
        finally:
            conn.close()

    def create_note(
        self, title: Optional[str], content: str
    ) -> Note:
        """创建笔记"""
        note_id = str(uuid4())
        now = datetime.now()
        now_str = now.isoformat()

        conn = self._get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO notes (id, title, content, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?)
            """, (note_id, title, content, now_str, now_str))
            conn.commit()
        finally:
            conn.close()

        return Note(
            note_id=note_id,
            title=title,
            content=content,
            created_at=now,
            updated_at=now,
        )

    def get_note(self, note_id: str) -> Optional[Note]:
        """获取笔记"""
        conn = self._get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT id, title, content, created_at, updated_at
                FROM notes
                WHERE id = ?
            """, (note_id,))
            row = cursor.fetchone()

            if not row:
                return None

            return Note(
                note_id=row["id"],
                title=row["title"],
                content=row["content"],
                created_at=datetime.fromisoformat(row["created_at"]),
                updated_at=datetime.fromisoformat(row["updated_at"]),
            )
        finally:
            conn.close()

    def list_notes(self) -> List[Note]:
        """获取所有笔记列表"""
        conn = self._get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT id, title, content, created_at, updated_at
                FROM notes
                ORDER BY updated_at DESC
            """)
            rows = cursor.fetchall()

            notes = []
            for row in rows:
                notes.append(Note(
                    note_id=row["id"],
                    title=row["title"],
                    content=row["content"],
                    created_at=datetime.fromisoformat(row["created_at"]),
                    updated_at=datetime.fromisoformat(row["updated_at"]),
                ))
            return notes
        finally:
            conn.close()

    def create_flash_cards(self, note_id: str, terms: List[str]) -> List[FlashCard]:
        """为笔记创建闪词卡片"""
        # 检查笔记是否存在
        if not self.get_note(note_id):
            raise ValueError(f"笔记 {note_id} 不存在")

        now = datetime.now()
        now_str = now.isoformat()
        new_cards = []

        conn = self._get_connection()
        try:
            cursor = conn.cursor()

            # 获取现有的词条，用于去重
            cursor.execute("""
                SELECT term FROM flash_cards WHERE note_id = ?
            """, (note_id,))
            existing_terms = {row["term"] for row in cursor.fetchall()}

            # 插入新词条
            for term in terms:
                # 如果已存在相同的词条，跳过（保留原有的学习状态）
                if term in existing_terms:
                    continue

                card_id = str(uuid4())
                cursor.execute("""
                    INSERT INTO flash_cards (id, note_id, term, status, created_at)
                    VALUES (?, ?, ?, ?, ?)
                """, (card_id, note_id, term, "notStarted", now_str))

                new_cards.append(FlashCard(
                    card_id=card_id,
                    note_id=note_id,
                    term=term,
                    status="notStarted",
                    created_at=now,
                ))

            # 更新笔记的更新时间
            cursor.execute("""
                UPDATE notes SET updated_at = ? WHERE id = ?
            """, (now_str, note_id))

            conn.commit()
        finally:
            conn.close()

        return new_cards

    def get_flash_cards(self, note_id: str) -> List[FlashCard]:
        """获取笔记的所有闪词卡片"""
        conn = self._get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT id, note_id, term, status, created_at, last_reviewed_at
                FROM flash_cards
                WHERE note_id = ?
                ORDER BY created_at ASC
            """, (note_id,))
            rows = cursor.fetchall()

            cards = []
            for row in rows:
                cards.append(FlashCard(
                    card_id=row["id"],
                    note_id=row["note_id"],
                    term=row["term"],
                    status=row["status"],
                    created_at=datetime.fromisoformat(row["created_at"]),
                    last_reviewed_at=datetime.fromisoformat(row["last_reviewed_at"])
                    if row["last_reviewed_at"] else None,
                ))
            return cards
        finally:
            conn.close()

    def get_flash_card_progress(self, note_id: str) -> Dict[str, int]:
        """获取闪词学习进度统计"""
        conn = self._get_connection()
        try:
            cursor = conn.cursor()

            # 获取总数
            cursor.execute("""
                SELECT COUNT(*) as total FROM flash_cards WHERE note_id = ?
            """, (note_id,))
            total = cursor.fetchone()["total"]

            # 按状态统计
            cursor.execute("""
                SELECT status, COUNT(*) as count
                FROM flash_cards
                WHERE note_id = ?
                GROUP BY status
            """, (note_id,))
            status_counts = {row["status"]: row["count"] for row in cursor.fetchall()}

            return {
                "total": total,
                "mastered": status_counts.get("mastered", 0),
                "needsReview": status_counts.get("needsReview", 0),
                "needsImprove": status_counts.get("needsImprove", 0),
                "notStarted": status_counts.get("notStarted", 0),
            }
        finally:
            conn.close()


# 全局数据库实例
# 数据库文件存储在 backend 目录下
_db_path = Path(__file__).parent / "notes.db"
db = Database(str(_db_path))
