"""
认证辅助函数
用于在需要认证的 API 中获取用户ID
"""
from typing import Optional
from fastapi import HTTPException, Depends
from auth_middleware import get_current_user_id
from get_default_user import get_default_user_id


def get_user_id_optional(
    current_user_id: Optional[int] = Depends(get_current_user_id)
) -> int:
    """
    获取用户ID（可选认证）
    
    如果提供了认证 Token，使用认证用户ID
    否则回退到默认用户（向后兼容）
    
    注意：这个函数用于向后兼容，新 API 应该使用 get_user_id_required
    """
    if current_user_id:
        return current_user_id
    return get_default_user_id()


def get_user_id_required(
    current_user_id: int = Depends(get_current_user_id)
) -> int:
    """
    获取用户ID（必须认证）
    
    如果未提供认证 Token，将返回 401 错误
    
    这是推荐的方式，用于需要认证的 API
    """
    return current_user_id
