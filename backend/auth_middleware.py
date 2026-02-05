"""
JWT 认证中间件
用于保护需要登录的 API 接口
"""
from fastapi import HTTPException, Depends, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from auth_utils import verify_token
from auth_service import get_user_by_id
from db_sql import get_db_cursor

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    request: Request = None
) -> dict:
    """
    获取当前登录用户
    
    使用方法：
    @app.get("/protected")
    def protected_route(current_user: dict = Depends(get_current_user)):
        # current_user 包含用户信息
        user_id = current_user["id"]
        ...
    """
    token = credentials.credentials
    
    # 验证 Token
    payload = verify_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="无效的 Token")
    
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="无效的 Token")
    
    # 获取用户信息
    with get_db_cursor() as cur:
        user = get_user_by_id(user_id, cur)
        if not user:
            raise HTTPException(status_code=404, detail="用户不存在")
    
    return user


def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> int:
    """
    获取当前登录用户的 ID（简化版本，不需要查询数据库）
    
    使用方法：
    @app.get("/protected")
    def protected_route(user_id: int = Depends(get_current_user_id)):
        # user_id 是当前用户的 ID
        ...
    """
    token = credentials.credentials
    
    # 验证 Token
    payload = verify_token(token)
    if not payload:
        raise HTTPException(status_code=401, detail="无效的 Token")
    
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="无效的 Token")
    
    return user_id
