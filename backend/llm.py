from functools import lru_cache

from langchain_openai import ChatOpenAI

try:
    from .config import api_key, base_url, model
except ImportError:
    from config import api_key, base_url, model


@lru_cache(maxsize=1)
def get_default_llm() -> ChatOpenAI:
    """
    返回一个按照配置文件初始化的 ChatOpenAI 实例。
    使用 lru_cache 确保全局仅创建一次,避免重复握手。
    """
    if not api_key:
        raise ValueError("API_KEY 未设置，无法调用 LLM。请在 backend/.env 配置 API_KEY。")
    return ChatOpenAI(
        api_key=api_key,
        base_url=base_url,
        model=model,
    )


__all__ = ["get_default_llm"]

