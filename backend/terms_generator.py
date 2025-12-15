"""
词汇生成器 - 使用 LLM 为自定义主题生成相关术语列表
"""
import json
import re
from typing import List

from langchain_core.messages import HumanMessage, SystemMessage

try:
    from .llm import get_default_llm
except ImportError:
    from llm import get_default_llm


TERMS_GENERATION_PROMPT = """你是一位专业的教育内容生成助手。你的任务是根据用户提供的主题，生成该主题下最核心、最重要的10-15个专业术语或概念。

## 输出要求
1. 返回纯 JSON 格式，不要任何其他文字
2. JSON 格式：{"terms": ["术语1", "术语2", "术语3", ...]}
3. 术语数量：10-15个
4. 术语应该是该主题的核心概念，按重要性排序
5. 术语应该是中文（如果是中文主题）或英文（如果是英文主题）
6. 术语应该是单个词或短语，不要太长（建议2-6个字）

## 示例

主题：经济学
输出：
```json
{
  "terms": ["通货膨胀", "货币政策", "财政赤字", "边际效用", "比较优势", "供给弹性", "需求曲线", "资本积累", "凯恩斯主义", "外部性", "市场失灵", "机会成本", "GDP", "CPI"]
}
```

主题：机器学习
输出：
```json
{
  "terms": ["监督学习", "无监督学习", "神经网络", "深度学习", "梯度下降", "过拟合", "交叉验证", "特征工程", "模型评估", "准确率", "召回率", "F1分数", "正则化", "损失函数"]
}
```

现在请为以下主题生成术语列表："""


def generate_terms_for_topic(topic: str) -> List[str]:
    """
    为指定主题生成相关术语列表
    
    Args:
        topic: 主题名称（如 "机器学习"、"量子物理" 等）
    
    Returns:
        术语列表
    """
    llm = get_default_llm()
    
    # 构建提示词
    prompt = TERMS_GENERATION_PROMPT + f"\n\n主题：{topic}"
    
    # 调用 LLM
    messages = [
        SystemMessage(content="你是一位专业的教育内容生成助手。"),
        HumanMessage(content=prompt)
    ]
    
    try:
        response = llm.invoke(messages)
        content = response.content.strip()
        
        # 尝试提取 JSON
        # 如果响应包含代码块，提取其中的 JSON
        json_match = re.search(r'```json\s*(\{.*?\})\s*```', content, re.DOTALL)
        if json_match:
            json_str = json_match.group(1)
        elif content.startswith('{'):
            # 直接是 JSON
            json_str = content
        else:
            # 尝试找到第一个 { 到最后一个 }
            start = content.find('{')
            end = content.rfind('}')
            if start != -1 and end != -1:
                json_str = content[start:end+1]
            else:
                raise ValueError("无法从响应中提取 JSON")
        
        # 解析 JSON
        data = json.loads(json_str)
        terms = data.get("terms", [])
        
        # 验证和清理
        if not isinstance(terms, list):
            raise ValueError("terms 必须是数组")
        
        # 过滤空字符串和无效项
        terms = [str(term).strip() for term in terms if term and str(term).strip()]
        
        if not terms:
            raise ValueError("生成的术语列表为空")
        
        # 限制数量（最多15个）
        return terms[:15]
        
    except Exception as e:
        # 如果生成失败，返回一个默认列表
        raise ValueError(f"生成术语失败: {str(e)}")


__all__ = ["generate_terms_for_topic"]

