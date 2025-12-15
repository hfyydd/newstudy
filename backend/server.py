from typing import List

from fastapi import FastAPI, HTTPException, Query
from fastapi import File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

try:
    from .curious_student_agent import run_curious_student_agent
    from .simple_explainer_agent import run_simple_explainer_agent
    from .terms_generator import generate_terms_for_topic
    from .note_terms_extractor import extract_terms_from_note
    from .file_text_extractor import extract_text_from_upload
except ImportError:  # pragma: no cover
    from curious_student_agent import run_curious_student_agent
    from simple_explainer_agent import run_simple_explainer_agent
    from terms_generator import generate_terms_for_topic
    from note_terms_extractor import extract_terms_from_note
    from file_text_extractor import extract_text_from_upload


app = FastAPI(title="Agent Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class AgentRequest(BaseModel):
    text: str = Field(..., min_length=1, description="用户输入文本")


class AgentResponse(BaseModel):
    reply: str


class TermsResponse(BaseModel):
    category: str = Field(..., min_length=1, description="术语类别标识")
    terms: List[str] = Field(..., min_items=1, description="术语列表")


class NoteExtractRequest(BaseModel):
    title: str | None = Field(default=None, description="笔记标题（可选）")
    text: str = Field(..., min_length=1, description="笔记内容（纯文本）")
    max_terms: int = Field(default=30, ge=5, le=60, description="最多返回词语数量")


class NoteExtractResponse(BaseModel):
    title: str | None = Field(default=None, description="笔记标题（回显）")
    terms: List[str] = Field(..., description="抽取出的词语列表（可编辑）")
    total_chars: int = Field(..., ge=0, description="笔记字符数")


TERMS_LIBRARY = {
    "economics": [
        "通货膨胀",
        "货币政策",
        "财政赤字",
        "边际效用",
        "比较优势",
        "供给弹性",
        "需求曲线",
        "资本积累",
        "凯恩斯主义",
        "外部性",
    ],
    "finance": [
        "股票",
        "债券",
        "基金",
        "投资组合",
        "风险管理",
        "资产配置",
        "收益率",
        "市盈率",
        "股息",
        "市场波动",
    ],
    "technology": [
        "人工智能",
        "机器学习",
        "深度学习",
        "神经网络",
        "算法",
        "数据结构",
        "编程语言",
        "软件工程",
        "云计算",
        "大数据",
    ],
    "medicine": [
        "细胞",
        "器官",
        "疾病",
        "症状",
        "诊断",
        "治疗",
        "药物",
        "免疫系统",
        "血液循环",
        "神经系统",
    ],
    "law": [
        "法律",
        "法规",
        "合同",
        "权利",
        "义务",
        "责任",
        "诉讼",
        "判决",
        "律师",
        "法庭",
    ],
    "psychology": [
        "认知",
        "情绪",
        "行为",
        "记忆",
        "学习",
        "人格",
        "心理",
        "意识",
        "潜意识",
        "动机",
    ],
    "philosophy": [
        "存在",
        "真理",
        "知识",
        "道德",
        "自由",
        "意志",
        "理性",
        "经验",
        "逻辑",
        "形而上学",
    ],
    "history": [
        "朝代",
        "文明",
        "战争",
        "革命",
        "文化",
        "社会",
        "政治",
        "经济",
        "人物",
        "事件",
    ],
}


def _call_agent(agent_fn, payload: AgentRequest) -> AgentResponse:
    try:
        result = agent_fn(payload.text)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    return AgentResponse(reply=result)


@app.post("/agents/curious-student", response_model=AgentResponse)
def run_curious_student(payload: AgentRequest) -> AgentResponse:
    return _call_agent(run_curious_student_agent, payload)


@app.post("/agents/simple-explainer", response_model=AgentResponse)
def run_simple_explainer(payload: AgentRequest) -> AgentResponse:
    return _call_agent(run_simple_explainer_agent, payload)


@app.get("/topics/terms", response_model=TermsResponse)
def list_terms(category: str = Query("economics", min_length=1)) -> TermsResponse:
    """
    获取指定主题的术语列表
    
    如果主题在预设库中，直接返回预设词汇
    如果不在，使用 LLM 生成该主题的相关术语
    """
    key = category.lower()
    
    # 先检查预设库
    terms = TERMS_LIBRARY.get(key)
    
    if not terms:
        # 如果不在预设库中，使用 LLM 生成
        try:
            # 使用原始 category（保持大小写）作为主题名称
            # 如果 category 是下划线格式（如 "machine_learning"），转换为空格格式
            topic_name = category.replace("_", " ").replace("-", " ")
            terms = generate_terms_for_topic(topic_name)
            # 将生成的词汇添加到缓存（可选，这里不持久化）
        except Exception as e:
            raise HTTPException(
                status_code=500,
                detail=f"生成术语失败: {str(e)}"
            ) from e
    
    return TermsResponse(category=key, terms=terms)


@app.post("/notes/extract-terms", response_model=NoteExtractResponse)
def extract_terms(payload: NoteExtractRequest) -> NoteExtractResponse:
    """
    提交笔记文本，解析并抽取待学习词语。

    - 优先 LLM 抽取（更贴近“重点概念”）
    - LLM 不可用时使用规则兜底抽取
    """
    try:
        terms = extract_terms_from_note(payload.text, max_terms=payload.max_terms)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    # 允许为空：如果笔记太短或不含有效词语
    return NoteExtractResponse(
        title=payload.title,
        terms=terms,
        total_chars=len(payload.text),
    )


@app.post("/notes/extract-terms/file", response_model=NoteExtractResponse)
async def extract_terms_from_file(
    file: UploadFile = File(...),
    max_terms: int = 30,
) -> NoteExtractResponse:
    """
    上传笔记文件（支持 pdf/docx/txt/md），解析并抽取待学习词语。
    """
    try:
        raw = await file.read()
        text = extract_text_from_upload(file.filename, raw)
        terms = extract_terms_from_note(text, max_terms=max_terms)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    return NoteExtractResponse(
        title=file.filename,
        terms=terms,
        total_chars=len(text),
    )


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(app, host="0.0.0.0", port=8000)
