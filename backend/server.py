from datetime import datetime
from typing import Dict, List, Optional

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
    from .database import db
except ImportError:  # pragma: no cover
    from curious_student_agent import run_curious_student_agent
    from simple_explainer_agent import run_simple_explainer_agent
    from terms_generator import generate_terms_for_topic
    from note_terms_extractor import extract_terms_from_note
    from file_text_extractor import extract_text_from_upload
    from database import db


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
    terms: List[str] = Field(..., min_length=1, description="术语列表")


class NoteExtractRequest(BaseModel):
    title: str | None = Field(default=None, description="笔记标题（可选）")
    text: str = Field(..., min_length=1, description="笔记内容（纯文本）")
    max_terms: int = Field(default=30, ge=5, le=60, description="最多返回词语数量")


class NoteExtractResponse(BaseModel):
    title: str | None = Field(default=None, description="笔记标题（回显）")
    terms: List[str] = Field(..., description="抽取出的词语列表（可编辑）")
    total_chars: int = Field(..., ge=0, description="笔记字符数")


# ==================== 笔记管理相关模型 ====================


class NoteCreateRequest(BaseModel):
    title: Optional[str] = Field(default=None, description="笔记标题（可选）")
    content: str = Field(..., min_length=1, description="笔记内容（文本）")


class NoteUpdateRequest(BaseModel):
    """更新笔记请求模型"""
    title: Optional[str] = Field(default=None, description="笔记标题（可选）")
    content: Optional[str] = Field(default=None, min_length=1, description="笔记内容（可选）")


class NoteResponse(BaseModel):
    id: str = Field(..., description="笔记ID")
    title: Optional[str] = Field(default=None, description="笔记标题")
    content: str = Field(..., description="笔记内容")
    createdAt: datetime = Field(..., description="创建时间")
    updatedAt: datetime = Field(..., description="更新时间")
    termCount: int = Field(default=0, description="词条数量")


class FlashCardGenerateRequest(BaseModel):
    max_terms: int = Field(default=30, ge=5, le=60, description="最多生成词条数量")


class FlashCardGenerateResponse(BaseModel):
    note_id: str = Field(..., description="笔记ID")
    terms: List[str] = Field(..., description="生成的词条列表")
    total: int = Field(..., description="生成的总词条数")


class FlashCardProgressResponse(BaseModel):
    total: int = Field(..., description="总词条数")
    mastered: int = Field(..., description="已掌握数量")
    needsReview: int = Field(..., description="待复习数量")
    needsImprove: int = Field(..., description="需改进数量")
    notStarted: int = Field(..., description="未学习数量")


class FlashCardListResponse(BaseModel):
    """闪词卡片列表响应模型"""
    note_id: str = Field(..., description="笔记ID")
    terms: List[str] = Field(..., description="词条列表")
    total: int = Field(..., description="总词条数")


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


# ==================== 笔记管理接口 ====================


class NoteListItemResponse(BaseModel):
    """笔记列表项响应模型"""
    id: str = Field(..., description="笔记ID")
    title: Optional[str] = Field(default=None, description="笔记标题")
    createdAt: datetime = Field(..., description="创建时间")
    updatedAt: datetime = Field(..., description="更新时间")
    termCount: int = Field(default=0, description="词条数量")
    masteredCount: int = Field(default=0, description="已掌握词条数")
    reviewCount: int = Field(default=0, description="待复习词条数")


class NotesListResponse(BaseModel):
    """笔记列表响应模型"""
    notes: List[NoteListItemResponse] = Field(..., description="笔记列表")
    total: int = Field(..., description="总笔记数")


@app.get("/notes", response_model=NotesListResponse)
def list_notes() -> NotesListResponse:
    """
    获取笔记列表
    
    返回所有笔记的简要信息，包括学习进度统计。
    """
    try:
        notes = db.list_notes()
        
        note_items = []
        for note in notes:
            # 获取每个笔记的闪词学习进度
            progress = db.get_flash_card_progress(note.id)
            
            note_items.append(NoteListItemResponse(
                id=note.id,
                title=note.title,
                createdAt=note.created_at,  # type: ignore
                updatedAt=note.updated_at,  # type: ignore
                termCount=progress["total"],
                masteredCount=progress["mastered"],
                reviewCount=progress["needsReview"],
            ))
        
        return NotesListResponse(
            notes=note_items,
            total=len(note_items),
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/notes", response_model=NoteResponse)
def create_note(payload: NoteCreateRequest) -> NoteResponse:
    """
    创建笔记
    
    保存用户的笔记内容（文本），返回创建的笔记信息。
    """
    try:
        note = db.create_note(title=payload.title, content=payload.content)
        return NoteResponse(
            id=note.id,
            title=note.title,
            content=note.content,
            createdAt=note.created_at,  # type: ignore
            updatedAt=note.updated_at,  # type: ignore
            termCount=0,  # type: ignore
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.get("/notes/{note_id}", response_model=NoteResponse)
def get_note(note_id: str) -> NoteResponse:
    """
    获取笔记详情
    
    根据笔记ID返回笔记的完整信息。
    """
    note = db.get_note(note_id)
    if not note:
        raise HTTPException(status_code=404, detail=f"笔记 {note_id} 不存在")

    # 获取该笔记的词条数量
    cards = db.get_flash_cards(note_id)
    term_count = len(cards)

    return NoteResponse(
        id=note.id,
        title=note.title,
        content=note.content,
        createdAt=note.created_at,  # type: ignore
        updatedAt=note.updated_at,  # type: ignore
        termCount=term_count,  # type: ignore
    )


@app.put("/notes/{note_id}", response_model=NoteResponse)
def update_note(note_id: str, payload: NoteUpdateRequest) -> NoteResponse:
    """
    更新笔记
    
    更新笔记的标题和/或内容。如果只提供部分字段，只更新提供的字段。
    """
    # 检查笔记是否存在
    existing_note = db.get_note(note_id)
    if not existing_note:
        raise HTTPException(status_code=404, detail=f"笔记 {note_id} 不存在")

    # 验证至少提供一个更新字段
    if payload.title is None and payload.content is None:
        raise HTTPException(
            status_code=400,
            detail="至少需要提供一个更新字段（title 或 content）"
        )

    try:
        updated_note = db.update_note(
            note_id=note_id,
            title=payload.title,
            content=payload.content,
        )

        if not updated_note:
            raise HTTPException(status_code=404, detail=f"笔记 {note_id} 不存在")

        # 获取该笔记的词条数量
        cards = db.get_flash_cards(note_id)
        term_count = len(cards)

        return NoteResponse(
            id=updated_note.id,
            title=updated_note.title,
            content=updated_note.content,
            createdAt=updated_note.created_at,  # type: ignore
            updatedAt=updated_note.updated_at,  # type: ignore
            termCount=term_count,  # type: ignore
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.delete("/notes/{note_id}")
def delete_note(note_id: str) -> Dict[str, str]:
    """
    删除笔记
    
    删除指定笔记及其关联的所有闪词卡片（级联删除）。
    """
    # 检查笔记是否存在
    note = db.get_note(note_id)
    if not note:
        raise HTTPException(status_code=404, detail=f"笔记 {note_id} 不存在")

    try:
        print(f"[Server] 开始删除笔记: {note_id}, 标题: {note.title}")
        success = db.delete_note(note_id)
        if not success:
            raise HTTPException(status_code=404, detail=f"笔记 {note_id} 不存在")

        # 验证删除是否成功
        deleted_note = db.get_note(note_id)
        if deleted_note is not None:
            print(f"[Server] 警告：删除后笔记仍然存在: {note_id}")
        else:
            print(f"[Server] 笔记删除成功: {note_id}")

        return {"message": f"笔记 {note_id} 已删除"}
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        print(f"[Server] 删除笔记异常: {exc}")
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.post("/notes/{note_id}/flash-cards/generate", response_model=FlashCardGenerateResponse)
def generate_flash_cards(
    note_id: str,
    payload: FlashCardGenerateRequest = FlashCardGenerateRequest(),
) -> FlashCardGenerateResponse:
    """
    生成闪词卡片
    
    从笔记内容中提取词条并创建闪词卡片。
    如果笔记已有词条，新词条会追加到现有列表中（自动去重）。
    """
    # 检查笔记是否存在
    note = db.get_note(note_id)
    if not note:
        raise HTTPException(status_code=404, detail=f"笔记 {note_id} 不存在")

    try:
        # 从笔记内容中提取词条
        terms = extract_terms_from_note(note.content, max_terms=payload.max_terms)

        if not terms:
            # 如果没有提取到词条，返回空列表
            return FlashCardGenerateResponse(
                note_id=note_id,
                terms=[],
                total=0,
            )

        # 创建闪词卡片（自动去重，保留已有词条的学习状态）
        new_cards = db.create_flash_cards(note_id, terms)

        # 返回所有词条（包括新生成的和已有的）
        all_cards = db.get_flash_cards(note_id)
        all_terms = [card.term for card in all_cards]

        return FlashCardGenerateResponse(
            note_id=note_id,
            terms=all_terms,
            total=len(all_terms),
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e)) from e
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.get("/notes/{note_id}/flash-cards", response_model=FlashCardListResponse)
def get_flash_cards(note_id: str) -> FlashCardListResponse:
    """
    获取笔记的闪词卡片列表
    
    返回笔记的所有闪词卡片词条列表。
    """
    # 检查笔记是否存在
    note = db.get_note(note_id)
    if not note:
        raise HTTPException(status_code=404, detail=f"笔记 {note_id} 不存在")

    try:
        cards = db.get_flash_cards(note_id)
        terms = [card.term for card in cards]
        return FlashCardListResponse(
            note_id=note_id,
            terms=terms,
            total=len(terms),
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc


class FlashCardStatusUpdateRequest(BaseModel):
    """更新闪词卡片状态请求模型"""
    term: str = Field(..., description="词条")
    status: str = Field(..., description="学习状态：notStarted, needsReview, needsImprove, mastered")


@app.put("/notes/{note_id}/flash-cards/status", response_model=dict)
def update_flash_card_status(
    note_id: str,
    payload: FlashCardStatusUpdateRequest,
) -> dict:
    """
    更新闪词卡片的学习状态
    
    用于标记卡片为已掌握、待复习等状态。
    """
    note = db.get_note(note_id)
    if not note:
        raise HTTPException(status_code=404, detail=f"笔记 {note_id} 不存在")

    # 验证状态值
    valid_statuses = ["notStarted", "needsReview", "needsImprove", "mastered"]
    if payload.status not in valid_statuses:
        raise HTTPException(
            status_code=400,
            detail=f"无效的状态值。允许的值: {', '.join(valid_statuses)}"
        )

    try:
        success = db.update_flash_card_status(
            note_id=note_id,
            term=payload.term,
            status=payload.status,
        )
        
        if not success:
            raise HTTPException(
                status_code=404,
                detail=f"未找到词条 '{payload.term}' 的闪词卡片"
            )
        
        return {
            "success": True,
            "message": f"已更新词条 '{payload.term}' 的状态为 '{payload.status}'"
        }
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.get("/notes/{note_id}/flash-cards/progress", response_model=FlashCardProgressResponse)
def get_flash_card_progress(note_id: str) -> FlashCardProgressResponse:
    """
    获取闪词学习进度
    
    返回笔记的闪词学习进度统计信息。
    """
    # 检查笔记是否存在
    note = db.get_note(note_id)
    if not note:
        raise HTTPException(status_code=404, detail=f"笔记 {note_id} 不存在")

    try:
        progress = db.get_flash_card_progress(note_id)
        return FlashCardProgressResponse(
            total=progress["total"],
            mastered=progress["mastered"],
            needsReview=progress["needsReview"],
            needsImprove=progress["needsImprove"],
            notStarted=progress["notStarted"],
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc


class LearningStatisticsResponse(BaseModel):
    """学习统计响应模型"""
    mastered: int = Field(..., description="已掌握词条数")
    totalTerms: int = Field(..., description="累计学习词条数")
    consecutiveDays: int = Field(..., description="连续学习天数")
    totalMinutes: int = Field(..., description="累计学习时长（分钟）")


@app.get("/statistics", response_model=LearningStatisticsResponse)
def get_learning_statistics() -> LearningStatisticsResponse:
    """
    获取学习统计信息
    
    返回全局学习统计数据，包括已掌握词条数、累计学习词条数、连续学习天数等。
    """
    try:
        stats = db.get_learning_statistics()
        return LearningStatisticsResponse(
            mastered=stats["mastered"],
            totalTerms=stats["totalTerms"],
            consecutiveDays=stats["consecutiveDays"],
            totalMinutes=stats["totalMinutes"],
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc


class TodayReviewStatisticsResponse(BaseModel):
    """今日复习统计响应模型"""
    total: int = Field(..., description="需要复习的词条总数")
    needsReview: int = Field(..., description="困难词条数（需要复习）")
    needsImprove: int = Field(..., description="需改进词条数")


@app.get("/review/today", response_model=TodayReviewStatisticsResponse)
def get_today_review_statistics() -> TodayReviewStatisticsResponse:
    """
    获取今日复习统计信息
    
    返回今日需要复习的词条统计，包括总数、困难词条数、需改进词条数。
    """
    try:
        stats = db.get_today_review_statistics()
        return TodayReviewStatisticsResponse(
            total=stats["total"],
            needsReview=stats["needsReview"],
            needsImprove=stats["needsImprove"],
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc


class ReviewFlashCardResponse(BaseModel):
    """复习闪词卡片响应模型"""
    id: str = Field(..., description="卡片ID")
    noteId: str = Field(..., description="笔记ID")
    noteTitle: Optional[str] = Field(default=None, description="笔记标题")
    term: str = Field(..., description="词条内容")
    status: str = Field(..., description="学习状态：needsReview, needsImprove")
    createdAt: datetime = Field(..., description="创建时间")
    lastReviewedAt: Optional[datetime] = Field(default=None, description="最后复习时间")


class ReviewFlashCardsResponse(BaseModel):
    """复习闪词卡片列表响应模型"""
    cards: List[ReviewFlashCardResponse] = Field(..., description="闪词卡片列表")
    total: int = Field(..., description="总卡片数")


@app.get("/review/cards", response_model=ReviewFlashCardsResponse)
def get_review_flash_cards(include_all: bool = False) -> ReviewFlashCardsResponse:
    """
    获取闪词卡片列表
    
    默认返回所有状态为 needsReview 或 needsImprove 的闪词卡片。
    如果 include_all=True，则返回所有状态的词条。
    """
    try:
        cards = db.get_review_flash_cards(include_all=include_all)
        
        card_responses = []
        for card in cards:
            # 获取笔记信息以包含笔记标题
            note = db.get_note(card.note_id)
            
            card_responses.append(ReviewFlashCardResponse(
                id=card.id,
                noteId=card.note_id,
                noteTitle=note.title if note else None,
                term=card.term,
                status=card.status,
                createdAt=card.created_at,  # type: ignore
                lastReviewedAt=card.last_reviewed_at,  # type: ignore
            ))
        
        return ReviewFlashCardsResponse(
            cards=card_responses,
            total=len(card_responses),
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=str(exc)) from exc


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(app, host="0.0.0.0", port=8000)
