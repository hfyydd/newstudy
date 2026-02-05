import os
from pathlib import Path

from dotenv import load_dotenv

# 加载 .env 文件（从 backend 目录查找）
env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=env_path)

base_url = os.getenv("BASE_URL", "https://api.moonshot.cn/v1")
api_key = os.getenv("API_KEY", "")
model = os.getenv("MODEL", "kimi-k2-turbo-preview")

# 数据库配置（从 .env 文件读取，不提供默认值）
# 注意：database_url 变量目前未使用，数据库连接统一使用 database.py 中的 DATABASE_URL
database_url = os.getenv("DATABASE_URL")

# JWT 配置
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 15  # Access Token 15分钟过期
REFRESH_TOKEN_EXPIRE_DAYS = 30  # Refresh Token 30天过期

# 邮箱验证码配置
VERIFICATION_CODE_EXPIRE_MINUTES = 5  # 验证码5分钟过期
VERIFICATION_CODE_LENGTH = 6  # 6位验证码

# Google OAuth 配置（可选，用于验证 Google ID Token）
GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID", "")

# Apple OAuth 配置（可选，用于验证 Apple ID Token）
APPLE_CLIENT_ID = os.getenv("APPLE_CLIENT_ID", "")
APPLE_TEAM_ID = os.getenv("APPLE_TEAM_ID", "")
APPLE_KEY_ID = os.getenv("APPLE_KEY_ID", "")

# 邮件发送配置
SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
SMTP_FROM_EMAIL = os.getenv("SMTP_FROM_EMAIL", SMTP_USER)
SMTP_FROM_NAME = os.getenv("SMTP_FROM_NAME", "FlashMind")
SMTP_USE_TLS = os.getenv("SMTP_USE_TLS", "true").lower() == "true"

# 注意：
# 这里不要在 import 阶段直接抛错，否则服务无法启动（即使只想用不依赖 LLM 的功能）。
# 需要调用 LLM 的地方应在运行时自行校验 api_key 是否为空。