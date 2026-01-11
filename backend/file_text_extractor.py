"""
上传文件文本提取器

支持：
- .txt / .md 等纯文本
- .pdf
- .docx（Word 新格式）
- 图片 (jpg, jpeg, png, bmp, webp) - 使用 OCR

说明：
- 传统 .doc 属于二进制格式，默认不支持（需要额外系统依赖/转换工具）。
- 图片OCR使用EasyOCR，支持中英文识别
"""

from __future__ import annotations

import io
import os
from typing import Optional


# 缓存EasyOCR Reader实例，避免重复初始化
_easyocr_reader = None


def _get_extension(filename: Optional[str]) -> str:
    if not filename:
        return ""
    _, ext = os.path.splitext(filename)
    return ext.lower().strip(".")


def _get_easyocr_reader():
    """获取或创建EasyOCR Reader实例"""
    global _easyocr_reader
    if _easyocr_reader is None:
        import easyocr
        # 初始化 easyocr (支持中英文)
        # gpu=False 使用CPU，第一次运行会自动下载模型
        _easyocr_reader = easyocr.Reader(['ch_sim', 'en'], gpu=False)
    return _easyocr_reader


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

    if ext in {"jpg", "jpeg", "png", "bmp", "webp"}:
        try:
            import numpy as np
            import cv2
        except Exception as exc:  # noqa: BLE001
            raise ValueError("缺少 OCR 依赖 (opencv/numpy)") from exc
        
        # 将 bytes 转为 numpy array 以供 cv2 使用
        nparr = np.frombuffer(raw, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError("无法解析图片文件")

        # 使用缓存的 reader
        reader = _get_easyocr_reader()
        raw_results = reader.readtext(img, detail=0)
        # 显式转换为字符串列表
        text_list: list[str] = [str(item) for item in raw_results]
        # 过滤空行
        filtered = [line for line in text_list if line.strip()]
        return "\n".join(filtered)

    raise ValueError(f"不支持的文件类型: .{ext}")


__all__ = ["extract_text_from_upload"]


