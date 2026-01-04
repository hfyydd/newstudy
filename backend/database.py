"""
数据库配置和连接
"""
import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
from pathlib import Path

# 加载环境变量
env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=env_path)

# 获取数据库连接 URL（必须从 .env 文件配置）
DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise ValueError(
        "DATABASE_URL 未配置！请在 .env 文件中设置 DATABASE_URL。\n"
        "示例：DATABASE_URL=postgresql://newstudy:newstudy123@localhost:5433/newstudy_db"
    )

# 创建数据库引擎
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,  # 连接前检查连接是否有效
    echo=False,  # 设置为 True 可以打印 SQL 语句（调试用）
)

# 创建会话工厂
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 创建基础模型类
Base = declarative_base()


def get_db():
    """
    获取数据库会话（用于依赖注入）
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """
    初始化数据库（创建所有表）
    """
    # 导入所有模型，确保它们被注册
    try:
        from .models import User, Note, FlashCard  # noqa: F401
    except ImportError:
        from models import User, Note, FlashCard  # noqa: F401
    
    # 创建所有表
    Base.metadata.create_all(bind=engine)
    print("✅ 数据库表创建成功！")


def drop_db():
    """
    删除所有表（谨慎使用！）
    """
    try:
        from .models import User, Note, FlashCard  # noqa: F401
    except ImportError:
        from models import User, Note, FlashCard  # noqa: F401
    
    Base.metadata.drop_all(bind=engine)
    print("⚠️ 所有数据库表已删除！")

