import os
from pathlib import Path

from dotenv import load_dotenv

# 加载 .env 文件（从 backend 目录查找）
env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=env_path)

# AI配置
base_url = os.getenv("BASE_URL", "https://api.moonshot.cn/v1")
api_key = os.getenv("API_KEY", "")
model = os.getenv("MODEL", "kimi-k2-turbo-preview")

# 数据库配置（从 .env 文件读取）
database_url = os.getenv("DATABASE_URL")

# 注意：
# 这里不要在 import 阶段直接抛错，否则服务无法启动（即使只想用不依赖 LLM 的功能）。
# 需要调用 LLM 的地方应在运行时自行校验 api_key 是否为空。