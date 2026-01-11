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
        _easyocr_reader = easyocr.Reader(['ch_sim', 'en'], gpu=False)
    return _easyocr_reader


def _ocr_pdf_page(page, page_num: int = 0) -> str:
    """从PDF页面提取图片并进行OCR"""
    try:
        import numpy as np
        import cv2
        
        # 尝试提取页面中的图片
        images = page.images
        if not images:
            return ""
        
        reader = _get_easyocr_reader()
        all_text: list[str] = []
        
        for i, image in enumerate(images):
            try:
                # image 可能是PIL Image或bytes
                if hasattr(image, 'tobytes'):
                    # PIL Image
                    img_bytes = image.tobytes()
                elif isinstance(image, bytes):
                    img_bytes = image
                else:
                    continue
                
                nparr = np.frombuffer(img_bytes, np.uint8)
                img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                
                if img is not None:
                    results = reader.readtext(img, detail=0)
                    page_text = "\n".join([str(r) for r in results if str(r).strip()])
                    if page_text:
                        all_text.append(page_text)
            except Exception as e:
                continue
        
        return "\n".join(all_text)
    except Exception:
        return ""


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
        has_text = False
        
        for i, page in enumerate(reader.pages):
            try:
                text = page.extract_text() or ""
                if text.strip():
                    has_text = True
                    parts.append(text)
            except Exception:
                text = ""
            
            # 如果这一页没有文本，尝试用OCR（如果有图片）
            if not text.strip():
                try:
                    # 尝试提取页面中的图片并OCR
                    page_text = _ocr_pdf_page(page, i)
                    if page_text.strip():
                        has_text = True
                        parts.append(page_text)
                except Exception:
                    pass
        
        result_text = "\n\n".join(parts).strip()
        
        # 如果完全没有提取到任何文本
        if not result_text:
            raise ValueError(
                "无法从PDF中提取到文本内容。"
                "这可能是因为："
                "1. PDF是扫描件（没有文本层），"
                "2. PDF使用了特殊的编码方式。"
                "建议：将PDF转为图片后重新上传，或使用文字版PDF。"
            )
        
        return result_text

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


