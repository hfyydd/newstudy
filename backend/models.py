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
    NEEDS_REVIEW = "needs_review"  # 需巩固（70-89分）
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
    # 学习统计
    review_count = Column(Integer, default=0, comment="复习次数")
    last_reviewed_at = Column(DateTime(timezone=True), nullable=True, comment="最后复习时间")
    mastered_at = Column(DateTime(timezone=True), nullable=True, comment="掌握时间")
    # 时间戳
    created_at = Column(DateTime(timezone=True), server_default=func.now(), comment="创建时间")
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), comment="更新时间")

    # 关系
    note = relationship("Note", back_populates="flash_cards")
    learning_records = relationship("LearningRecord", back_populates="flash_card", cascade="all, delete-orphan", order_by="LearningRecord.attempted_at.desc()")

    def __repr__(self):
        return f"<FlashCard(id={self.id}, term='{self.term}', status='{self.status}')>"


class LearningRecord(Base):
    """学习记录表 - 记录每次费曼学习的详细信息"""
    __tablename__ = "learning_records"

    id = Column(Integer, primary_key=True, index=True)
    card_id = Column(Integer, ForeignKey("flash_cards.id", ondelete="CASCADE"), nullable=False, index=True, comment="闪词卡片ID")
    note_id = Column(Integer, ForeignKey("notes.id", ondelete="CASCADE"), nullable=False, index=True, comment="笔记ID（冗余，便于查询）")
    
    # 学习信息
    selected_role = Column(String(50), nullable=False, comment="选择的角色（如5岁孩子、同事等）")
    user_explanation = Column(Text, nullable=False, comment="用户的解释内容")
    score = Column(Integer, nullable=False, comment="AI评估分数（0-100）")
    ai_feedback = Column(Text, nullable=False, comment="AI反馈内容")
    status = Column(
        SQLEnum(CardStatus, name="card_status"),
        nullable=False,
        comment="本次评估的状态"
    )
    
    # 尝试信息
    attempt_number = Column(Integer, nullable=False, default=1, comment="第几次尝试（同一卡片）")
    
    # 时间戳
    attempted_at = Column(DateTime(timezone=True), server_default=func.now(), comment="尝试时间")

    # 关系
    flash_card = relationship("FlashCard", back_populates="learning_records")
    note = relationship("Note")

    def __repr__(self):
        return f"<LearningRecord(id={self.id}, card_id={self.card_id}, score={self.score}, status='{self.status}')>"

