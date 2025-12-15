"""
上传文件文本提取器

支持：
- .txt / .md 等纯文本
- .pdf
- .docx（Word 新格式）

说明：
- 传统 .doc 属于二进制格式，默认不支持（需要额外系统依赖/转换工具）。
"""

from __future__ import annotations

import io
import os
from typing import Optional


def _get_extension(filename: Optional[str]) -> str:
    if not filename:
        return ""
    _, ext = os.path.splitext(filename)
    return ext.lower().strip(".")


def extract_text_from_upload(filename: Optional[str], raw: bytes) -> str:
    ext = _get_extension(filename)

    if ext in {"txt", "md", "markdown", "log"} or not ext:
        try:
            return raw.decode("utf-8")
        except UnicodeDecodeError:
            return raw.decode("latin-1")

    if ext == "pdf":
        try:
            from pypdf import PdfReader
        except Exception as exc:  # noqa: BLE001
            raise ValueError("缺少 PDF 解析依赖 pypdf") from exc

        reader = PdfReader(io.BytesIO(raw))
        parts: list[str] = []
        for page in reader.pages:
            try:
                text = page.extract_text() or ""
            except Exception:
                text = ""
            if text.strip():
                parts.append(text)
        return "\n\n".join(parts).strip()

    if ext == "docx":
        try:
            import docx  # python-docx
        except Exception as exc:  # noqa: BLE001
            raise ValueError("缺少 Word(docx) 解析依赖 python-docx") from exc

        doc = docx.Document(io.BytesIO(raw))
        parts = [p.text for p in doc.paragraphs if p.text and p.text.strip()]
        return "\n".join(parts).strip()

    if ext == "doc":
        raise ValueError("暂不支持 .doc（请另存为 .docx 后上传）")

    raise ValueError(f"不支持的文件类型: .{ext}")


__all__ = ["extract_text_from_upload"]


