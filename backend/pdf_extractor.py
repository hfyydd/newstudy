"""
PDF 文本提取模块（优化版）

支持大 PDF 文件的智能提取：
- 限制页数（默认前 50 页）
- 限制字符数（默认 50000 字符）
"""

import io
import logging
from typing import Optional, Tuple

logger = logging.getLogger(__name__)


def extract_text_from_pdf(
    raw: bytes,
    max_pages: int = 50,
    max_chars: int = 50000
) -> Tuple[str, int, int]:
    """
    从 PDF 文件提取文本
    
    Args:
        raw: PDF 文件的字节数据
        max_pages: 最大提取页数（默认 50 页）
        max_chars: 最大字符数（默认 50000 字符）
        
    Returns:
        Tuple[str, int, int]: (提取的文本, 总页数, 实际提取的页数)
        
    Raises:
        ValueError: PDF 解析失败时抛出异常
    """
    try:
        from pypdf import PdfReader
    except ImportError as exc:
        raise ValueError("缺少 PDF 解析依赖 pypdf") from exc
    
    try:
        reader = PdfReader(io.BytesIO(raw))
        total_pages = len(reader.pages)
        
        logger.info(f"📄 PDF 总页数: {total_pages}")
        
        # 确定实际提取的页数
        pages_to_extract = min(max_pages, total_pages)
        
        if total_pages > max_pages:
            logger.warning(f"⚠️ PDF 页数较多（{total_pages} 页），仅提取前 {pages_to_extract} 页")
        
        # 提取文本
        parts: list[str] = []
        total_chars = 0
        
        for page_num in range(pages_to_extract):
            try:
                page = reader.pages[page_num]
                text = page.extract_text() or ""
                
                if text.strip():
                    # 检查字符数限制
                    remaining_chars = max_chars - total_chars
                    if remaining_chars <= 0:
                        logger.warning(f"⚠️ 已达到字符数限制（{max_chars}），停止提取")
                        break
                    
                    # 如果当前页文本超过剩余字符数，截断
                    if len(text) > remaining_chars:
                        text = text[:remaining_chars]
                        logger.warning(f"⚠️ 第 {page_num + 1} 页文本过长，已截断")
                    
                    parts.append(text)
                    total_chars += len(text)
                    
            except Exception as e:
                logger.warning(f"⚠️ 提取第 {page_num + 1} 页失败: {e}")
                continue
        
        extracted_text = "\n\n".join(parts).strip()
        
        logger.info(f"✅ PDF 文本提取成功")
        logger.info(f"   - 总页数: {total_pages}")
        logger.info(f"   - 提取页数: {len(parts)}")
        logger.info(f"   - 提取字符数: {len(extracted_text)}")
        
        return extracted_text, total_pages, len(parts)
        
    except Exception as e:
        error_msg = str(e)
        logger.error(f"❌ PDF 解析失败: {error_msg}")
        raise ValueError(f"PDF 解析失败: {error_msg}") from e
