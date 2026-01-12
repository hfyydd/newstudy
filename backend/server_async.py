from datetime import datetime
from typing import Dict, List, Optional, Awaitable
from enum import Enum
import asyncio
import uuid
from concurrent.futures import ThreadPoolExecutor

from fastapi import FastAPI, HTTPException, Query, BackgroundTasks
from fastapi import File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import contextlib

try:
    from .curious_student_agent import run_curious_student_agent
    from .simple_explainer_agent import run_simple_explainer_agent
    from .terms_generator import generate_terms_for_topic
    from .note_terms_extractor import extract_terms_from_note
    from .file_text_extractor import extract_text_from_upload
    from .database_async import db
    from .config import database_url
except ImportError:  # pragma: no cover
    from curious_student_agent import run_curious_student_agent
    from simple_explainer_agent import run_simple_explainer_agent
    from terms_generator import generate_terms_for_topic
    from note_terms_extractor import extract_terms_from_note
    from file_text_extractor import extract_text_from_upload
    from database_async import db
    from config import database_url

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
    text: str = Field(default="", description="提取的文本内容")
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


class FlashCardDetailResponse(BaseModel):
    """闪词卡片详情响应模型（含状态）"""
    term: str = Field(..., description="词条")
    status: str = Field(..., description="学习状态")


class FlashCardListWithStatusResponse(BaseModel):
    """闪词卡片列表响应模型（含状态）"""
    note_id: str = Field(..., description="笔记ID")
    cards: List[FlashCardDetailResponse] = Field(..., description="卡片详情列表")
    total: int = Field(..., description="总词条数")
    mastered_count: int = Field(..., description="已掌握数量")


class FlashCardStatusUpdateRequest(BaseModel):
    """闪词卡片状态更新请求模型"""
    term: str = Field(..., description="词条")
    status: str = Field(..., description="学习状态", 
                   pattern="^(notStarted|needsReview|needsImprove|mastered)$")


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
        "手术",
        "预防",
        "康复",
    ],
}


# ==================== 健康检查接口 ====================


@app.get("/health")
async def health_check():
    """健康检查接口"""
    return {
        "status": "healthy",
        "timestamp": datetime.now(),
        "database": "postgresql",
    }


# ==================== Agent 相关接口 ====================


@app.post("/agents/curious-student", response_model=AgentResponse)
async def curious_student(request: AgentRequest):
    """好奇学生Agent"""
    try:
        reply = await run_curious_student_agent(request.text)
        return AgentResponse(reply=reply)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/agents/simple-explainer", response_model=AgentResponse)
async def simple_explainer(request: AgentRequest):
    """简单解释器Agent"""
    try:
        reply = await run_simple_explainer_agent(request.text)
        return AgentResponse(reply=reply)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Topic 相关接口 ====================


@app.get("/topics/terms", response_model=TermsResponse)
async def get_terms(category: str = Query(..., description="术语类别")):
    """获取术语列表"""
    if category not in TERMS_LIBRARY:
        raise HTTPException(
            status_code=404, detail=f"类别 '{category}' 不存在"
        )
    
    return TermsResponse(category=category, terms=TERMS_LIBRARY[category])


# ==================== Notes 相关接口 ====================


@app.post("/notes/extract-terms", response_model=NoteExtractResponse)
async def extract_note_terms(request: NoteExtractRequest):
    """从笔记文本中抽取待学习词语"""
    try:
        terms = await extract_terms_from_note(request.text, request.max_terms)
        return NoteExtractResponse(
            title=request.title,
            text=request.text,
            terms=terms,
            total_chars=len(request.text),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/notes/extract-terms/file", response_model=NoteExtractResponse)
async def extract_note_terms_file(
    title: Optional[str] = None,
    max_terms: int = 30,
    file: UploadFile = File(...),
):
    """从笔记文件中抽取待学习词语（multipart/form-data）"""
    try:
        raw = await file.read()
        text = extract_text_from_upload(file.filename, raw)
        terms = await extract_terms_from_note(text, max_terms)
        return NoteExtractResponse(
            title=title,
            text=text,
            terms=terms,
            total_chars=len(text),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/notes", response_model=NoteResponse)
async def create_note(request: NoteCreateRequest):
    """创建笔记"""
    try:
        note = await db.create_note(request.title, request.content)
        cards = await db.get_flash_cards(note.id)
        return NoteResponse(
            id=note.id,
            title=note.title,
            content=note.content,
            createdAt=note.created_at,
            updatedAt=note.updated_at,
            termCount=len(cards),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/notes/{note_id}", response_model=NoteResponse)
async def get_note(note_id: str):
    """获取笔记详情"""
    try:
        note = await db.get_note(note_id)
        if not note:
            raise HTTPException(status_code=404, detail="笔记不存在")
        
        cards = await db.get_flash_cards(note_id)
        return NoteResponse(
            id=note.id,
            title=note.title,
            content=note.content,
            createdAt=note.created_at,
            updatedAt=note.updated_at,
            termCount=len(cards),
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.put("/notes/{note_id}", response_model=NoteResponse)
async def update_note(note_id: str, request: NoteUpdateRequest):
    """更新笔记"""
    try:
        note = await db.update_note(note_id, request.title, request.content)
        if not note:
            raise HTTPException(status_code=404, detail="笔记不存在")
        
        cards = await db.get_flash_cards(note_id)
        return NoteResponse(
            id=note.id,
            title=note.title,
            content=note.content,
            createdAt=note.created_at,
            updatedAt=note.updated_at,
            termCount=len(cards),
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.delete("/notes/{note_id}")
async def delete_note(note_id: str):
    """删除笔记"""
    try:
        success = await db.delete_note(note_id)
        if not success:
            raise HTTPException(status_code=404, detail="笔记不存在")
        return {"message": "笔记删除成功"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/notes", response_model=List[NoteResponse])
async def list_notes(
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
):
    """获取笔记列表"""
    try:
        notes = await db.list_notes(limit, offset)
        result = []
        for note in notes:
            cards = await db.get_flash_cards(note.id)
            result.append(
                NoteResponse(
                    id=note.id,
                    title=note.title,
                    content=note.content,
                    createdAt=note.created_at,
                    updatedAt=note.updated_at,
                    termCount=len(cards),
                )
            )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Flash Cards 相关接口 ====================


@app.post(
    "/notes/{note_id}/flash-cards/generate",
    response_model=FlashCardGenerateResponse,
)
async def generate_flash_cards(
    note_id: str, request: FlashCardGenerateRequest
):
    """生成闪词卡片"""
    try:
        note = await db.get_note(note_id)
        if not note:
            raise HTTPException(status_code=404, detail="笔记不存在")
        
        terms = await extract_terms_from_note(note.content, request.max_terms)
        cards = await db.create_flash_cards(note_id, terms)
        
        return FlashCardGenerateResponse(
            note_id=note_id, terms=[card.term for card in cards], total=len(cards)
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/notes/{note_id}/flash-cards", response_model=FlashCardListResponse)
async def get_flash_cards(note_id: str):
    """获取闪词卡片列表"""
    try:
        cards = await db.get_flash_cards(note_id)
        return FlashCardListResponse(
            note_id=note_id,
            terms=[card.term for card in cards],
            total=len(cards),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/notes/{note_id}/flash-cards/detail", response_model=FlashCardListWithStatusResponse)
async def get_flash_cards_with_status(note_id: str):
    """获取闪词卡片列表（含状态详情）"""
    try:
        cards = await db.get_flash_cards(note_id)
        card_details = [
            FlashCardDetailResponse(term=card.term, status=card.status)
            for card in cards
        ]
        mastered_count = sum(1 for card in cards if card.status == "mastered")
        return FlashCardListWithStatusResponse(
            note_id=note_id,
            cards=card_details,
            total=len(cards),
            mastered_count=mastered_count,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get(
    "/notes/{note_id}/flash-cards/progress",
    response_model=FlashCardProgressResponse,
)
async def get_flash_card_progress(note_id: str):
    """获取闪词学习进度"""
    try:
        progress = await db.get_flash_card_progress(note_id)
        return FlashCardProgressResponse(**progress)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.put("/notes/{note_id}/flash-cards/status")
async def update_flash_card_status(note_id: str, request: FlashCardStatusUpdateRequest):
    """更新闪词卡片状态"""
    try:
        cards = await db.get_flash_cards(note_id)
        target_card = None
        
        for card in cards:
            if card.term == request.term:
                target_card = card
                break
        
        if not target_card:
            raise HTTPException(status_code=404, detail="闪词卡片不存在")
        
        success = await db.update_flash_card_status(target_card.id, request.status)
        if not success:
            raise HTTPException(status_code=500, detail="更新失败")
        
        return {"message": "状态更新成功"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==================== 统计相关接口 ====================


@app.get("/statistics")
async def get_statistics():
    """获取学习统计"""
    try:
        note_count = await db.get_note_count()
        review_cards = await db.get_review_cards(1000)  # 获取最多1000张卡片进行统计
        
        total_review_cards = len(review_cards)
        
        return {
            "totalNotes": note_count,
            "totalReviewCards": total_review_cards,
            "lastUpdated": datetime.now(),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/review/today")
async def get_today_review_statistics():
    """获取今日复习统计"""
    try:
        # 这里简化实现，实际应该根据复习记录统计
        review_cards = await db.get_review_cards(50)
        return {
            "todayReviewCards": len(review_cards),
            "todayCompletedCards": 0,  # 需要实际实现
            "date": datetime.now().date().isoformat(),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/review/cards", response_model=List[dict])
async def get_review_flash_cards(limit: int = Query(default=50, ge=1, le=100)):
    """获取需要复习的闪词卡片列表"""
    try:
        cards = await db.get_review_cards(limit)
        return [
            {
                "id": card.id,
                "noteId": card.note_id,
                "term": card.term,
                "status": card.status,
                "createdAt": card.created_at,
                "lastReviewedAt": card.last_reviewed_at,
            }
            for card in cards
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ==================== 应用启动和关闭事件 ====================


@app.on_event("startup")
async def startup_event():
    """应用启动时初始化数据库连接池"""
    await db.init_pool()


@app.on_event("shutdown")
async def shutdown_event():
    """应用关闭时清理数据库连接"""
    await db.close()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)


# ==================== 异步文档处理 ====================

# 异步任务状态枚举
class TaskStatus(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


# 异步任务存储（内存中，生产环境建议用Redis）
_task_store: Dict[str, dict] = {}

# 线程池用于CPU密集型任务
_ocr_executor = ThreadPoolExecutor(max_workers=4)

# 配置
ASYNC_FILE_SIZE_THRESHOLD = 5 * 1024 * 1024  # 5MB
ASYNC_PAGE_COUNT_THRESHOLD = 10  # 10页


class AsyncTaskResponse(BaseModel):
    """异步任务响应"""
    task_id: str
    status: TaskStatus
    message: str


class AsyncTaskResult(BaseModel):
    """异步任务结果"""
    task_id: str
    status: TaskStatus
    text: Optional[str] = None
    terms: Optional[List[str]] = None
    error: Optional[str] = None


def _create_task(task_id: str, message: str) -> dict:
    """创建异步任务"""
    task = {
        "task_id": task_id,
        "status": TaskStatus.PENDING,
        "message": message,
        "text": None,
        "terms": None,
        "error": None,
        "created_at": datetime.now().isoformat(),
        "completed_at": None,
    }
    _task_store[task_id] = task
    return task


def _update_task(task_id: str, status: TaskStatus, **kwargs):
    """更新异步任务"""
    if task_id in _task_store:
        _task_store[task_id].update({
            "status": status,
            **kwargs,
        })
        if status in (TaskStatus.COMPLETED, TaskStatus.FAILED):
            _task_store[task_id]["completed_at"] = datetime.now().isoformat()


async def _process_file_async(task_id: str, filename: str, raw: bytes, max_terms: int):
    """后台处理文件提取（异步任务）"""
    try:
        _update_task(task_id, TaskStatus.PROCESSING, message="正在提取文本...")
        
        # 在线程池中运行CPU密集型OCR操作
        loop = asyncio.get_event_loop()
        text = await loop.run_in_executor(
            _ocr_executor,
            lambda: extract_text_from_upload(filename or "unknown", raw)
        )
        
        _update_task(task_id, TaskStatus.PROCESSING, message="正在提取术语...")
        
        # 提取术语
        terms = await extract_terms_from_note(text, max_terms)
        
        _task_store[task_id].update({
            "status": TaskStatus.COMPLETED,
            "message": "处理完成",
            "text": text,
            "terms": terms,
        })
    except Exception as e:
        _update_task(task_id, TaskStatus.FAILED, error=str(e), message="处理失败")


@app.post("/notes/extract-terms/file/async", response_model=AsyncTaskResponse)
async def extract_note_terms_file_async(
    title: Optional[str] = None,
    max_terms: int = 30,
    file: UploadFile = File(...),
):
    """
    异步从笔记文件中抽取待学习词语
    
    适用于大文件（>5MB或>10页），立即返回任务ID，可通过API查询进度
    """
    task_id = str(uuid.uuid4())[:8]
    raw = await file.read()
    file_size = len(raw)
    
    # 创建任务
    _create_task(
        task_id,
        f"文件 {file.filename} ({file_size/1024:.1f}KB) 已加入队列"
    )
    
    # 启动后台任务
    asyncio.create_task(
        _process_file_async(task_id, file.filename, raw, max_terms)
    )
    
    return AsyncTaskResponse(
        task_id=task_id,
        status=TaskStatus.PENDING,
        message=_task_store[task_id]["message"]
    )


@app.get("/notes/extract-terms/async/{task_id}", response_model=AsyncTaskResult)
async def get_async_task_result(task_id: str):
    """获取异步任务结果"""
    task = _task_store.get(task_id)
    
    if not task:
        raise HTTPException(status_code=404, detail="任务不存在")
    
    return AsyncTaskResult(
        task_id=task_id,
        status=task["status"],
        text=task.get("text"),
        terms=task.get("terms"),
        error=task.get("error"),
    )


@app.get("/notes/extract-terms/async", response_model=Dict[str, AsyncTaskResult])
async def list_async_tasks() -> Dict[str, AsyncTaskResult]:
    """列出所有异步任务"""
    return {
        task_id: AsyncTaskResult(
            task_id=task_id,
            status=task["status"],
            text=task.get("text"),
            terms=task.get("terms"),
            error=task.get("error"),
        )
        for task_id, task in _task_store.items()
    }


@app.delete("/notes/extract-terms/async/{task_id}")
async def delete_async_task(task_id: str):
    """删除已完成的任务"""
    if task_id not in _task_store:
        raise HTTPException(status_code=404, detail="任务不存在")
    
    if _task_store[task_id]["status"] == TaskStatus.PROCESSING:
        raise HTTPException(status_code=400, detail="无法删除正在进行的任务")
    
    del _task_store[task_id]
    return {"message": "任务已删除"}