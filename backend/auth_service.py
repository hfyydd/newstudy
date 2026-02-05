"""
认证服务模块
处理用户认证相关的业务逻辑
"""
import logging
from datetime import datetime, timezone
from typing import Optional, Dict, Any
from db_sql import get_db_cursor
from auth_utils import (
    create_access_token,
    create_refresh_token,
    verify_token,
    generate_verification_code,
    get_verification_code_expires_at,
)

logger = logging.getLogger(__name__)


def get_or_create_user_by_email(
    email: str,
    display_name: Optional[str] = None,
    auth_provider: str = "email",
    email_verified: bool = False,
    avatar_url: Optional[str] = None,
    cur=None
) -> Dict[str, Any]:
    """
    根据邮箱获取或创建用户
    
    Args:
        email: 用户邮箱
        display_name: 显示名称
        auth_provider: 认证提供商
        email_verified: 邮箱是否已验证
        avatar_url: 头像URL
        cur: 数据库游标
    
    Returns:
        用户信息字典
    """
    if cur is None:
        with get_db_cursor() as cur:
            return get_or_create_user_by_email(
                email, display_name, auth_provider, email_verified, avatar_url, cur
            )
    
    # 先尝试查找用户
    cur.execute(
        "SELECT id, email, display_name, auth_provider, email_verified, avatar_url, created_at "
        "FROM users WHERE email = %s",
        (email,)
    )
    user = cur.fetchone()
    
    if user:
        # 用户已存在，更新信息
        update_fields = []
        update_values = []
        
        if display_name and display_name != user.get('display_name'):
            update_fields.append("display_name = %s")
            update_values.append(display_name)
        
        if avatar_url and avatar_url != user.get('avatar_url'):
            update_fields.append("avatar_url = %s")
            update_values.append(avatar_url)
        
        if auth_provider != user.get('auth_provider'):
            update_fields.append("auth_provider = %s")
            update_values.append(auth_provider)
        
        if email_verified and not user.get('email_verified'):
            update_fields.append("email_verified = %s")
            update_values.append(True)
        
        update_fields.append("last_login_at = %s")
        update_values.append(datetime.now(timezone.utc))
        
        if update_fields:
            update_values.append(email)
            cur.execute(
                f"UPDATE users SET {', '.join(update_fields)}, updated_at = NOW() WHERE email = %s",
                update_values
            )
        
        return dict(user)
    else:
        # 创建新用户
        username = email.split('@')[0]  # 使用邮箱前缀作为用户名
        # 确保用户名唯一
        base_username = username
        counter = 1
        while True:
            cur.execute("SELECT id FROM users WHERE username = %s", (username,))
            if not cur.fetchone():
                break
            username = f"{base_username}{counter}"
            counter += 1
        
        cur.execute(
            "INSERT INTO users (username, email, display_name, auth_provider, email_verified, avatar_url, last_login_at) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s) RETURNING id, email, display_name, auth_provider, email_verified, avatar_url, created_at",
            (username, email, display_name, auth_provider, email_verified, avatar_url, datetime.now(timezone.utc))
        )
        user = cur.fetchone()
        logger.info(f"创建新用户: {email}")
        return dict(user)


def save_verification_code(email: str, code: str, cur=None) -> None:
    """
    保存验证码到数据库
    
    Args:
        email: 邮箱地址
        code: 验证码
        cur: 数据库游标
    """
    if cur is None:
        with get_db_cursor() as cur:
            save_verification_code(email, code, cur)
            return
    
    expires_at = get_verification_code_expires_at()
    cur.execute(
        "INSERT INTO email_verification_codes (email, code, expires_at) VALUES (%s, %s, %s)",
        (email, code, expires_at)
    )
    logger.info(f"保存验证码: {email}")


def verify_verification_code(email: str, code: str, cur=None) -> bool:
    """
    验证邮箱验证码
    
    Args:
        email: 邮箱地址
        code: 验证码
        cur: 数据库游标
    
    Returns:
        是否验证成功
    """
    if cur is None:
        with get_db_cursor() as cur:
            return verify_verification_code(email, code, cur)
    
    # 查找未使用且未过期的验证码
    cur.execute(
        "SELECT id FROM email_verification_codes "
        "WHERE email = %s AND code = %s AND used = FALSE AND expires_at > NOW() "
        "ORDER BY created_at DESC LIMIT 1",
        (email, code)
    )
    result = cur.fetchone()
    
    if result:
        # 标记为已使用
        cur.execute(
            "UPDATE email_verification_codes SET used = TRUE WHERE id = %s",
            (result['id'],)
        )
        return True
    
    return False


def save_refresh_token(user_id: int, refresh_token: str, cur=None) -> None:
    """
    保存 Refresh Token 到数据库
    
    Args:
        user_id: 用户ID
        refresh_token: Refresh Token
        cur: 数据库游标
    """
    if cur is None:
        with get_db_cursor() as cur:
            save_refresh_token(user_id, refresh_token, cur)
            return
    
    from datetime import timedelta
    from config import REFRESH_TOKEN_EXPIRE_DAYS
    
    expires_at = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    cur.execute(
        "UPDATE users SET refresh_token = %s, refresh_token_expires_at = %s WHERE id = %s",
        (refresh_token, expires_at, user_id)
    )


def verify_refresh_token(refresh_token: str, cur=None) -> Optional[Dict[str, Any]]:
    """
    验证 Refresh Token
    
    Args:
        refresh_token: Refresh Token
        cur: 数据库游标
    
    Returns:
        用户信息字典，如果 Token 无效则返回 None
    """
    if cur is None:
        with get_db_cursor() as cur:
            return verify_refresh_token(refresh_token, cur)
    
    # 先验证 Token 格式
    payload = verify_token(refresh_token)
    if not payload or payload.get('type') != 'refresh':
        return None
    
    user_id = payload.get('sub')  # 假设 user_id 存储在 'sub' 字段
    if not user_id:
        return None
    
    # 检查数据库中的 Token
    cur.execute(
        "SELECT id, email, display_name, auth_provider, email_verified, avatar_url "
        "FROM users WHERE id = %s AND refresh_token = %s AND refresh_token_expires_at > NOW()",
        (user_id, refresh_token)
    )
    user = cur.fetchone()
    
    if user:
        return dict(user)
    
    return None


def get_user_by_id(user_id: int, cur=None) -> Optional[Dict[str, Any]]:
    """
    根据用户ID获取用户信息
    
    Args:
        user_id: 用户ID
        cur: 数据库游标
    
    Returns:
        用户信息字典，如果不存在则返回 None
    """
    if cur is None:
        with get_db_cursor() as cur:
            return get_user_by_id(user_id, cur)
    
    cur.execute(
        "SELECT id, email, display_name, auth_provider, email_verified, avatar_url, created_at "
        "FROM users WHERE id = %s",
        (user_id,)
    )
    user = cur.fetchone()
    
    if user:
        return dict(user)
    
    return None


def clear_refresh_token(user_id: int, cur=None) -> None:
    """
    清除用户的 Refresh Token（用于登出）
    
    Args:
        user_id: 用户ID
        cur: 数据库游标
    """
    if cur is None:
        with get_db_cursor() as cur:
            clear_refresh_token(user_id, cur)
            return
    
    cur.execute(
        "UPDATE users SET refresh_token = NULL, refresh_token_expires_at = NULL WHERE id = %s",
        (user_id,)
    )
