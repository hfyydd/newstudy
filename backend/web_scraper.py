"""
网页抓取工具
用于从网页URL提取可见文本内容
支持静态网页（requests + BeautifulSoup）和动态网页（Playwright）
"""
import logging
import re
from typing import Optional, Tuple
from urllib.parse import urlparse, urljoin

import requests
from bs4 import BeautifulSoup

logger = logging.getLogger(__name__)

# 尝试导入 Playwright（可选，如果未安装则使用降级方案）
try:
    from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeoutError
    PLAYWRIGHT_AVAILABLE = True
except ImportError:
    PLAYWRIGHT_AVAILABLE = False
    logger.warning("⚠️ Playwright 未安装，将仅支持静态网页抓取。安装命令: pip install playwright && playwright install chromium")

# 请求超时时间（秒）
REQUEST_TIMEOUT = 10
PLAYWRIGHT_TIMEOUT = 30000  # Playwright 超时时间（毫秒）

# 默认 User-Agent，模拟浏览器访问
DEFAULT_HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
}

# 需要移除的标签（不包含可见内容）
REMOVE_TAGS = [
    'script', 'style', 'nav', 'footer', 'header', 'aside',
    'iframe', 'noscript', 'meta', 'link', 'svg', 'canvas'
]

# 需要移除的类名模式（广告、评论等）
REMOVE_CLASS_PATTERNS = [
    re.compile(r'ad', re.IGNORECASE),
    re.compile(r'comment', re.IGNORECASE),
    re.compile(r'sidebar', re.IGNORECASE),
    re.compile(r'widget', re.IGNORECASE),
]


def validate_url(url: str) -> bool:
    """
    验证URL格式
    
    Args:
        url: 待验证的URL字符串
        
    Returns:
        bool: URL格式是否有效
    """
    try:
        result = urlparse(url)
        return all([result.scheme, result.netloc])
    except Exception:
        return False


def normalize_url(url: str) -> str:
    """
    规范化URL（添加协议等）
    
    Args:
        url: 原始URL字符串
        
    Returns:
        str: 规范化后的URL
    """
    url = url.strip()
    
    # 如果没有协议，添加 https://
    if not url.startswith(('http://', 'https://')):
        url = 'https://' + url
    
    return url


def fetch_webpage_with_playwright(url: str) -> Optional[str]:
    """
    使用 Playwright 抓取网页HTML内容（支持 JavaScript 渲染）
    
    Args:
        url: 网页URL
        
    Returns:
        Optional[str]: HTML内容，如果失败返回None
    """
    if not PLAYWRIGHT_AVAILABLE:
        return None
    
    try:
        logger.info(f"🌐 [Playwright] 开始抓取网页: {url}")
        
        with sync_playwright() as p:
            # 启动浏览器（使用 headless 模式）
            browser = p.chromium.launch(headless=True)
            context = browser.new_context(
                user_agent=DEFAULT_HEADERS['User-Agent'],
                viewport={'width': 1920, 'height': 1080},
                # 禁用图片和字体加载以加快速度
                bypass_csp=True
            )
            page = context.new_page()
            
            # 访问网页并等待内容加载
            # 使用 'load' 状态，比 'domcontentloaded' 更完整，但比 'networkidle' 更快
            try:
                page.goto(url, wait_until='load', timeout=PLAYWRIGHT_TIMEOUT)
            except PlaywrightTimeoutError:
                logger.warning(f"⚠️ [Playwright] load 超时，继续尝试...")
                # 如果 load 超时，尝试 domcontentloaded
                try:
                    page.goto(url, wait_until='domcontentloaded', timeout=10000)
                except PlaywrightTimeoutError:
                    logger.warning(f"⚠️ [Playwright] domcontentloaded 也超时，继续...")
            
            # 等待页面内容加载（给 JavaScript 一些时间渲染）
            page.wait_for_timeout(2000)  # 等待 2 秒
            
            # 尝试等待网络空闲（最多等待 5 秒，不强制要求）
            # 如果超时也不影响，因为很多网站有持续的网络请求（如统计、广告等）
            try:
                page.wait_for_load_state('networkidle', timeout=5000)
            except PlaywrightTimeoutError:
                # networkidle 超时是正常的，很多网站有持续的网络请求
                # 不记录警告，因为我们已经等待了足够的时间让内容加载
                pass
            
            # 再等待一小段时间，确保动态内容渲染完成
            page.wait_for_timeout(1000)  # 等待 1 秒
            
            # 尝试滚动页面以触发懒加载内容
            try:
                # 滚动到页面底部
                page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
                page.wait_for_timeout(1000)  # 等待 1 秒让内容加载
                # 滚动回顶部
                page.evaluate("window.scrollTo(0, 0)")
                page.wait_for_timeout(1000)  # 再等待 1 秒
            except Exception as e:
                logger.warning(f"⚠️ [Playwright] 滚动页面时出错: {e}")
            
            # 获取渲染后的 HTML
            html = page.content()
            
            # 关闭浏览器
            browser.close()
            
            logger.info(f"✅ [Playwright] 网页抓取成功，长度: {len(html)} 字符")
            return html
            
    except PlaywrightTimeoutError:
        logger.warning(f"⚠️ [Playwright] 网页加载超时: {url}")
        return None
    except Exception as e:
        logger.error(f"❌ [Playwright] 网页抓取失败: {e}", exc_info=True)
        return None


def fetch_webpage(url: str) -> Optional[str]:
    """
    抓取网页HTML内容（使用 requests，仅支持静态网页）
    
    Args:
        url: 网页URL
        
    Returns:
        Optional[str]: HTML内容，如果失败返回None
    """
    try:
        logger.info(f"🌐 [Requests] 开始抓取网页: {url}")
        
        response = requests.get(
            url,
            headers=DEFAULT_HEADERS,
            timeout=REQUEST_TIMEOUT,
            allow_redirects=True
        )
        
        # 检查状态码
        if response.status_code != 200:
            logger.warning(f"⚠️ [Requests] 网页返回状态码: {response.status_code}")
            return None
        
        # 检测编码
        if response.encoding:
            response.encoding = response.encoding
        else:
            # 尝试从响应头或内容中检测编码
            response.encoding = response.apparent_encoding or 'utf-8'
        
        logger.info(f"✅ [Requests] 网页抓取成功，长度: {len(response.text)} 字符")
        return response.text
        
    except requests.exceptions.Timeout:
        logger.error(f"❌ [Requests] 网页抓取超时: {url}")
        return None
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ [Requests] 网页抓取失败: {e}")
        return None
    except Exception as e:
        logger.error(f"❌ [Requests] 网页抓取异常: {e}", exc_info=True)
        return None


def extract_text_from_html(html: str, max_length: int = 50000) -> str:
    """
    从HTML中提取可见文本
    优先提取 article、main 等主要内容区域
    
    Args:
        html: HTML内容
        max_length: 最大文本长度（字符数）
        
    Returns:
        str: 提取的文本内容
    """
    try:
        # 使用 lxml 解析器（更快），如果失败则使用 html.parser
        try:
            soup = BeautifulSoup(html, 'lxml')
        except Exception:
            logger.warning("⚠️ lxml 解析失败，使用 html.parser")
            soup = BeautifulSoup(html, 'html.parser')
        
        # 移除不需要的标签
        for tag_name in REMOVE_TAGS:
            for tag in soup.find_all(tag_name):
                if tag:
                    tag.decompose()
        
        # 移除广告、评论等区域（通过类名）
        # 先收集需要移除的元素，避免在遍历时修改导致的问题
        elements_to_remove = []
        for element in soup.find_all(class_=True):
            if element is None:
                continue
            try:
                class_attr = element.get('class', [])
                if class_attr:
                    class_names = ' '.join(class_attr)
                    for pattern in REMOVE_CLASS_PATTERNS:
                        if pattern.search(class_names):
                            elements_to_remove.append(element)
                            break
            except (AttributeError, TypeError):
                # 如果元素没有 get 方法或 class 属性，跳过
                continue
        
        # 统一移除
        for element in elements_to_remove:
            if element:
                element.decompose()
        
        # 优先提取主要内容区域
        text = ""
        
        # 策略1: 尝试提取 article 标签
        article = soup.find('article')
        if article:
            text = article.get_text(separator='\n\n', strip=True)
            logger.info("✅ 从 article 标签提取文本")
        
        # 策略2: 如果没有 article，尝试 main 标签
        if not text or len(text.strip()) < 100:
            main = soup.find('main')
            if main:
                text = main.get_text(separator='\n\n', strip=True)
                logger.info("✅ 从 main 标签提取文本")
        
        # 策略3: 尝试查找常见的内容容器（如 .content, .post, .article-content 等）
        if not text or len(text.strip()) < 100:
            # 按优先级尝试不同的选择器
            content_elements = [
                soup.find(class_='content'),
                soup.find(class_='post'),
                soup.find(class_='article-content'),
                soup.find(class_='article-body'),
                soup.find(id='content'),
                soup.find(id='article'),
                soup.find(id='post'),
                soup.find('div', class_=lambda x: x and 'article' in ' '.join(x).lower()),
                soup.find('div', class_=lambda x: x and 'content' in ' '.join(x).lower()),
            ]
            for content_elem in content_elements:
                if content_elem:
                    candidate_text = content_elem.get_text(separator='\n\n', strip=True)
                    if len(candidate_text.strip()) > len(text.strip()):
                        text = candidate_text
                        logger.info(f"✅ 从内容容器提取文本，长度: {len(text)} 字符")
                        break
        
        # 策略4: 如果以上都失败，提取整个 body
        if not text or len(text.strip()) < 100:
            body = soup.find('body')
            if body:
                text = body.get_text(separator='\n\n', strip=True)
                logger.info("✅ 从 body 标签提取文本")
            else:
                text = soup.get_text(separator='\n\n', strip=True)
                logger.info("✅ 从整个文档提取文本")
        
        # 清理文本
        # 1. 移除多余的空白行
        lines = [line.strip() for line in text.split('\n') if line.strip()]
        text = '\n\n'.join(lines)
        
        # 2. 限制长度
        if len(text) > max_length:
            text = text[:max_length]
            text += '\n\n[内容已截断，原文可能更长]'
            logger.warning(f"⚠️ 文本长度超过限制，已截断到 {max_length} 字符")
        
        logger.info(f"✅ 文本提取成功，长度: {len(text)} 字符")
        return text
        
    except Exception as e:
        logger.error(f"❌ HTML解析失败: {e}", exc_info=True)
        return ""


def scrape_website(url: str, max_text_length: int = 50000) -> Tuple[Optional[str], Optional[str]]:
    """
    从网站URL提取可见文本
    优先使用 Playwright（支持 JavaScript 渲染），失败则回退到 requests
    
    Args:
        url: 网页URL
        max_text_length: 最大文本长度
        
    Returns:
        tuple[Optional[str], Optional[str]]: (提取的文本, 错误信息)
        如果成功，返回 (文本内容, None)
        如果失败，返回 (None, 错误信息)
    """
    # 1. 验证和规范化URL
    if not validate_url(url):
        return None, "URL格式无效"
    
    normalized_url = normalize_url(url)
    
    # 2. 优先使用 Playwright 抓取（支持动态网页）
    html = None
    if PLAYWRIGHT_AVAILABLE:
        html = fetch_webpage_with_playwright(normalized_url)
        if html:
            logger.info("✅ 使用 Playwright 成功抓取网页")
    
    # 3. 如果 Playwright 失败或不可用，回退到 requests
    if not html:
        logger.info("🔄 回退到 requests 方式抓取网页")
        html = fetch_webpage(normalized_url)
        if html is None:
            return None, "无法访问该网页，请检查URL是否正确或网络连接"
    
    # 4. 提取文本
    text = extract_text_from_html(html, max_text_length)
    
    # 检查提取的文本长度
    text_stripped = text.strip() if text else ""
    text_length = len(text_stripped)
    
    logger.info(f"📊 文本提取结果: 原始长度={len(text) if text else 0}, 清理后长度={text_length}")
    
    if not text or text_length < 50:
        logger.warning(f"⚠️ 提取的文本太短: {text_length} 字符")
        return None, f"无法从网页中提取有效文本（仅提取到 {text_length} 字符），可能是网页需要登录、使用了动态加载或内容受保护"
    
    return text, None


__all__ = ['scrape_website', 'validate_url', 'normalize_url']
