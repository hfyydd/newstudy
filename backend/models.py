"""
数据库模型定义
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Enum as SQLEnum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum

try:
    from .database import Base
except ImportError:
    from database import Base


class CardStatus(str, enum.Enum):
    """闪词卡片状态枚举"""
    NOT_STARTED = "not_started"  # 未学习
    NEEDS_REVIEW = "needs_review"  # 待复习
    NEEDS_IMPROVE = "needs_improve"  # 需改进
    NOT_MASTERED = "not_mastered"  # 未掌握
    MASTERED = "mastered"  # 已掌握


class User(Base):
    """用户表"""
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False, comment="用户名")
    email = Column(String(100), unique=True, index=True, nullable=True, comment="邮箱")
    created_at = Column(DateTime(timezone=True), server_default=func.now(), comment="创建时间")
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), comment="更新时间")

    # 关系
    notes = relationship("Note", back_populates="user", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<User(id={self.id}, username='{self.username}')>"


class Note(Base):
    """笔记表"""
    __tablename__ = "notes"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True, comment="用户ID")
    title = Column(String(200), nullable=False, comment="笔记标题")
    content = Column(Text, nullable=True, comment="原始内容")
    markdown_content = Column(Text, nullable=True, comment="Markdown格式的笔记内容")
    created_at = Column(DateTime(timezone=True), server_default=func.now(), comment="创建时间")
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), comment="更新时间")

    # 关系
    user = relationship("User", back_populates="notes")
    flash_cards = relationship("FlashCard", back_populates="note", cascade="all, delete-orphan", order_by="FlashCard.id")

    def __repr__(self):
        return f"<Note(id={self.id}, title='{self.title[:30]}...')>"


class FlashCard(Base):
    """闪词表"""
    __tablename__ = "flash_cards"

    id = Column(Integer, primary_key=True, index=True)
    note_id = Column(Integer, ForeignKey("notes.id", ondelete="CASCADE"), nullable=False, index=True, comment="笔记ID")
    term = Column(String(100), nullable=False, comment="闪词内容")
    status = Column(
        SQLEnum(CardStatus, name="card_status"),
        default=CardStatus.NOT_STARTED,
        nullable=False,
        comment="学习状态"
    )
    # 学习记录
    review_count = Column(Integer, default=0, comment="复习次数")
    last_reviewed_at = Column(DateTime(timezone=True), nullable=True, comment="最后复习时间")
    mastered_at = Column(DateTime(timezone=True), nullable=True, comment="掌握时间")
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now(), comment="创建时间")
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), comment="更新时间")

    # 关系
    note = relationship("Note", back_populates="flash_cards")

    def __repr__(self):
        return f"<FlashCard(id={self.id}, term='{self.term}', status='{self.status}')>"

