"""
认证工具模块
提供 JWT Token 生成、验证、密码哈希等功能
"""
import secrets
import string
from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any
from jose import JWTError, jwt
from passlib.context import CryptContext
from config import (
    JWT_SECRET_KEY,
    JWT_ALGORITHM,
    ACCESS_TOKEN_EXPIRE_MINUTES,
    REFRESH_TOKEN_EXPIRE_DAYS,
    VERIFICATION_CODE_EXPIRE_MINUTES,
    VERIFICATION_CODE_LENGTH,
)

# 密码加密上下文（用于未来可能的密码登录）
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def create_access_token(data: Dict[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """
    创建 Access Token
    
    Args:
        data: 要编码到 Token 中的数据（通常包含 user_id）
        expires_delta: 过期时间增量，如果为 None 则使用默认值
    
    Returns:
        JWT Token 字符串
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire, "iat": datetime.now(timezone.utc)})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
    return encoded_jwt


def create_refresh_token(data: Dict[str, Any]) -> str:
    """
    创建 Refresh Token
    
    Args:
        data: 要编码到 Token 中的数据（通常包含 user_id）
    
    Returns:
        JWT Token 字符串
    """
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "iat": datetime.now(timezone.utc), "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=JWT_ALGORITHM)
    return encoded_jwt


def verify_token(token: str) -> Optional[Dict[str, Any]]:
    """
    验证 Token 并返回解码后的数据
    
    Args:
        token: JWT Token 字符串
    
    Returns:
        解码后的数据字典，如果 Token 无效则返回 None
    """
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[JWT_ALGORITHM])
        return payload
    except JWTError:
        return None


def generate_verification_code() -> str:
    """
    生成随机验证码
    
    Returns:
        6位数字验证码字符串
    """
    return ''.join(secrets.choice(string.digits) for _ in range(VERIFICATION_CODE_LENGTH))


def get_verification_code_expires_at() -> datetime:
    """
    获取验证码过期时间
    
    Returns:
        过期时间（当前时间 + 5分钟）
    """
    return datetime.now(timezone.utc) + timedelta(minutes=VERIFICATION_CODE_EXPIRE_MINUTES)


def hash_password(password: str) -> str:
    """
    哈希密码（用于未来可能的密码登录）
    
    Args:
        password: 明文密码
    
    Returns:
        哈希后的密码
    """
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    验证密码（用于未来可能的密码登录）
    
    Args:
        plain_password: 明文密码
        hashed_password: 哈希后的密码
    
    Returns:
        是否匹配
    """
    return pwd_context.verify(plain_password, hashed_password)
