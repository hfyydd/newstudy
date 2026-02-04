"""
Bilibili 字幕获取模块

使用 bilibili-api-python 库获取视频字幕
"""

import re
import logging
from typing import Optional, Tuple
import asyncio

try:
    from bilibili_api import video, sync
except ImportError:
    # 如果导入失败，提供友好的错误提示
    raise ImportError(
        "bilibili-api-python 未安装，请运行: uv sync"
    )

logger = logging.getLogger(__name__)


def extract_bv_id(url: str) -> Optional[str]:
    """
    从 Bilibili URL 中提取 BV 号
    
    支持的 URL 格式：
    - https://www.bilibili.com/video/BVxxxxxx
    - https://b23.tv/xxxxxx (短链接需要先解析)
    - https://m.bilibili.com/video/BVxxxxxx
    """
    # 标准格式：https://www.bilibili.com/video/BVxxxxxx
    bv_pattern = r'BV[a-zA-Z0-9]{10}'
    match = re.search(bv_pattern, url)
    if match:
        return match.group(0)
    
    # 短链接格式：https://b23.tv/xxxxxx
    if 'b23.tv' in url:
        try:
            import requests
            # 跟随重定向获取真实 URL
            response = requests.head(url, allow_redirects=True, timeout=10)
            real_url = response.url
            match = re.search(bv_pattern, real_url)
            if match:
                return match.group(0)
        except Exception as e:
            logger.warning(f"解析短链接失败: {e}")
    
    return None


async def _get_bilibili_transcript_async(bv_id: str) -> Tuple[str, str]:
    """
    异步获取 Bilibili 视频的字幕
    
    Args:
        bv_id: Bilibili 视频 BV 号
        
    Returns:
        Tuple[str, str]: (字幕文本, 语言代码)
        
    Raises:
        Exception: 无法获取字幕时抛出异常
    """
    logger.info(f"🎬 开始获取 Bilibili 视频字幕: {bv_id}")
    
    try:
        # 创建 Video 对象
        v = video.Video(bvid=bv_id)
        
        # 1. 获取视频信息（包含字幕列表）
        try:
            video_info = await v.get_info()
            logger.info(f"✅ 获取视频信息成功: {video_info.get('title', '未知标题')}")
        except Exception as e:
            logger.error(f"❌ 获取视频信息失败: {e}")
            raise Exception(f"获取视频信息失败: {str(e)}")
        
        # 2. 从视频信息中获取字幕列表
        subtitle_info = video_info.get('subtitle', {})
        subtitle_list = subtitle_info.get('list', [])
        
        if not subtitle_list:
            raise Exception("该视频没有可用的字幕")
        
        logger.info(f"✅ 找到 {len(subtitle_list)} 个字幕选项")
        
        # 3. 优先选择中文字幕
        subtitle = None
        preferred_languages = ['zh-Hans', 'zh-CN', 'zh-Hant', 'zh-TW', 'zh', 'zh-cn', 'zh-Hans-CN']
        
        for lang in preferred_languages:
            for sub in subtitle_list:
                sub_lan = sub.get('lan', '').lower()
                if sub_lan == lang.lower() or sub_lan.startswith(lang.lower()):
                    subtitle = sub
                    break
            if subtitle:
                break
        
        # 如果没有找到首选语言，使用第一个可用字幕
        if not subtitle:
            subtitle = subtitle_list[0]
        
        language = subtitle.get('lan', 'unknown')
        subtitle_url = subtitle.get('subtitle_url', '')
        
        if not subtitle_url:
            raise Exception("字幕 URL 为空")
        
        logger.info(f"✅ 选择字幕语言: {language}")
        
        # 4. 获取字幕内容
        try:
            # 使用 bilibili-api-python 的 get_subtitle 方法
            # 注意：get_subtitle 需要 cid 参数，但我们可以直接使用字幕 URL
            # 如果 get_subtitle 不支持 URL，我们需要直接请求字幕 URL
            import requests
            headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Referer': f'https://www.bilibili.com/video/{bv_id}'
            }
            subtitle_response = requests.get(subtitle_url, headers=headers, timeout=10)
            subtitle_response.raise_for_status()
            subtitle_data = subtitle_response.json()
        except Exception as e:
            logger.error(f"❌ 获取字幕内容失败: {e}")
            raise Exception(f"获取字幕内容失败: {str(e)}")
        
        # 5. 解析字幕内容
        # bilibili-api-python 返回的字幕格式可能是不同的
        # 需要根据实际返回格式解析
        body = None
        if isinstance(subtitle_data, dict):
            body = subtitle_data.get('body', [])
        elif isinstance(subtitle_data, list):
            body = subtitle_data
        else:
            # 尝试直接访问属性
            body = getattr(subtitle_data, 'body', None) or getattr(subtitle_data, 'data', None)
        
        if not body:
            # 如果 body 为空，尝试其他可能的字段
            if isinstance(subtitle_data, dict):
                # 尝试直接获取内容
                for key in ['content', 'text', 'lines', 'subtitles']:
                    if key in subtitle_data:
                        body = subtitle_data[key]
                        break
            
            if not body:
                raise Exception("字幕内容为空或格式不支持")
        
        # 合并所有字幕文本
        text_parts = []
        for item in body:
            if isinstance(item, dict):
                content = item.get('content', item.get('text', item.get('line', ''))).strip()
            elif isinstance(item, str):
                content = item.strip()
            else:
                # 尝试访问属性
                content = getattr(item, 'content', getattr(item, 'text', '')).strip()
            
            if content:
                text_parts.append(content)
        
        full_text = ' '.join(text_parts)
        
        if not full_text:
            raise Exception("字幕文本为空")
        
        logger.info(f"✅ 字幕获取成功，长度: {len(full_text)} 字符，语言: {language}")
        
        return full_text, language
        
    except Exception as e:
        error_msg = str(e)
        logger.error(f"❌ 获取字幕失败: {error_msg}")
        raise


def get_bilibili_transcript(bv_id: str) -> Tuple[str, str]:
    """
    获取 Bilibili 视频的字幕（同步包装）
    
    Args:
        bv_id: Bilibili 视频 BV 号
        
    Returns:
        Tuple[str, str]: (字幕文本, 语言代码)
        
    Raises:
        Exception: 无法获取字幕时抛出异常
    """
    try:
        # 使用 sync 将异步函数转换为同步
        return sync(_get_bilibili_transcript_async(bv_id))
    except Exception as e:
        error_msg = str(e)
        logger.error(f"❌ 获取字幕失败: {error_msg}")
        raise


def get_transcript_from_url(url: str) -> Tuple[str, str, str]:
    """
    从 Bilibili URL 获取字幕
    
    Args:
        url: Bilibili 视频 URL
        
    Returns:
        Tuple[str, str, str]: (字幕文本, 语言代码, BV号)
        
    Raises:
        Exception: 无效 URL 或无法获取字幕时抛出异常
    """
    # 提取 BV 号
    bv_id = extract_bv_id(url)
    if not bv_id:
        raise Exception("无效的 Bilibili URL，请检查链接格式（需要包含 BV 号）")
    
    logger.info(f"🔗 Bilibili URL: {url}")
    logger.info(f"🎬 视频 BV 号: {bv_id}")
    
    # 获取字幕
    text, language = get_bilibili_transcript(bv_id)
    
    return text, language, bv_id
