"""
SQLite 数据库实现
用于存储笔记和闪词卡片数据
"""

import sqlite3
from datetime import datetime, timedelta
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
        # 启用外键约束（SQLite 默认关闭，需要显式启用）
        conn.execute("PRAGMA foreign_keys = ON")
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
            # 创建复习计划表
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS review_schedule (
                    id TEXT PRIMARY KEY,
                    card_id TEXT NOT NULL UNIQUE,
                    next_review_at TEXT NOT NULL,
                    review_count INTEGER DEFAULT 0,
                    FOREIGN KEY (card_id) REFERENCES flash_cards(id) ON DELETE CASCADE
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
            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_review_schedule_next_review 
                ON review_schedule(next_review_at)
            """)
            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_review_schedule_card_id 
                ON review_schedule(card_id)
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

    def update_note(
        self, note_id: str, title: Optional[str] = None, content: Optional[str] = None
    ) -> Optional[Note]:
        """更新笔记"""
        # 检查笔记是否存在
        existing_note = self.get_note(note_id)
        if not existing_note:
            return None

        # 如果未提供新值，使用原有值
        new_title = title if title is not None else existing_note.title
        new_content = content if content is not None else existing_note.content

        now = datetime.now()
        now_str = now.isoformat()

        conn = self._get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE notes 
                SET title = ?, content = ?, updated_at = ?
                WHERE id = ?
            """, (new_title, new_content, now_str, note_id))
            conn.commit()
        finally:
            conn.close()

        # 返回更新后的笔记
        return Note(
            note_id=note_id,
            title=new_title,
            content=new_content,
            created_at=existing_note.created_at,
            updated_at=now,
        )

    def delete_note(self, note_id: str) -> bool:
        """删除笔记（级联删除关联的闪词卡片）"""
        # 检查笔记是否存在
        if not self.get_note(note_id):
            return False

        conn = self._get_connection()
        try:
            cursor = conn.cursor()
            
            # 先统计要删除的闪词卡片数量（用于日志）
            cursor.execute("""
                SELECT COUNT(*) as count FROM flash_cards WHERE note_id = ?
            """, (note_id,))
            cards_count = cursor.fetchone()["count"]
            
            # 手动删除关联的闪词卡片（确保删除，即使外键约束未生效也能正常工作）
            cursor.execute("""
                DELETE FROM flash_cards WHERE note_id = ?
            """, (note_id,))
            deleted_cards_count = cursor.rowcount
            
            # 删除笔记
            cursor.execute("""
                DELETE FROM notes WHERE id = ?
            """, (note_id,))
            deleted_notes_count = cursor.rowcount
            
            conn.commit()
            
            if deleted_notes_count > 0:
                print(f"[Database] 删除笔记 {note_id}，同时删除了 {deleted_cards_count} 个关联的闪词卡片")
            
            return deleted_notes_count > 0
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

                # 为新词条创建复习计划（notStarted 状态：4小时后复习）
                next_review = now + timedelta(hours=4)
                next_review_str = next_review.isoformat()
                cursor.execute("""
                    INSERT INTO review_schedule (id, card_id, next_review_at, review_count)
                    VALUES (?, ?, ?, 0)
                """, (str(uuid4()), card_id, next_review_str))

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

    def update_flash_card_status(
        self, note_id: str, term: str, status: str
    ) -> bool:
        """更新闪词卡片的学习状态，并计算下次复习时间"""
        conn = self._get_connection()
        try:
            cursor = conn.cursor()
            now = datetime.now()
            now_str = now.isoformat()
            
            # 先获取卡片ID
            cursor.execute("""
                SELECT id FROM flash_cards 
                WHERE note_id = ? AND term = ?
            """, (note_id, term))
            row = cursor.fetchone()
            if not row:
                return False
            
            card_id = row["id"]
            
            # 更新状态和最后复习时间
            cursor.execute("""
                UPDATE flash_cards 
                SET status = ?, last_reviewed_at = ?
                WHERE note_id = ? AND term = ?
            """, (status, now_str, note_id, term))
            
            if cursor.rowcount == 0:
                return False
            
            # 根据状态计算下次复习时间
            if status == 'needsReview':
                next_review = now + timedelta(days=1)  # 1天后
            elif status == 'needsImprove':
                next_review = now + timedelta(days=3)  # 3天后
            elif status == 'mastered':
                next_review = now + timedelta(days=7)  # 7天后
            else:  # notStarted 或其他状态
                next_review = now + timedelta(hours=4)  # 4小时后
            
            next_review_str = next_review.isoformat()
            
            # 更新或创建复习计划
            cursor.execute("""
                INSERT INTO review_schedule (id, card_id, next_review_at, review_count)
                VALUES (?, ?, ?, 0)
                ON CONFLICT(card_id) DO UPDATE SET
                    next_review_at = ?,
                    review_count = review_count + 1
            """, (str(uuid4()), card_id, next_review_str, next_review_str))
            
            conn.commit()
            return True
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

    def get_learning_statistics(self) -> Dict[str, int]:
        """获取学习统计信息（全局统计）"""
        conn = self._get_connection()
        try:
            cursor = conn.cursor()

            # 统计已掌握的词条数
            cursor.execute("""
                SELECT COUNT(*) as count FROM flash_cards WHERE status = 'mastered'
            """)
            mastered = cursor.fetchone()["count"]

            # 统计累计学习词条数（所有词条）
            cursor.execute("""
                SELECT COUNT(*) as count FROM flash_cards
            """)
            total_terms = cursor.fetchone()["count"]

            # 计算连续天数（基于最后复习时间）
            # 注意：这是一个简化实现，实际应用中需要学习历史表来准确计算连续天数
            # 这里暂时返回0，因为需要更复杂的逻辑来计算连续天数
            consecutive_days = 0
            
            # 累计时长（分钟）- 暂时返回0，实际需要学习历史表来记录学习时长
            total_minutes = 0

            return {
                "mastered": mastered,
                "totalTerms": total_terms,
                "consecutiveDays": consecutive_days,
                "totalMinutes": total_minutes,
            }
        finally:
            conn.close()

    def get_today_review_statistics(self) -> Dict[str, int]:
        """获取今日复习统计信息（基于复习时间间隔）"""
        conn = self._get_connection()
        try:
            cursor = conn.cursor()
            now_str = datetime.now().isoformat()

            # 统计需要复习的词条总数（基于时间判断）
            # 条件：状态为 needsReview 或 needsImprove，且 next_review_at <= 当前时间
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM flash_cards fc
                INNER JOIN review_schedule rs ON fc.id = rs.card_id
                WHERE fc.status IN ('needsReview', 'needsImprove')
                  AND rs.next_review_at <= ?
            """, (now_str,))
            total = cursor.fetchone()["count"]

            # 统计困难词条数（needsReview，基于时间判断）
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM flash_cards fc
                INNER JOIN review_schedule rs ON fc.id = rs.card_id
                WHERE fc.status = 'needsReview'
                  AND rs.next_review_at <= ?
            """, (now_str,))
            needs_review = cursor.fetchone()["count"]

            # 统计需改进词条数（needsImprove，基于时间判断）
            cursor.execute("""
                SELECT COUNT(*) as count 
                FROM flash_cards fc
                INNER JOIN review_schedule rs ON fc.id = rs.card_id
                WHERE fc.status = 'needsImprove'
                  AND rs.next_review_at <= ?
            """, (now_str,))
            needs_improve = cursor.fetchone()["count"]

            return {
                "total": total,
                "needsReview": needs_review,
                "needsImprove": needs_improve,
            }
        finally:
            conn.close()

    def get_review_flash_cards(self, include_all: bool = False) -> List[FlashCard]:
        """
        获取闪词卡片列表（根据复习时间间隔过滤）
        
        Args:
            include_all: 如果为True，返回所有状态的词条；如果为False，只返回需要复习的词条（基于时间判断）
        """
        conn = self._get_connection()
        try:
            cursor = conn.cursor()
            now_str = datetime.now().isoformat()
            
            if include_all:
                # 返回所有状态的词条
                cursor.execute("""
                    SELECT fc.id, fc.note_id, fc.term, fc.status, fc.created_at, fc.last_reviewed_at
                    FROM flash_cards fc
                    ORDER BY 
                        CASE fc.status
                            WHEN 'needsReview' THEN 1
                            WHEN 'needsImprove' THEN 2
                            WHEN 'notStarted' THEN 3
                            WHEN 'mastered' THEN 4
                        END,
                        fc.created_at ASC
                """)
            else:
                # 只返回需要复习的词条（基于时间判断）
                # 条件：状态为 needsReview 或 needsImprove，且 next_review_at <= 当前时间
                cursor.execute("""
                    SELECT fc.id, fc.note_id, fc.term, fc.status, fc.created_at, fc.last_reviewed_at
                    FROM flash_cards fc
                    INNER JOIN review_schedule rs ON fc.id = rs.card_id
                    WHERE fc.status IN ('needsReview', 'needsImprove')
                      AND rs.next_review_at <= ?
                    ORDER BY 
                        CASE fc.status
                            WHEN 'needsReview' THEN 1
                            WHEN 'needsImprove' THEN 2
                        END,
                        rs.next_review_at ASC
                """, (now_str,))
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


# 全局数据库实例
# 数据库文件存储在 backend 目录下
_db_path = Path(__file__).parent / "notes.db"
db = Database(str(_db_path))
