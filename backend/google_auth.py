"""
Google 认证工具
用于验证 Google ID Token
"""
import logging
from typing import Optional, Dict, Any
from config import GOOGLE_CLIENT_ID

logger = logging.getLogger(__name__)


def verify_google_id_token(id_token: str) -> Optional[Dict[str, Any]]:
    """
    验证 Google ID Token
    
    Args:
        id_token: Google ID Token
    
    Returns:
        验证后的用户信息字典，如果验证失败则返回 None
    """
    if not GOOGLE_CLIENT_ID:
        logger.warning("⚠️ GOOGLE_CLIENT_ID 未配置，跳过 Token 验证")
        return None
    
    try:
        from google.auth import verify_id_token
        from google.auth.transport import requests
        
        # 验证 Token
        user_info = verify_id_token(
            id_token,
            GOOGLE_CLIENT_ID,
            request=requests.Request()
        )
        
        return {
            "email": user_info.get("email"),
            "name": user_info.get("name"),
            "picture": user_info.get("picture"),
            "email_verified": user_info.get("email_verified", False),
            "sub": user_info.get("sub"),  # Google 用户 ID
        }
    except Exception as e:
        logger.error(f"❌ 验证 Google ID Token 失败: {e}", exc_info=True)
        return None
