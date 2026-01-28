"""
智能笔记生成器

调用 LLM 根据用户输入内容生成结构化的笔记（Markdown格式）和闪词列表。
"""

from __future__ import annotations

import json
import logging
import re
from typing import List, Optional

from langchain_core.messages import HumanMessage, SystemMessage

try:
    from .llm import get_default_llm
except ImportError:  # pragma: no cover
    from llm import get_default_llm

logger = logging.getLogger(__name__)


SMART_NOTE_SYSTEM_PROMPT = """你是一位专业的学习助理，擅长将用户的学习内容整理成结构化的笔记。

## 你的任务
根据用户输入的内容，生成：
1. 一份结构化的 Markdown 格式笔记（清晰、易读、便于学习）
2. 一份从内容中提取的核心词语/概念列表（闪词列表，用于后续的卡片式学习）

## 笔记生成要求
1. 使用 Markdown 格式，包含标题、列表、表格等元素
2. 结构清晰，分点阐述
3. 如果内容涉及定义、概念，要给出清晰的解释
4. 如果内容涉及分类或对比，使用表格呈现
5. 保持专业性和准确性
6. 内容要比用户输入更丰富、更有条理

## 闪词列表要求
1. 提取 10-30 个核心词语或概念
2. 优先选择专业术语、重要概念、关键词
3. 词语应尽量保持原文用词
4. 去重、按重要性排序
5. 每个词语 2-12 个字

## 输出格式（严格遵守）
只输出纯 JSON，不要任何额外文字：
```json
{
  "note_content": "# 标题\\n\\n笔记的 Markdown 内容...",
  "terms": ["词语1", "词语2", "词语3", ...]
}
```

注意：note_content 中的换行用 \\n 表示。
"""


_JSON_BLOCK_RE = re.compile(r"```json\s*(\{.*?\})\s*```", re.DOTALL | re.IGNORECASE)


def _extract_json(text: str) -> Optional[str]:
    """从 LLM 响应中提取 JSON 字符串"""
    content = text.strip()
    if not content:
        return None
    match = _JSON_BLOCK_RE.search(content)
    if match:
        return match.group(1)
    if content.startswith("{") and content.endswith("}"):
        return content
    start = content.find("{")
    end = content.rfind("}")
    if start != -1 and end > start:
        return content[start : end + 1]
    return None


def _generate_fallback_note(user_input: str) -> tuple[str, List[str]]:
    """
    当 LLM 不可用时的兜底方案：简单格式化用户输入
    """
    lines = user_input.strip().split('\n')
    title = lines[0][:50] if lines else "学习笔记"
    
    # 简单的笔记格式化
    note_content = f"""# {title}

## 原始内容

{user_input}

---

*此笔记由系统自动生成，建议重新编辑整理。*
"""
    
    # 简单的词语提取（使用规则）
    import re
    from collections import Counter
    
    # 提取中文词语
    chinese_tokens = re.findall(r"[\u4e00-\u9fff]{2,8}", user_input)
    # 提取英文词语
    english_tokens = re.findall(r"[A-Za-z][A-Za-z0-9_\-]{2,30}", user_input)
    
    chinese_stop = {"我们", "你们", "他们", "这个", "那个", "这些", "那些", "然后", 
                    "因此", "所以", "因为", "但是", "如果", "就是", "以及", "可以"}
    english_stop = {"the", "and", "or", "to", "of", "in", "on", "for", "with", 
                    "is", "are", "was", "were", "be", "this", "that", "it"}
    
    all_tokens = [t for t in chinese_tokens if t not in chinese_stop]
    all_tokens.extend([t for t in english_tokens if t.lower() not in english_stop])
    
    counts = Counter(all_tokens)
    terms = [term for term, _ in counts.most_common(20)]
    
    return note_content, terms


def generate_smart_note(user_input: str, max_terms: int = 30) -> tuple[str, List[str]]:
    """
    根据用户输入生成智能笔记和闪词列表
    
    Args:
        user_input: 用户输入的学习内容
        max_terms: 最多返回的词语数量
        
    Returns:
        tuple[str, List[str]]: (Markdown格式的笔记内容, 闪词列表)
    """
    text = user_input.strip()
    if not text:
        logger.warning("用户输入为空，返回空结果")
        return "", []
    
    logger.info(f"📖 开始调用 LLM 生成智能笔记...")
    
    # 1) 尝试使用 LLM 生成
    try:
        llm = get_default_llm()
        logger.info("✅ LLM 实例获取成功")
        
        messages = [
            SystemMessage(content=SMART_NOTE_SYSTEM_PROMPT),
            HumanMessage(
                content=(
                    f"请根据以下内容生成结构化笔记和闪词列表。\n\n"
                    f"用户输入：\n{text}\n\n"
                    f"闪词列表最多返回 {max_terms} 个词语。"
                )
            ),
        ]
        
        logger.info("🤖 正在调用 LLM API...")
        response = llm.invoke(messages)
        content = str(getattr(response, "content", "")).strip()
        logger.info(f"📨 LLM 响应长度: {len(content)} 字符")
        logger.debug(f"LLM 原始响应: {content[:500]}...")
        
        json_str = _extract_json(content)
        
        if json_str:
            logger.info("✅ JSON 解析成功")
            data = json.loads(json_str)
            note_content = data.get("note_content", "")
            terms_raw = data.get("terms", [])
            
            if isinstance(terms_raw, list) and note_content:
                terms = [str(t).strip() for t in terms_raw if str(t).strip()]
                # 去重并截断
                uniq: List[str] = []
                seen: set[str] = set()
                for t in terms:
                    if t in seen:
                        continue
                    seen.add(t)
                    uniq.append(t)
                    if len(uniq) >= max_terms:
                        break
                logger.info(f"✅ LLM 生成完成: 笔记 {len(note_content)} 字符, 闪词 {len(uniq)} 个")
                return note_content, uniq
        else:
            logger.warning("⚠️ 无法从 LLM 响应中提取 JSON")
    except Exception as e:
        # 任何 LLM 错误都直接走兜底
        logger.error(f"❌ LLM 生成失败，使用兜底方案: {e}")
        pass
    
    # 2) 兜底方案
    logger.info("🔄 使用兜底方案生成笔记...")
    return _generate_fallback_note(text)


__all__ = ["generate_smart_note"]

