import os
from pathlib import Path

from dotenv import load_dotenv

# 加载 .env 文件（从 backend 目录查找）
env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=env_path)

base_url = os.getenv("BASE_URL", "https://api.moonshot.cn/v1")
api_key = os.getenv("API_KEY", "")
model = os.getenv("MODEL", "kimi-k2-turbo-preview")

if not api_key:
    raise ValueError(
        "API_KEY 未设置。请在 .env 文件中配置 API_KEY，或参考 .env.example"
    )