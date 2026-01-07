"""
费曼学习评估器
评估用户对词条的解释，给出分数和反馈
"""
import json
import re
from typing import Tuple

from langchain_core.messages import HumanMessage, SystemMessage

try:
    from .llm import get_default_llm
except ImportError:
    from llm import get_default_llm


# 评估系统提示词
EVALUATOR_SYSTEM_PROMPT = """你是一位专业的学习评估专家，负责评估用户对某个概念/词条的解释。

## 你的任务
用户会尝试用自己的话解释一个概念，你需要：
1. 评估解释的准确性和完整性
2. 给出0-100的分数
3. 提供友好、鼓励性的反馈
4. 根据分数判定学习状态

## 评分标准
- 90-100分（已掌握 mastered）：解释准确、完整、能用简单的话说清楚核心概念
- 70-89分（待复习 needs_review）：基本理解正确，但有些细节不够准确或遗漏
- 50-69分（需改进 needs_improve）：有一定理解，但存在明显错误或遗漏重要内容
- 0-49分（未掌握 not_mastered）：理解有严重偏差或基本没有理解

## 角色适配
用户会选择一个角色来解释，你需要根据角色调整评分标准：
- 对"5岁孩子"：使用最简单、形象的语言，像讲故事一样即可得高分
- 对"小学生"：使用简单易懂的语言，结合生活例子即可得高分
- 对"中学生"：使用基础概念解释，可以适当使用专业词汇
- 对"大学生"：需要专业但易懂的方式解释，可以涉及相关概念
- 对"研究生"：需要精确的专业术语和理论框架，要求更高的准确性和深度

## 输出格式
必须严格按照以下JSON格式输出，不要包含其他内容：
```json
{
  "score": 85,
  "status": "needs_review",
  "feedback": "你的解释...",
  "highlights": ["做得好的点1", "做得好的点2"],
  "suggestions": ["可以改进的点1"]
}
```

## 反馈原则
1. 始终保持鼓励性和建设性
2. 先肯定做得好的地方
3. 温和地指出可以改进的地方
4. 给出具体的学习建议
"""


def evaluate_explanation(
    term: str,
    user_explanation: str,
    selected_role: str,
) -> Tuple[int, str, str]:
    """
    评估用户对词条的解释
    
    Args:
        term: 词条/概念名称
        user_explanation: 用户的解释内容
        selected_role: 选择的角色（如"5岁孩子"、"同事"等）
    
    Returns:
        Tuple[score, status, ai_feedback]:
        - score: 分数（0-100）
        - status: 学习状态（mastered/needs_review/needs_improve/not_mastered）
        - ai_feedback: AI反馈内容（JSON格式）
    """
    llm = get_default_llm()
    
    # 构建用户消息
    user_message = f"""
## 词条
{term}

## 用户选择的角色
{selected_role}

## 用户的解释
{user_explanation}

请评估这个解释，并按照JSON格式输出评估结果。
"""
    
    # 调用 LLM
    messages = [
        SystemMessage(content=EVALUATOR_SYSTEM_PROMPT.strip()),
        HumanMessage(content=user_message.strip()),
    ]
    
    response = llm.invoke(messages)
    reply = response.content.strip()
    
    # 解析响应
    return _parse_evaluation_response(reply)


def _parse_evaluation_response(reply: str) -> Tuple[int, str, str]:
    """
    解析 LLM 的评估响应
    
    Returns:
        Tuple[score, status, ai_feedback]
    """
    # 尝试提取 JSON
    json_str = _extract_json(reply)
    
    if json_str:
        try:
            data = json.loads(json_str)
            score = int(data.get('score', 50))
            status = data.get('status', _score_to_status(score))
            
            # 验证状态值
            valid_statuses = ['mastered', 'needs_review', 'needs_improve', 'not_mastered']
            if status not in valid_statuses:
                status = _score_to_status(score)
            
            # 确保分数在有效范围内
            score = max(0, min(100, score))
            
            # 完整的反馈 JSON
            ai_feedback = json.dumps(data, ensure_ascii=False)
            
            return score, status, ai_feedback
            
        except (json.JSONDecodeError, ValueError, TypeError) as e:
            print(f"解析评估响应失败: {e}")
    
    # 解析失败，返回默认值
    default_feedback = {
        "score": 60,
        "status": "needs_improve",
        "feedback": "感谢你的解释！继续加油，多练习会越来越好的。",
        "highlights": ["尝试用自己的话解释"],
        "suggestions": ["可以尝试更详细地说明核心概念"]
    }
    return 60, "needs_improve", json.dumps(default_feedback, ensure_ascii=False)


def _extract_json(text: str) -> str | None:
    """从文本中提取 JSON"""
    # 尝试提取代码块中的 JSON
    code_block_match = re.search(r'```(?:json)?\s*([\s\S]*?)```', text)
    if code_block_match:
        return code_block_match.group(1).strip()
    
    # 尝试直接解析
    if text.startswith('{') and text.endswith('}'):
        return text
    
    # 查找 JSON 对象
    start = text.find('{')
    end = text.rfind('}')
    if start != -1 and end > start:
        return text[start:end + 1]
    
    return None


def _score_to_status(score: int) -> str:
    """根据分数返回学习状态"""
    if score >= 90:
        return 'mastered'
    elif score >= 70:
        return 'needs_review'
    elif score >= 50:
        return 'needs_improve'
    else:
        return 'not_mastered'


# 角色列表
LEARNING_ROLES = [
    {"id": "child_5", "name": "5岁孩子", "description": "用最简单的话解释，像讲故事一样"},
    {"id": "elementary", "name": "小学生", "description": "用简单易懂的语言，结合生活例子"},
    {"id": "middle_school", "name": "中学生", "description": "用基础概念解释，可以适当使用专业词汇"},
    {"id": "college", "name": "大学生", "description": "用专业但易懂的方式解释，可以涉及相关概念"},
    {"id": "master", "name": "研究生", "description": "用精确的专业术语和理论框架解释"},
]


def get_available_roles():
    """获取可用的角色列表"""
    return LEARNING_ROLES


__all__ = ["evaluate_explanation", "get_available_roles", "LEARNING_ROLES"]

