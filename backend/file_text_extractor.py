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
- 可配置使用Tesseract（需安装系统依赖），速度更快

环境变量：
- OCR_BACKEND: "easyocr" (默认) 或 "tesseract"
"""

from __future__ import annotations

import io
import os
from typing import Optional


# 缓存EasyOCR Reader实例，避免重复初始化
_easyocr_reader = None

# Tesseract可用性检查
_tesseract_available = None


def _get_extension(filename: Optional[str]) -> str:
    if not filename:
        return ""
    _, ext = os.path.splitext(filename)
    return ext.lower().strip(".")


def _get_ocr_backend() -> str:
    """获取配置的OCR后端"""
    return os.environ.get("OCR_BACKEND", "easyocr").lower()


def _is_tesseract_available() -> bool:
    """检查Tesseract是否可用"""
    global _tesseract_available
    if _tesseract_available is not None:
        return _tesseract_available
    
    try:
        import pytesseract
        # 检查tesseract命令是否可用
        pytesseract.get_tesseract_version()
        _tesseract_available = True
        return True
    except Exception:
        _tesseract_available = False
        return False


def _get_easyocr_reader():
    """获取或创建EasyOCR Reader实例"""
    global _easyocr_reader
    if _easyocr_reader is None:
        import easyocr
        _easyocr_reader = easyocr.Reader(['ch_sim', 'en'], gpu=False)
    return _easyocr_reader


def _preprocess_image_for_ocr(img):
    """预处理图片以提高OCR准确率"""
    try:
        import numpy as np
        import cv2
        
        # 转换为灰度图
        if len(img.shape) == 3:
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        else:
            gray = img.copy()
        
        # 应用CLAHE增强对比度
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(gray)
        
        # 轻度去噪
        denoised = cv2.fastNlMeansDenoising(enhanced, None, 10, 7, 21)
        
        return denoised
    except Exception:
        return img


def _ocr_with_tesseract(img) -> str:
    """使用Tesseract进行OCR"""
    try:
        import pytesseract
        from PIL import Image
        
        # 预处理图片
        processed = _preprocess_image_for_ocr(img)
        
        # 转换为PIL Image
        pil_image = Image.fromarray(processed)
        
        # 使用Tesseract进行OCR（中英文混合）
        text = pytesseract.image_to_string(
            pil_image,
            lang='eng+chi_sim',
            config='--oem 3 --psm 6'
        )
        
        return text.strip()
    except Exception as e:
        raise ValueError(f"Tesseract OCR失败: {e}")


def _ocr_with_easyocr(img) -> str:
    """使用EasyOCR进行OCR"""
    reader = _get_easyocr_reader()
    results = reader.readtext(img, detail=0)
    text_list = [str(r) for r in results if str(r).strip()]
    return "\n".join(text_list)


def _ocr_image(img) -> str:
    """根据配置选择OCR后端"""
    backend = _get_ocr_backend()
    
    if backend == "tesseract":
        if not _is_tesseract_available():
            # 回退到EasyOCR
            return _ocr_with_easyocr(img)
        return _ocr_with_tesseract(img)
    else:
        return _ocr_with_easyocr(img)


def _ocr_pdf_page(page, page_num: int = 0) -> str:
    """从PDF页面提取图片并进行OCR"""
    try:
        import numpy as np
        import cv2
        
        # 尝试提取页面中的图片
        images = page.images
        if not images:
            return ""
        
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
                    # 使用配置的OCR后端
                    page_text = _ocr_image(img)
                    if page_text.strip():
                        all_text.append(page_text)
            except Exception:
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
            import fitz
        except Exception as exc:  # noqa: BLE001
            raise ValueError("缺少 PDF 解析依赖 PyMuPDF，请运行: pip install PyMuPDF") from exc

        try:
            doc = fitz.open(stream=raw, filetype="pdf")
            parts = []
            has_text = False
            
            for page_num, page in enumerate(doc):
                text = page.get_text() or ""
                if text.strip():
                    has_text = True
                    parts.append(text)
                else:
                    page_text = _ocr_pdf_page(page, page_num)
                    if page_text.strip():
                        has_text = True
                        parts.append(page_text)
            
            doc.close()
            result_text = "\n\n".join(parts).strip()
            
            if not result_text:
                raise ValueError(
                    "无法从PDF中提取到文本内容。这可能是因为："
                    "1. PDF是扫描件（没有文本层），"
                    "2. PDF使用了特殊的编码方式。"
                    "建议：将PDF转为图片后重新上传，或使用文字版PDF。"
                )
            
            return result_text
        except Exception as exc:
            if isinstance(exc, ValueError):
                raise
            raise ValueError(f"PDF解析失败: {exc}") from exc

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

        # 使用配置的OCR后端
        text = _ocr_image(img)
        return text

    raise ValueError(f"不支持的文件类型: .{ext}")


__all__ = ["extract_text_from_upload"]


