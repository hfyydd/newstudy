"""
YouTube 字幕获取模块

使用 youtube-transcript-api 获取 YouTube 视频的字幕
"""

import re
import logging
from typing import Optional, Tuple

from youtube_transcript_api import YouTubeTranscriptApi

logger = logging.getLogger(__name__)


def extract_video_id(url: str) -> Optional[str]:
    """
    从 YouTube URL 中提取视频 ID
    
    支持的 URL 格式：
    - https://www.youtube.com/watch?v=VIDEO_ID
    - https://youtu.be/VIDEO_ID
    - https://m.youtube.com/watch?v=VIDEO_ID
    - https://www.youtube.com/embed/VIDEO_ID
    - https://www.youtube.com/v/VIDEO_ID
    """
    patterns = [
        # 标准格式：https://www.youtube.com/watch?v=VIDEO_ID
        r'(?:youtube\.com\/watch\?v=)([0-9A-Za-z_-]{11})',
        # 短链接：https://youtu.be/VIDEO_ID
        r'(?:youtu\.be\/)([0-9A-Za-z_-]{11})',
        # 嵌入格式：https://www.youtube.com/embed/VIDEO_ID
        r'(?:youtube\.com\/embed\/)([0-9A-Za-z_-]{11})',
        # 旧格式：https://www.youtube.com/v/VIDEO_ID
        r'(?:youtube\.com\/v\/)([0-9A-Za-z_-]{11})',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    
    return None


def get_youtube_transcript(video_id: str) -> Tuple[str, str]:
    """
    获取 YouTube 视频的字幕
    
    Args:
        video_id: YouTube 视频 ID
        
    Returns:
        Tuple[str, str]: (字幕文本, 语言代码)
        
    Raises:
        Exception: 无法获取字幕时抛出异常
    """
    logger.info(f"🎬 开始获取 YouTube 视频字幕: {video_id}")
    
    # 优先获取的语言列表（按优先级排序）
    preferred_languages = ['zh-Hans', 'zh-CN', 'zh-Hant', 'zh-TW', 'zh', 'en', 'en-US', 'en-GB']
    
    # 创建 API 实例（新版本 1.2.x 需要实例化）
    api = YouTubeTranscriptApi()
    
    try:
        # 方法1：尝试直接获取指定语言的字幕
        transcript_data = None
        language = None
        
        for lang in preferred_languages:
            try:
                transcript_data = api.fetch(video_id, languages=[lang])
                language = lang
                logger.info(f"✅ 成功获取 {lang} 字幕")
                break
            except Exception:
                continue
        
        # 方法2：如果没有找到首选语言，获取英文字幕（默认）
        if transcript_data is None:
            try:
                transcript_data = api.fetch(video_id)
                language = 'en'
                logger.info(f"✅ 使用默认英文字幕")
            except Exception as e:
                logger.error(f"❌ 无法获取任何字幕: {e}")
                raise Exception("该视频没有可用的字幕，请确保视频有字幕功能")
        
        if not transcript_data:
            raise Exception("该视频没有可用的字幕")
        
        # 合并所有字幕文本
        text_parts = []
        for entry in transcript_data:
            # FetchedTranscript 返回的是类似字典的对象
            text = entry.text.strip() if hasattr(entry, 'text') else entry.get('text', '').strip()
            if text:
                text_parts.append(text)
        
        full_text = ' '.join(text_parts)
        
        if not full_text:
            raise Exception("字幕内容为空")
        
        logger.info(f"✅ 字幕获取成功，长度: {len(full_text)} 字符，语言: {language}")
        
        return full_text, language
        
    except Exception as e:
        error_msg = str(e)
        logger.error(f"❌ 获取字幕失败: {error_msg}")
        
        # 提供更友好的错误信息
        if "disabled" in error_msg.lower():
            raise Exception("该视频已禁用字幕功能")
        elif "no transcript" in error_msg.lower() or "not found" in error_msg.lower():
            raise Exception("该视频没有可用的字幕")
        else:
            raise Exception(f"获取字幕失败: {error_msg}")


def get_transcript_from_url(url: str) -> Tuple[str, str, str]:
    """
    从 YouTube URL 获取字幕
    
    Args:
        url: YouTube 视频 URL
        
    Returns:
        Tuple[str, str, str]: (字幕文本, 语言代码, 视频ID)
        
    Raises:
        Exception: 无效 URL 或无法获取字幕时抛出异常
    """
    # 提取视频 ID
    video_id = extract_video_id(url)
    if not video_id:
        raise Exception("无效的 YouTube URL，请检查链接格式")
    
    logger.info(f"🔗 YouTube URL: {url}")
    logger.info(f"🎬 视频 ID: {video_id}")
    
    # 获取字幕
    text, language = get_youtube_transcript(video_id)
    
    return text, language, video_id
