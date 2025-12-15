"""
笔记词语抽取器

优先使用 LLM 从笔记中提取“需要学习的词语/概念”，在 LLM 不可用时使用规则兜底。
"""

from __future__ import annotations

import json
import re
from collections import Counter
from typing import List, Optional

from langchain_core.messages import HumanMessage, SystemMessage

try:
    from .llm import get_default_llm
except ImportError:  # pragma: no cover
    from llm import get_default_llm


NOTE_TERMS_SYSTEM_PROMPT = """你是一位学习助理。你会收到一段用户笔记，请从中提取“最值得学习/记忆”的核心词语或概念，输出一个去重后的列表。

## 输出要求（严格遵守）
1. 只输出纯 JSON，不要任何额外文字
2. JSON 格式：{"terms": ["词语1", "词语2", ...]}
3. 词语数量：10-30 个（由内容决定）
4. 词语应尽量保持原文用词（不要随意改写）
5. 去重、按重要性排序
6. 避免非常常见的停用词（如：我们、这个、因此、是、的、and、the 等）
7. 不要输出句子，只输出词或短语（建议 2-12 个字/字符）
"""


_JSON_BLOCK_RE = re.compile(r"```json\s*(\{.*?\})\s*```", re.DOTALL | re.IGNORECASE)


def _extract_json(text: str) -> Optional[str]:
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


def _heuristic_extract_terms(note_text: str, max_terms: int = 30) -> List[str]:
    text = note_text.strip()
    if not text:
        return []

    # 英文/数字/下划线 token
    english_tokens = re.findall(r"[A-Za-z][A-Za-z0-9_\-]{1,30}", text)
    # 中文连续 token（不做分词，先取 2-8 字）
    chinese_tokens = re.findall(r"[\u4e00-\u9fff]{2,8}", text)

    english_stop = {
        "the",
        "and",
        "or",
        "to",
        "of",
        "in",
        "on",
        "for",
        "with",
        "is",
        "are",
        "was",
        "were",
        "be",
        "this",
        "that",
        "it",
        "as",
        "by",
        "from",
    }
    chinese_stop = {
        "我们",
        "你们",
        "他们",
        "这个",
        "那个",
        "这些",
        "那些",
        "然后",
        "因此",
        "所以",
        "因为",
        "但是",
        "如果",
        "就是",
        "以及",
        "可以",
        "进行",
        "一个",
        "一种",
        "是否",
        "本身",
        "同时",
        "通过",
        "问题",
        "方法",
        "结果",
    }

    normalized: List[str] = []
    for t in english_tokens:
        low = t.lower()
        if low in english_stop:
            continue
        if len(t) <= 2:
            continue
        normalized.append(t)
    for t in chinese_tokens:
        if t in chinese_stop:
            continue
        normalized.append(t)

    if not normalized:
        return []

    counts = Counter(normalized)

    def score(term: str) -> float:
        freq = counts[term]
        length_bonus = min(len(term), 12) / 12.0
        # 偏好中文与含大写的缩写/专有名词
        is_chinese = bool(re.search(r"[\u4e00-\u9fff]", term))
        has_upper = any(ch.isupper() for ch in term)
        type_bonus = (0.25 if is_chinese else 0.0) + (0.15 if has_upper else 0.0)
        return freq * (1.0 + length_bonus) + type_bonus

    sorted_terms = sorted(counts.keys(), key=score, reverse=True)

    # 去重（英文不区分大小写）
    out: List[str] = []
    seen_lower: set[str] = set()
    for t in sorted_terms:
        key = t.lower() if re.fullmatch(r"[A-Za-z0-9_\-]+", t) else t
        if key in seen_lower:
            continue
        seen_lower.add(key)
        out.append(t)
        if len(out) >= max_terms:
            break
    return out


def extract_terms_from_note(note_text: str, max_terms: int = 30) -> List[str]:
    """
    从笔记内容中抽取待学习词语。

    - LLM 可用：用 LLM 抽取更贴近“学习重点”的词语
    - LLM 不可用：使用规则兜底抽取
    """
    text = note_text.strip()
    if not text:
        return []

    # 1) 先尝试 LLM
    try:
        llm = get_default_llm()
        messages = [
            SystemMessage(content=NOTE_TERMS_SYSTEM_PROMPT),
            HumanMessage(
                content=(
                    f"请从下面笔记中提取核心词语/概念。\n\n"
                    f"笔记：\n{text}\n\n"
                    f"最多返回 {max_terms} 个词语。"
                )
            ),
        ]
        response = llm.invoke(messages)
        content = str(getattr(response, "content", "")).strip()
        json_str = _extract_json(content)
        if json_str:
            data = json.loads(json_str)
            terms_raw = data.get("terms", [])
            if isinstance(terms_raw, list):
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
                if uniq:
                    return uniq
    except Exception:
        # 任何 LLM 错误都直接走兜底，不影响服务可用性
        pass

    # 2) 规则兜底
    return _heuristic_extract_terms(text, max_terms=max_terms)


__all__ = ["extract_terms_from_note"]


