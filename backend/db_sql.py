"""
数据库连接和操作（纯 SQL 方式）
使用 psycopg2 直接执行 SQL 语句
"""
import os
import psycopg2
from psycopg2.extras import RealDictCursor
from psycopg2.pool import SimpleConnectionPool
from contextlib import contextmanager
from dotenv import load_dotenv
from pathlib import Path
from typing import Generator, Optional, Dict, List, Any

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

# 解析 DATABASE_URL
def parse_database_url(url: str) -> Dict[str, str]:
    """解析数据库连接 URL"""
    # postgresql://user:password@host:port/database
    import re
    pattern = r'postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)'
    match = re.match(pattern, url)
    if not match:
        raise ValueError(f"无效的 DATABASE_URL: {url}")
    
    return {
        'user': match.group(1),
        'password': match.group(2),
        'host': match.group(3),
        'port': match.group(4),
        'database': match.group(5),
    }

# 解析连接参数
db_params = parse_database_url(DATABASE_URL)

# 创建连接池（可选，用于生产环境）
# 这里使用简单连接，每次操作时创建新连接
# 如果需要连接池，可以使用 SimpleConnectionPool


@contextmanager
def get_db_connection() -> Generator[psycopg2.extensions.connection, None, None]:
    """
    获取数据库连接的上下文管理器
    
    使用示例:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute("SELECT * FROM users WHERE id = %s", (1,))
                result = cur.fetchone()
    """
    conn = None
    try:
        conn = psycopg2.connect(
            host=db_params['host'],
            port=db_params['port'],
            database=db_params['database'],
            user=db_params['user'],
            password=db_params['password'],
        )
        yield conn
        conn.commit()
    except Exception:
        if conn:
            conn.rollback()
        raise
    finally:
        if conn:
            conn.close()


def get_db_cursor():
    """
    获取数据库游标的生成器（用于 FastAPI 依赖注入）
    
    使用示例:
        @app.get("/notes")
        def list_notes(cur = Depends(get_db_cursor)):
            cur.execute("SELECT * FROM notes")
            return cur.fetchall()
    """
    conn = None
    cur = None
    try:
        conn = psycopg2.connect(
            host=db_params['host'],
            port=db_params['port'],
            database=db_params['database'],
            user=db_params['user'],
            password=db_params['password'],
        )
        cur = conn.cursor(cursor_factory=RealDictCursor)
        yield cur
        conn.commit()
    except Exception:
        if conn:
            conn.rollback()
        raise
    finally:
        if cur:
            cur.close()
        if conn:
            conn.close()


def execute_query(query: str, params: Optional[tuple] = None) -> List[Dict[str, Any]]:
    """
    执行查询 SQL，返回结果列表
    
    Args:
        query: SQL 查询语句
        params: 查询参数（用于防止 SQL 注入）
    
    Returns:
        结果列表，每行是一个字典
    """
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, params)
            return [dict(row) for row in cur.fetchall()]


def execute_one(query: str, params: Optional[tuple] = None) -> Optional[Dict[str, Any]]:
    """
    执行查询 SQL，返回单行结果
    
    Args:
        query: SQL 查询语句
        params: 查询参数
    
    Returns:
        单行结果字典，如果没有结果返回 None
    """
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(query, params)
            row = cur.fetchone()
            return dict(row) if row else None


def execute_update(query: str, params: Optional[tuple] = None) -> int:
    """
    执行更新 SQL（INSERT, UPDATE, DELETE），返回受影响的行数
    
    Args:
        query: SQL 更新语句
        params: 更新参数
    
    Returns:
        受影响的行数
    """
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, params)
            conn.commit()
            return cur.rowcount


def execute_insert_return_id(query: str, params: Optional[tuple] = None) -> int:
    """
    执行 INSERT SQL，返回插入记录的 ID
    
    Args:
        query: INSERT 语句，必须包含 RETURNING id
        params: 插入参数
    
    Returns:
        插入记录的 ID
    """
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(query, params)
            result = cur.fetchone()
            conn.commit()
            return result[0] if result else None

