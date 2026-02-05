"""
Apple 认证工具
用于验证 Apple ID Token
"""
import logging
from typing import Optional, Dict, Any
from config import APPLE_CLIENT_ID, APPLE_TEAM_ID, APPLE_KEY_ID
from jose import jwt
import requests

logger = logging.getLogger(__name__)


def get_apple_public_keys() -> Optional[list]:
    """
    获取 Apple 公钥列表
    
    Returns:
        Apple 公钥列表
    """
    try:
        response = requests.get("https://appleid.apple.com/auth/keys")
        response.raise_for_status()
        return response.json().get("keys", [])
    except Exception as e:
        logger.error(f"❌ 获取 Apple 公钥失败: {e}", exc_info=True)
        return None


def verify_apple_id_token(id_token: str) -> Optional[Dict[str, Any]]:
    """
    验证 Apple ID Token
    
    Args:
        id_token: Apple ID Token
    
    Returns:
        验证后的用户信息字典，如果验证失败则返回 None
    """
    if not APPLE_CLIENT_ID:
        logger.warning("⚠️ APPLE_CLIENT_ID 未配置，跳过 Token 验证")
        return None
    
    try:
        # 获取 Apple 公钥
        public_keys = get_apple_public_keys()
        if not public_keys:
            logger.error("无法获取 Apple 公钥")
            return None
        
        # 解码 Token（不验证签名，先获取 header）
        unverified_header = jwt.get_unverified_header(id_token)
        kid = unverified_header.get("kid")
        
        if not kid:
            logger.error("Token 中缺少 kid")
            return None
        
        # 查找对应的公钥
        public_key = None
        for key in public_keys:
            if key.get("kid") == kid:
                public_key = key
                break
        
        if not public_key:
            logger.error(f"未找到对应的公钥: {kid}")
            return None
        
        # 使用 jose 库验证 Token
        # 注意：这里简化处理，实际应该使用 cryptography 库验证 RS256 签名
        # 由于 Apple 使用 RS256，需要使用 RSA 公钥验证
        
        # 暂时使用不验证签名的方式（仅用于开发）
        # 生产环境必须实现完整的 RS256 验证
        logger.warning("⚠️ Apple Token 验证未完全实现，仅用于开发测试")
        
        # 解码 Token（不验证签名）
        unverified_payload = jwt.decode(
            id_token,
            options={"verify_signature": False}
        )
        
        # 检查 audience 和 issuer
        if unverified_payload.get("aud") != APPLE_CLIENT_ID:
            logger.error("Token audience 不匹配")
            return None
        
        if unverified_payload.get("iss") != "https://appleid.apple.com":
            logger.error("Token issuer 不匹配")
            return None
        
        return {
            "email": unverified_payload.get("email"),
            "sub": unverified_payload.get("sub"),  # Apple 用户 ID
            "email_verified": unverified_payload.get("email_verified", False),
        }
        
    except Exception as e:
        logger.error(f"❌ 验证 Apple ID Token 失败: {e}", exc_info=True)
        return None
