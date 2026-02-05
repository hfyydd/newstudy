"""
邮件发送服务
用于发送邮箱验证码等邮件
"""
import logging
import aiosmtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from config import (
    SMTP_HOST,
    SMTP_PORT,
    SMTP_USER,
    SMTP_PASSWORD,
    SMTP_FROM_EMAIL,
    SMTP_FROM_NAME,
    SMTP_USE_TLS,
)

logger = logging.getLogger(__name__)


async def send_verification_code_email(email: str, code: str) -> bool:
    """
    发送验证码邮件
    
    Args:
        email: 收件人邮箱
        code: 验证码
    
    Returns:
        是否发送成功
    """
    # 如果没有配置 SMTP，则仅打印到日志（开发环境）
    if not SMTP_USER or not SMTP_PASSWORD:
        logger.warning(f"⚠️ SMTP 未配置，验证码仅打印到日志: {email} -> {code}")
        logger.info(f"📧 验证码: {code} (发送到 {email})")
        return True  # 开发环境返回成功
    
    try:
        # 创建邮件
        message = MIMEMultipart("alternative")
        message["From"] = f"{SMTP_FROM_NAME} <{SMTP_FROM_EMAIL}>"
        message["To"] = email
        message["Subject"] = "FlashMind 验证码"
        
        # 邮件正文
        text_content = f"""
您好！

您的 FlashMind 验证码是：{code}

验证码将在 5 分钟后过期。

如果您没有请求此验证码，请忽略此邮件。

---
FlashMind 团队
"""
        
        html_content = f"""
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body {{
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
        }}
        .container {{
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }}
        .code {{
            font-size: 32px;
            font-weight: bold;
            color: #667EEA;
            text-align: center;
            padding: 20px;
            background-color: #f5f5f5;
            border-radius: 8px;
            margin: 20px 0;
        }}
        .footer {{
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #999;
            font-size: 12px;
        }}
    </style>
</head>
<body>
    <div class="container">
        <h2>您好！</h2>
        <p>您的 FlashMind 验证码是：</p>
        <div class="code">{code}</div>
        <p>验证码将在 5 分钟后过期。</p>
        <p>如果您没有请求此验证码，请忽略此邮件。</p>
        <div class="footer">
            <p>---</p>
            <p>FlashMind 团队</p>
        </div>
    </div>
</body>
</html>
"""
        
        # 添加文本和 HTML 版本
        text_part = MIMEText(text_content, "plain", "utf-8")
        html_part = MIMEText(html_content, "html", "utf-8")
        message.attach(text_part)
        message.attach(html_part)
        
        # 发送邮件
        await aiosmtplib.send(
            message,
            hostname=SMTP_HOST,
            port=SMTP_PORT,
            username=SMTP_USER,
            password=SMTP_PASSWORD,
            use_tls=SMTP_USE_TLS,
        )
        
        logger.info(f"✅ 验证码邮件已发送: {email}")
        return True
        
    except Exception as e:
        logger.error(f"❌ 发送验证码邮件失败: {e}", exc_info=True)
        # 即使发送失败，也打印到日志（开发环境）
        logger.info(f"📧 验证码（邮件发送失败，仅打印）: {code} (发送到 {email})")
        return False  # 生产环境应该返回 False，但开发环境可以返回 True


async def send_email_async(to_email: str, subject: str, text_content: str, html_content: str = None) -> bool:
    """
    发送通用邮件（异步）
    
    Args:
        to_email: 收件人邮箱
        subject: 邮件主题
        text_content: 文本内容
        html_content: HTML 内容（可选）
    
    Returns:
        是否发送成功
    """
    if not SMTP_USER or not SMTP_PASSWORD:
        logger.warning(f"⚠️ SMTP 未配置，邮件仅打印到日志")
        logger.info(f"📧 邮件主题: {subject}")
        logger.info(f"📧 收件人: {to_email}")
        logger.info(f"📧 内容: {text_content}")
        return True
    
    try:
        message = MIMEMultipart("alternative")
        message["From"] = f"{SMTP_FROM_NAME} <{SMTP_FROM_EMAIL}>"
        message["To"] = to_email
        message["Subject"] = subject
        
        text_part = MIMEText(text_content, "plain", "utf-8")
        message.attach(text_part)
        
        if html_content:
            html_part = MIMEText(html_content, "html", "utf-8")
            message.attach(html_part)
        
        await aiosmtplib.send(
            message,
            hostname=SMTP_HOST,
            port=SMTP_PORT,
            username=SMTP_USER,
            password=SMTP_PASSWORD,
            use_tls=SMTP_USE_TLS,
        )
        
        logger.info(f"✅ 邮件已发送: {to_email}")
        return True
        
    except Exception as e:
        logger.error(f"❌ 发送邮件失败: {e}", exc_info=True)
        return False
