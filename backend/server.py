import logging
import sys
from typing import List
from datetime import datetime, timedelta

from fastapi import FastAPI, HTTPException, Query, Request, Depends
from fastapi import File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

try:
    from .curious_student_agent import run_curious_student_agent
    from .simple_explainer_agent import run_simple_explainer_agent
    from .terms_generator import generate_terms_for_topic
    from .note_terms_extractor import extract_terms_from_note
    from .file_text_extractor import extract_text_from_upload
    from .smart_note_generator import generate_smart_note
    from .web_scraper import scrape_website
    from .db_sql import get_db_cursor, execute_query, execute_one, execute_insert_return_id
    from .get_default_user import get_default_user_id
    from .feynman_evaluator import evaluate_explanation, get_available_roles
except ImportError:  # pragma: no cover
    from curious_student_agent import run_curious_student_agent
    from simple_explainer_agent import run_simple_explainer_agent
    from terms_generator import generate_terms_for_topic
    from note_terms_extractor import extract_terms_from_note
    from file_text_extractor import extract_text_from_upload
    from smart_note_generator import generate_smart_note
    from web_scraper import scrape_website
    from db_sql import get_db_cursor, execute_query, execute_one, execute_insert_return_id
    from get_default_user import get_default_user_id
    from feynman_evaluator import evaluate_explanation, get_available_roles


app = FastAPI(title="Agent Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def log_requests(request: Request, call_next):
    """记录所有HTTP请求"""
    logger.info(f"📥 收到请求: {request.method} {request.url.path}")
    response = await call_next(request)
    logger.info(f"📤 响应状态: {response.status_code}")
    return response


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


class SmartNoteRequest(BaseModel):
    """智能笔记生成请求"""
    user_input: str = Field(..., min_length=1, description="用户输入的学习内容")
    max_terms: int = Field(default=30, ge=5, le=60, description="最多返回词语数量")


class SmartNoteResponse(BaseModel):
    """智能笔记生成响应"""
    note_content: str = Field(..., description="Markdown格式的笔记内容")
    terms: List[str] = Field(..., description="闪词列表")
    input_chars: int = Field(..., ge=0, description="用户输入字符数")


class CreateNoteRequest(BaseModel):
    """创建笔记请求"""
    user_input: str = Field(..., min_length=1, description="用户输入的学习内容")
    max_terms: int = Field(default=30, ge=5, le=60, description="最多返回词语数量")


class CreateNoteFromUrlRequest(BaseModel):
    """从URL创建笔记请求"""
    url: str = Field(..., min_length=1, description="网页URL")
    max_terms: int = Field(default=30, ge=5, le=60, description="最多返回词语数量")
    max_text_length: int = Field(default=50000, ge=1000, le=100000, description="最大文本长度")


class CreateNoteResponse(BaseModel):
    """创建笔记响应"""
    note_id: int = Field(..., description="笔记ID")
    title: str = Field(..., description="笔记标题")
    flash_card_count: int = Field(..., ge=0, description="闪词数量")


class NoteListItem(BaseModel):
    """笔记列表项"""
    id: int
    title: str
    created_at: str
    flash_card_count: int = Field(..., description="闪词总数")
    mastered_count: int = Field(default=0, description="已掌握数量")
    needs_review_count: int = Field(default=0, description="需巩固数量（70-89分）")
    needs_improve_count: int = Field(default=0, description="需改进数量")
    not_mastered_count: int = Field(default=0, description="未掌握数量")


class NotesListResponse(BaseModel):
    """笔记列表响应"""
    notes: List[NoteListItem] = Field(..., description="笔记列表")
    total: int = Field(..., ge=0, description="总数")


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


@app.post("/notes/generate-smart-note", response_model=SmartNoteResponse)
def generate_smart_note_api(payload: SmartNoteRequest) -> SmartNoteResponse:
    """
    根据用户输入生成智能笔记和闪词列表（不保存到数据库）。
    
    - 调用 LLM 生成结构化的 Markdown 笔记
    - 同时提取核心词语作为闪词列表
    - LLM 不可用时使用规则兜底
    """
    logger.info(f"🚀 开始生成智能笔记，输入长度: {len(payload.user_input)} 字符")
    logger.info(f"📝 用户输入前100字: {payload.user_input[:100]}...")
    
    try:
        note_content, terms = generate_smart_note(
            payload.user_input, 
            max_terms=payload.max_terms
        )
        logger.info(f"✅ 智能笔记生成成功！")
        logger.info(f"   - 笔记长度: {len(note_content)} 字符")
        logger.info(f"   - 提取闪词: {len(terms)} 个")
        logger.info(f"   - 闪词列表: {terms[:10]}{'...' if len(terms) > 10 else ''}")
    except Exception as exc:  # noqa: BLE001
        logger.error(f"❌ 智能笔记生成失败: {exc}")
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    return SmartNoteResponse(
        note_content=note_content,
        terms=terms,
        input_chars=len(payload.user_input),
    )


@app.post("/notes/create", response_model=CreateNoteResponse)
def create_note(
    payload: CreateNoteRequest,
    cur = Depends(get_db_cursor)
) -> CreateNoteResponse:
    """
    创建笔记并保存到数据库（纯 SQL 方式）。
    
    - 调用 AI 生成智能笔记和闪词列表
    - 使用 SQL INSERT 保存笔记到数据库
    - 使用 SQL INSERT 保存闪词列表到数据库
    """
    logger.info(f"📝 开始创建笔记，输入长度: {len(payload.user_input)} 字符")
    
    try:
        # 获取默认用户ID
        user_id = get_default_user_id()
        
        # 生成智能笔记和闪词
        note_content, terms = generate_smart_note(
            payload.user_input,
            max_terms=payload.max_terms
        )
        
        # 从Markdown内容中提取标题（取第一行，移除#号）
        title = "智能笔记"
        for line in note_content.split('\n'):
            line = line.strip()
            if line:
                # 移除Markdown标题符号
                title = line.replace('#', '').strip()
                if title:
                    # 限制标题长度
                    if len(title) > 50:
                        title = title[:50] + "..."
                    break
        
        # 使用 SQL INSERT 创建笔记
        insert_note_sql = """
            INSERT INTO notes (user_id, title, content, markdown_content, created_at, updated_at)
            VALUES (%s, %s, %s, %s, NOW(), NOW())
            RETURNING id
        """
        cur.execute(insert_note_sql, (user_id, title, payload.user_input, note_content))
        result = cur.fetchone()
        logger.info(f"🔍 INSERT 执行结果: {result}, 类型: {type(result)}")
        
        if not result:
            raise ValueError("插入笔记失败，未返回笔记ID")
        
        # RealDictRow 支持字典方式访问
        note_id = result['id']
        
        if not note_id:
            raise ValueError(f"插入笔记失败，返回的ID无效: {result}")
        
        logger.info(f"✅ 获取到笔记ID: {note_id}")
        
        # 使用 SQL INSERT 批量创建闪词卡片
        if terms:
            # 注意：数据库枚举值是大写，需要转换为大写
            insert_flashcard_sql = """
                INSERT INTO flash_cards (note_id, term, status, review_count, created_at, updated_at)
                VALUES (%s, %s, %s::card_status, 0, NOW(), NOW())
            """
            # 使用大写的枚举值
            flashcard_data = [(note_id, term, 'NOT_STARTED') for term in terms]
            cur.executemany(insert_flashcard_sql, flashcard_data)
            affected_rows = cur.rowcount
            logger.info(f"✅ 插入 {len(flashcard_data)} 个闪词卡片，影响行数: {affected_rows}")
            
            # 验证插入是否成功
            if affected_rows != len(flashcard_data):
                logger.warning(f"⚠️ 插入闪词数量不匹配: 期望 {len(flashcard_data)}, 实际 {affected_rows}")
        
        logger.info(f"✅ 笔记创建成功！")
        logger.info(f"   - 笔记ID: {note_id}")
        logger.info(f"   - 标题: {title}")
        logger.info(f"   - 闪词数量: {len(terms)}")
        
        return CreateNoteResponse(
            note_id=note_id,
            title=title,
            flash_card_count=len(terms),
        )
        
    except Exception as exc:  # noqa: BLE001
        error_msg = str(exc)
        logger.error(f"❌ 创建笔记失败: {error_msg}", exc_info=True)
        # 如果错误信息是 "0"，可能是 rowcount 返回的，需要更详细的错误信息
        if error_msg == "0":
            logger.error("⚠️ 错误信息是 '0'，可能是数据库操作返回的行数为 0")
            error_msg = "数据库操作失败，未插入任何记录"
        raise HTTPException(status_code=500, detail=error_msg) from exc


@app.post("/notes/create-from-url", response_model=CreateNoteResponse)
def create_note_from_url(
    payload: CreateNoteFromUrlRequest,
    cur = Depends(get_db_cursor)
) -> CreateNoteResponse:
    """
    从网页URL创建笔记并保存到数据库。
    
    - 抓取网页内容并提取可见文本
    - 调用 AI 生成智能笔记和闪词列表
    - 使用 SQL INSERT 保存笔记到数据库
    """
    logger.info(f"🌐 开始从URL创建笔记: {payload.url}")
    
    try:
        # 1. 抓取网页并提取文本
        text, error = scrape_website(payload.url, payload.max_text_length)
        
        if error:
            logger.error(f"❌ 网页抓取失败: {error}")
            raise HTTPException(status_code=400, detail=error)
        
        # 检查文本长度（与 web_scraper.py 中的检查保持一致）
        text_stripped = text.strip() if text else ""
        if not text or len(text_stripped) < 50:
            logger.warning(f"⚠️ 提取的文本太短: {len(text_stripped)} 字符")
            raise HTTPException(
                status_code=400,
                detail=f"无法从网页中提取有效文本（仅提取到 {len(text_stripped)} 字符），请检查URL是否正确或网页是否需要登录"
            )
        
        logger.info(f"✅ 网页文本提取成功，长度: {len(text)} 字符")
        
        # 2. 获取默认用户ID
        user_id = get_default_user_id()
        
        # 3. 生成智能笔记和闪词
        note_content, terms = generate_smart_note(
            text,
            max_terms=payload.max_terms
        )
        
        # 4. 从Markdown内容中提取标题
        title = "网页笔记"
        for line in note_content.split('\n'):
            line = line.strip()
            if line:
                title = line.replace('#', '').strip()
                if title:
                    if len(title) > 50:
                        title = title[:50] + "..."
                    break
        
        # 5. 使用 SQL INSERT 创建笔记
        insert_note_sql = """
            INSERT INTO notes (user_id, title, content, markdown_content, created_at, updated_at)
            VALUES (%s, %s, %s, %s, NOW(), NOW())
            RETURNING id
        """
        cur.execute(insert_note_sql, (user_id, title, text, note_content))
        result = cur.fetchone()
        
        if not result:
            raise ValueError("插入笔记失败，未返回笔记ID")
        
        note_id = result['id']
        logger.info(f"✅ 获取到笔记ID: {note_id}")
        
        # 6. 使用 SQL INSERT 批量创建闪词卡片
        if terms:
            insert_flashcard_sql = """
                INSERT INTO flash_cards (note_id, term, status, review_count, created_at, updated_at)
                VALUES (%s, %s, %s::card_status, 0, NOW(), NOW())
            """
            flashcard_data = [(note_id, term, 'NOT_STARTED') for term in terms]
            cur.executemany(insert_flashcard_sql, flashcard_data)
            affected_rows = cur.rowcount
            logger.info(f"✅ 插入 {len(flashcard_data)} 个闪词卡片，影响行数: {affected_rows}")
            
            if affected_rows != len(flashcard_data):
                logger.warning(f"⚠️ 插入闪词数量不匹配: 期望 {len(flashcard_data)}, 实际 {affected_rows}")
        
        logger.info(f"✅ 从URL创建笔记成功！")
        logger.info(f"   - 笔记ID: {note_id}")
        logger.info(f"   - 标题: {title}")
        logger.info(f"   - 闪词数量: {len(terms)}")
        
        return CreateNoteResponse(
            note_id=note_id,
            title=title,
            flash_card_count=len(terms),
        )
        
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        error_msg = str(exc)
        logger.error(f"❌ 从URL创建笔记失败: {error_msg}", exc_info=True)
        if error_msg == "0":
            error_msg = "数据库操作失败，未插入任何记录"
        raise HTTPException(status_code=500, detail=error_msg) from exc


@app.get("/notes/list", response_model=NotesListResponse)
def list_notes(
    cur = Depends(get_db_cursor),
    skip: int = Query(0, ge=0, description="跳过数量"),
    limit: int = Query(100, ge=1, le=100, description="返回数量")
) -> NotesListResponse:
    """
    获取笔记列表（纯 SQL 方式）。
    """
    try:
        user_id = get_default_user_id()
        
        # 查询笔记列表（使用 SQL）
        query_notes_sql = """
            SELECT 
                n.id,
                n.title,
                n.created_at,
                COUNT(fc.id) as flash_card_count,
                COUNT(CASE WHEN fc.status = 'MASTERED' THEN 1 END) as mastered_count,
                COUNT(CASE WHEN fc.status = 'NEEDS_REVIEW' THEN 1 END) as needs_review_count,
                COUNT(CASE WHEN fc.status = 'NEEDS_IMPROVE' THEN 1 END) as needs_improve_count,
                COUNT(CASE WHEN fc.status = 'NOT_MASTERED' THEN 1 END) as not_mastered_count
            FROM notes n
            LEFT JOIN flash_cards fc ON n.id = fc.note_id
            WHERE n.user_id = %s
            GROUP BY n.id, n.title, n.created_at
            ORDER BY n.created_at DESC
            LIMIT %s OFFSET %s
        """
        cur.execute(query_notes_sql, (user_id, limit, skip))
        notes = cur.fetchall()
        
        # 统计总数
        count_sql = "SELECT COUNT(*) as count FROM notes WHERE user_id = %s"
        cur.execute(count_sql, (user_id,))
        total_row = cur.fetchone()
        total = total_row['count']
        
        # 构建响应
        note_items = []
        for note in notes:
            note_items.append(NoteListItem(
                id=note['id'],
                title=note['title'],
                created_at=note['created_at'].isoformat() if note['created_at'] else "",
                flash_card_count=note['flash_card_count'] or 0,
                mastered_count=note['mastered_count'] or 0,
                needs_review_count=note['needs_review_count'] or 0,
                needs_improve_count=note['needs_improve_count'] or 0,
                not_mastered_count=note['not_mastered_count'] or 0,
            ))
        
        logger.info(f"📋 获取笔记列表: 总数={total}, 返回={len(note_items)}")
        
        return NotesListResponse(
            notes=note_items,
            total=total,
        )
        
    except Exception as exc:  # noqa: BLE001
        logger.error(f"❌ 获取笔记列表失败: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


class NoteDetailResponse(BaseModel):
    """笔记详情响应"""
    id: int
    title: str
    content: str | None
    markdown_content: str | None
    created_at: str
    updated_at: str
    default_role: str | None = Field(default=None, description="笔记的默认学习角色")
    flash_cards: List[dict] = Field(..., description="闪词列表")


# ========== 学习相关模型 ==========

class LearningRole(BaseModel):
    """学习角色"""
    id: str
    name: str
    description: str


class RolesResponse(BaseModel):
    """角色列表响应"""
    roles: List[LearningRole]


class EvaluateRequest(BaseModel):
    """评估请求"""
    card_id: int = Field(..., description="闪词卡片ID")
    note_id: int = Field(..., description="笔记ID")
    selected_role: str = Field(..., min_length=1, description="选择的角色ID")
    user_explanation: str = Field(..., min_length=1, description="用户的解释")


class EvaluateResponse(BaseModel):
    """评估响应"""
    score: int = Field(..., ge=0, le=100, description="评分 0-100")
    status: str = Field(..., description="学习状态")
    feedback: str = Field(..., description="AI反馈（简短版）")
    highlights: List[str] = Field(default=[], description="做得好的点")
    suggestions: List[str] = Field(default=[], description="改进建议")
    learning_record_id: int = Field(..., description="学习记录ID")


class UpdateCardStatusRequest(BaseModel):
    """更新卡片状态请求"""
    status: str = Field(..., description="新状态")


class CardStatusResponse(BaseModel):
    """卡片状态响应"""
    id: int
    term: str
    status: str
    review_count: int


class SetNoteDefaultRoleRequest(BaseModel):
    """设置笔记默认角色请求"""
    role_id: str = Field(..., min_length=1, description="角色ID")


# ==================== 学习中心 / 首页统计模型 ====================

class StudyCenterStatisticsResponse(BaseModel):
    """学习中心统计数据响应"""
    today_review_count: int = Field(default=0, description="今日复习数量")
    mastered_count: int = Field(default=0, description="已掌握数量")
    needs_review_count: int = Field(default=0, description="需巩固数量（70-89分）")
    needs_improve_count: int = Field(default=0, description="需改进数量")
    not_mastered_count: int = Field(default=0, description="未掌握数量")
    total_cards_count: int = Field(default=0, description="全部词条数量")


class DailyStudyCount(BaseModel):
    """按天统计的学习次数"""
    date: str = Field(..., description="日期，格式YYYY-MM-DD")
    count: int = Field(default=0, description="当天学习次数")


class HomeStatisticsResponse(BaseModel):
    """首页学习统计数据响应"""
    today_review_count: int = Field(default=0, description="今日复习数量")
    mastered_count: int = Field(default=0, description="已掌握数量")
    needs_review_count: int = Field(default=0, description="需巩固数量（70-89分）")
    needs_improve_count: int = Field(default=0, description="需改进数量")
    not_mastered_count: int = Field(default=0, description="未掌握数量")
    total_cards_count: int = Field(default=0, description="全部词条数量")

    streak_days: int = Field(default=0, description="连续学习天数（从今天向前连续有学习记录）")
    active_days_7d: int = Field(default=0, description="近7天活跃天数（有学习记录的天数）")
    week_completed: int = Field(default=0, description="本周完成的学习次数（学习记录数）")
    week_target: int = Field(default=30, description="本周学习目标次数")
    trend_7d: List[DailyStudyCount] = Field(default_factory=list, description="近7天学习趋势")


class FlashCardListItem(BaseModel):
    """闪词卡片列表项"""
    id: int
    term: str
    status: str
    note_id: int
    note_title: str = Field(default="", description="笔记标题")
    review_count: int = Field(default=0, description="复习次数")
    last_studied_at: str | None = Field(default=None, description="最后学习时间")
    best_score: int | None = Field(default=None, description="最高分")
    attempt_count: int = Field(default=0, description="学习次数")


class FlashCardListResponse(BaseModel):
    """闪词卡片列表响应"""
    cards: List[FlashCardListItem] = Field(default_factory=list, description="词条列表")
    total: int = Field(default=0, description="总数")


class CardsByNoteItem(BaseModel):
    """按笔记分类的词条统计项"""
    note_id: int
    note_title: str
    total_count: int = Field(default=0, description="总词条数")
    mastered_count: int = Field(default=0, description="已掌握数量")
    needs_review_count: int = Field(default=0, description="需巩固数量（70-89分）")
    needs_improve_count: int = Field(default=0, description="需改进数量")
    not_mastered_count: int = Field(default=0, description="未掌握数量")


class CardsByNoteResponse(BaseModel):
    """按笔记分类的词条列表响应"""
    notes: List[CardsByNoteItem] = Field(default_factory=list, description="笔记列表")
    total: int = Field(default=0, description="总数")


@app.get("/notes/{note_id}", response_model=NoteDetailResponse)
def get_note_detail(
    note_id: int,
    cur = Depends(get_db_cursor)
) -> NoteDetailResponse:
    """
    获取笔记详情（纯 SQL 方式）。
    """
    try:
        user_id = get_default_user_id()
        
        # 查询笔记详情（使用 SQL）
        query_note_sql = """
            SELECT id, title, content, markdown_content, created_at, updated_at, default_role
            FROM notes
            WHERE id = %s AND user_id = %s
        """
        cur.execute(query_note_sql, (note_id, user_id))
        note = cur.fetchone()
        
        if not note:
            raise HTTPException(status_code=404, detail="笔记不存在")
        
        # 查询闪词列表（使用 SQL）
        query_flashcards_sql = """
            SELECT id, term, status, review_count
            FROM flash_cards
            WHERE note_id = %s
            ORDER BY id
        """
        cur.execute(query_flashcards_sql, (note_id,))
        flashcard_rows = cur.fetchall()
        
        # 构建闪词列表
        flash_cards = []
        for fc in flashcard_rows:
            flash_cards.append({
                "id": fc['id'],
                "term": fc['term'],
                "status": fc['status'],
                "review_count": fc['review_count'],
            })
        
        # 处理时间格式
        created_at = note['created_at']
        if hasattr(created_at, 'isoformat'):
            created_at_str = created_at.isoformat()
        else:
            created_at_str = str(created_at) if created_at else ""
        
        updated_at = note['updated_at']
        if hasattr(updated_at, 'isoformat'):
            updated_at_str = updated_at.isoformat()
        else:
            updated_at_str = str(updated_at) if updated_at else ""
        
        return NoteDetailResponse(
            id=note['id'],
            title=note['title'],
            content=note['content'],
            markdown_content=note['markdown_content'],
            created_at=created_at_str,
            updated_at=updated_at_str,
            default_role=note.get('default_role'),
            flash_cards=flash_cards,
        )
        
    except HTTPException:
        raise
    except Exception as exc:  # noqa: BLE001
        logger.error(f"❌ 获取笔记详情失败: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


# ========== 学习相关 API ==========

@app.get("/learning/roles", response_model=RolesResponse)
def get_learning_roles() -> RolesResponse:
    """
    获取可用的学习角色列表
    """
    roles = get_available_roles()
    return RolesResponse(
        roles=[LearningRole(**role) for role in roles]
    )


@app.post("/learning/evaluate", response_model=EvaluateResponse)
def evaluate_user_explanation(
    payload: EvaluateRequest,
    cur = Depends(get_db_cursor)
) -> EvaluateResponse:
    """
    评估用户对词条的解释，并保存学习记录。
    
    流程：
    1. 获取闪词卡片信息
    2. 调用 AI 评估用户的解释
    3. 保存学习记录
    4. 更新闪词卡片状态
    """
    import json
    
    logger.info(f"📝 开始评估，卡片ID: {payload.card_id}, 角色: {payload.selected_role}")
    
    try:
        # 1. 获取闪词卡片信息
        query_card_sql = """
            SELECT id, note_id, term, status, review_count
            FROM flash_cards
            WHERE id = %s
        """
        cur.execute(query_card_sql, (payload.card_id,))
        card = cur.fetchone()
        
        if not card:
            raise HTTPException(status_code=404, detail="闪词卡片不存在")
        
        term = card['term']
        current_review_count = card['review_count'] or 0
        
        # 2. 获取角色名称（用于AI评估）
        roles = get_available_roles()
        role_name = payload.selected_role
        for role in roles:
            if role['id'] == payload.selected_role:
                role_name = role['name']
                break
        
        # 3. 调用 AI 评估
        score, status, ai_feedback = evaluate_explanation(
            term=term,
            user_explanation=payload.user_explanation,
            selected_role=role_name,
        )
        
        logger.info(f"✅ AI评估完成: 分数={score}, 状态={status}")
        
        # 4. 保存学习记录
        attempt_number = current_review_count + 1
        insert_record_sql = """
            INSERT INTO learning_records 
            (card_id, note_id, selected_role, user_explanation, score, ai_feedback, status, attempt_number, attempted_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, NOW())
            RETURNING id
        """
        cur.execute(insert_record_sql, (
            payload.card_id,
            payload.note_id,
            role_name,  # 保持原有逻辑，存储角色名称（前端会兼容处理）
            payload.user_explanation,
            score,
            ai_feedback,
            status.upper(),  # 数据库枚举是大写
            attempt_number,
        ))
        record_result = cur.fetchone()
        learning_record_id = record_result['id']
        
        logger.info(f"✅ 学习记录已保存，ID: {learning_record_id}")
        
        # 5. 更新闪词卡片状态、复习次数和最后复习时间
        # 根据状态设置mastered_at（如果达到已掌握状态）
        mastered_at_value = None
        if status.upper() == 'MASTERED':
            mastered_at_value = 'NOW()'
        
        if mastered_at_value:
            update_card_sql = """
                UPDATE flash_cards
                SET status = %s::card_status, 
                    review_count = %s, 
                    last_reviewed_at = NOW(),
                    mastered_at = NOW(),
                    updated_at = NOW()
                WHERE id = %s
            """
        else:
            update_card_sql = """
                UPDATE flash_cards
                SET status = %s::card_status, 
                    review_count = %s, 
                    last_reviewed_at = NOW(),
                    updated_at = NOW()
                WHERE id = %s
            """
        cur.execute(update_card_sql, (status.upper(), attempt_number, payload.card_id))
        
        logger.info(f"✅ 卡片状态已更新: {status.upper()}")
        
        # 6. 解析 AI 反馈并构建响应
        try:
            feedback_data = json.loads(ai_feedback)
            feedback_text = feedback_data.get('feedback', '感谢你的解释！')
            highlights = feedback_data.get('highlights', [])
            suggestions = feedback_data.get('suggestions', [])
        except (json.JSONDecodeError, TypeError):
            feedback_text = "感谢你的解释！继续加油！"
            highlights = []
            suggestions = []
        
        return EvaluateResponse(
            score=score,
            status=status,
            feedback=feedback_text,
            highlights=highlights,
            suggestions=suggestions,
            learning_record_id=learning_record_id,
        )
        
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"❌ 评估失败: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.patch("/flash-cards/{card_id}/status", response_model=CardStatusResponse)
def update_card_status(
    card_id: int,
    payload: UpdateCardStatusRequest,
    cur = Depends(get_db_cursor)
) -> CardStatusResponse:
    """
    直接更新闪词卡片状态（如标记为已掌握）
    """
    logger.info(f"📝 更新卡片状态，ID: {card_id}, 新状态: {payload.status}")
    
    try:
        # 验证状态值
        valid_statuses = ['NOT_STARTED', 'NEEDS_REVIEW', 'NEEDS_IMPROVE', 'NOT_MASTERED', 'MASTERED']
        status_upper = payload.status.upper()
        if status_upper not in valid_statuses:
            raise HTTPException(status_code=400, detail=f"无效的状态值，有效值为: {valid_statuses}")
        
        # 更新卡片状态
        # 如果状态变为需要复习的状态，更新last_reviewed_at
        # 如果状态变为已掌握，同时更新mastered_at
        if status_upper == 'MASTERED':
            update_sql = """
                UPDATE flash_cards
                SET status = %s::card_status, 
                    last_reviewed_at = NOW(),
                    mastered_at = NOW(),
                    updated_at = NOW()
                WHERE id = %s
                RETURNING id, term, status, review_count
            """
        elif status_upper in ('NEEDS_REVIEW', 'NEEDS_IMPROVE', 'NOT_MASTERED'):
            # 这些状态表示需要复习，更新last_reviewed_at
            update_sql = """
                UPDATE flash_cards
                SET status = %s::card_status, 
                    last_reviewed_at = NOW(),
                    updated_at = NOW()
                WHERE id = %s
                RETURNING id, term, status, review_count
            """
        else:
            # NOT_STARTED 等状态不需要更新last_reviewed_at
            update_sql = """
                UPDATE flash_cards
                SET status = %s::card_status, updated_at = NOW()
                WHERE id = %s
                RETURNING id, term, status, review_count
            """
        cur.execute(update_sql, (status_upper, card_id))
        result = cur.fetchone()
        
        if not result:
            raise HTTPException(status_code=404, detail="闪词卡片不存在")
        
        logger.info(f"✅ 卡片状态更新成功: {result['status']}")
        
        return CardStatusResponse(
            id=result['id'],
            term=result['term'],
            status=result['status'],
            review_count=result['review_count'] or 0,
        )
        
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"❌ 更新卡片状态失败: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.get("/flash-cards/{card_id}", response_model=dict)
def get_flash_card_detail(
    card_id: int,
    cur = Depends(get_db_cursor)
) -> dict:
    """
    获取闪词卡片详情（包含学习历史）
    """
    try:
        # 获取卡片信息
        query_card_sql = """
            SELECT id, note_id, term, status, review_count, created_at, updated_at
            FROM flash_cards
            WHERE id = %s
        """
        cur.execute(query_card_sql, (card_id,))
        card = cur.fetchone()
        
        if not card:
            raise HTTPException(status_code=404, detail="闪词卡片不存在")
        
        # 获取学习历史
        query_history_sql = """
            SELECT id, selected_role, user_explanation, score, ai_feedback, status, attempt_number, attempted_at
            FROM learning_records
            WHERE card_id = %s
            ORDER BY attempted_at DESC
            LIMIT 10
        """
        cur.execute(query_history_sql, (card_id,))
        history_rows = cur.fetchall()
        
        # 构建学习历史
        learning_history = []
        for record in history_rows:
            learning_history.append({
                "id": record['id'],
                "selected_role": record['selected_role'],
                "user_explanation": record['user_explanation'],
                "score": record['score'],
                "ai_feedback": record['ai_feedback'],
                "status": record['status'],
                "attempt_number": record['attempt_number'],
                "attempted_at": record['attempted_at'].isoformat() if record['attempted_at'] else "",
            })
        
        return {
            "id": card['id'],
            "note_id": card['note_id'],
            "term": card['term'],
            "status": card['status'],
            "review_count": card['review_count'] or 0,
            "created_at": card['created_at'].isoformat() if card['created_at'] else "",
            "updated_at": card['updated_at'].isoformat() if card['updated_at'] else "",
            "learning_history": learning_history,
        }
        
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"❌ 获取卡片详情失败: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.patch("/notes/{note_id}/default-role")
def set_note_default_role(
    note_id: int,
    payload: SetNoteDefaultRoleRequest,
    cur = Depends(get_db_cursor)
) -> dict:
    """
    设置笔记的默认学习角色
    """
    logger.info(f"📝 设置笔记默认角色，笔记ID: {note_id}, 角色ID: {payload.role_id}")
    
    try:
        user_id = get_default_user_id()
        
        # 验证笔记是否存在且属于当前用户
        check_note_sql = """
            SELECT id FROM notes
            WHERE id = %s AND user_id = %s
        """
        cur.execute(check_note_sql, (note_id, user_id))
        note = cur.fetchone()
        
        if not note:
            raise HTTPException(status_code=404, detail="笔记不存在")
        
        # 获取角色名称
        roles = get_available_roles()
        role_name = payload.role_id
        for role in roles:
            if role['id'] == payload.role_id:
                role_name = role['name']
                break
        
        # 更新笔记的默认角色
        update_sql = """
            UPDATE notes
            SET default_role = %s, updated_at = NOW()
            WHERE id = %s
        """
        cur.execute(update_sql, (role_name, note_id))
        
        logger.info(f"✅ 笔记默认角色已设置: {role_name}")
        
        return {
            "note_id": note_id,
            "default_role": role_name,
            "role_id": payload.role_id,
        }
        
    except HTTPException:
        raise
    except Exception as exc:
        logger.error(f"❌ 设置笔记默认角色失败: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


# ==================== 学习中心相关接口 ====================

@app.get("/study-center/statistics", response_model=StudyCenterStatisticsResponse)
def get_study_center_statistics(
    cur = Depends(get_db_cursor)
) -> StudyCenterStatisticsResponse:
    """
    获取学习中心统计数据
    """
    try:
        user_id = get_default_user_id()
        
        # 统计各状态词条数量
        stats_sql = """
            SELECT 
                COUNT(CASE WHEN fc.status = 'MASTERED' THEN 1 END) as mastered_count,
                COUNT(CASE WHEN fc.status = 'NEEDS_REVIEW' THEN 1 END) as needs_review_count,
                COUNT(CASE WHEN fc.status = 'NEEDS_IMPROVE' THEN 1 END) as needs_improve_count,
                COUNT(CASE WHEN fc.status = 'NOT_MASTERED' THEN 1 END) as not_mastered_count,
                COUNT(fc.id) as total_cards_count,
                COUNT(CASE 
                    WHEN (
                        (fc.status = 'NOT_MASTERED' AND (
                            fc.last_reviewed_at IS NULL OR 
                            fc.last_reviewed_at + INTERVAL '4 hours' <= NOW()
                        ))
                        OR
                        (fc.status = 'NEEDS_IMPROVE' AND (
                            fc.last_reviewed_at IS NULL OR 
                            fc.last_reviewed_at + INTERVAL '3 days' <= NOW()
                        ))
                        OR
                        (fc.status = 'NEEDS_REVIEW' AND (
                            fc.last_reviewed_at IS NULL OR 
                            fc.last_reviewed_at + INTERVAL '1 day' <= NOW()
                        ))
                        OR
                        (fc.status = 'MASTERED' AND (
                            fc.last_reviewed_at IS NULL OR 
                            fc.last_reviewed_at + INTERVAL '7 days' <= NOW()
                        ))
                    )
                    THEN 1 
                END) as today_review_count
            FROM flash_cards fc
            INNER JOIN notes n ON fc.note_id = n.id
            WHERE n.user_id = %s
        """
        cur.execute(stats_sql, (user_id,))
        stats = cur.fetchone()
        
        return StudyCenterStatisticsResponse(
            today_review_count=stats['today_review_count'] or 0,
            mastered_count=stats['mastered_count'] or 0,
            needs_review_count=stats['needs_review_count'] or 0,
            needs_improve_count=stats['needs_improve_count'] or 0,
            not_mastered_count=stats['not_mastered_count'] or 0,
            total_cards_count=stats['total_cards_count'] or 0,
        )
        
    except Exception as exc:
        logger.error(f"❌ 获取学习中心统计数据失败: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.get("/home/statistics", response_model=HomeStatisticsResponse)
def get_home_statistics(
    cur = Depends(get_db_cursor)
) -> HomeStatisticsResponse:
    """
    获取首页学习统计数据：
    - 基础状态分布（沿用学习中心统计）
    - 连续学习天数
    - 近7天活跃天数
    - 本周完成次数 + 目标
    - 近7天趋势
    """
    try:
        user_id = get_default_user_id()

        # 基础状态统计
        stats_sql = """
            SELECT 
                COUNT(CASE WHEN fc.status = 'MASTERED' THEN 1 END) as mastered_count,
                COUNT(CASE WHEN fc.status = 'NEEDS_REVIEW' THEN 1 END) as needs_review_count,
                COUNT(CASE WHEN fc.status = 'NEEDS_IMPROVE' THEN 1 END) as needs_improve_count,
                COUNT(CASE WHEN fc.status = 'NOT_MASTERED' THEN 1 END) as not_mastered_count,
                COUNT(fc.id) as total_cards_count,
                COUNT(CASE 
                    WHEN (
                        (fc.status = 'NOT_MASTERED' AND (
                            fc.last_reviewed_at IS NULL OR 
                            fc.last_reviewed_at + INTERVAL '4 hours' <= NOW()
                        ))
                        OR
                        (fc.status = 'NEEDS_IMPROVE' AND (
                            fc.last_reviewed_at IS NULL OR 
                            fc.last_reviewed_at + INTERVAL '3 days' <= NOW()
                        ))
                        OR
                        (fc.status = 'NEEDS_REVIEW' AND (
                            fc.last_reviewed_at IS NULL OR 
                            fc.last_reviewed_at + INTERVAL '1 day' <= NOW()
                        ))
                        OR
                        (fc.status = 'MASTERED' AND (
                            fc.last_reviewed_at IS NULL OR 
                            fc.last_reviewed_at + INTERVAL '7 days' <= NOW()
                        ))
                    )
                    THEN 1 
                END) as today_review_count
            FROM flash_cards fc
            INNER JOIN notes n ON fc.note_id = n.id
            WHERE n.user_id = %s
        """
        cur.execute(stats_sql, (user_id,))
        stats = cur.fetchone()

        mastered_count = stats['mastered_count'] or 0
        needs_review_count = stats['needs_review_count'] or 0
        needs_improve_count = stats['needs_improve_count'] or 0
        not_mastered_count = stats['not_mastered_count'] or 0
        total_cards_count = stats['total_cards_count'] or 0
        today_review_count = stats['today_review_count'] or 0

        # 近30天的学习记录（用于 streak / active / trend / 周进度）
        learning_sql = """
            SELECT 
                DATE(lr.attempted_at) AS day,
                COUNT(*) AS cnt
            FROM learning_records lr
            INNER JOIN notes n ON lr.note_id = n.id
            WHERE n.user_id = %s
                AND lr.attempted_at >= NOW() - INTERVAL '30 days'
            GROUP BY DATE(lr.attempted_at)
        """
        cur.execute(learning_sql, (user_id,))
        learning_rows = cur.fetchall()
        day_count_map = {row['day'].strftime("%Y-%m-%d"): row['cnt'] for row in learning_rows}

        # 近7天趋势（包含当天，补0）
        trend_7d = []
        for i in range(6, -1, -1):
            day = (datetime.utcnow().date() - timedelta(days=i))
            day_str = day.strftime("%Y-%m-%d")
            trend_7d.append(DailyStudyCount(date=day_str, count=day_count_map.get(day_str, 0)))

        # 近7天活跃天数
        active_days_7d = sum(1 for item in trend_7d if item.count > 0)

        # 连续学习天数（streak）：从今天起向前连续有学习记录的天数
        streak = 0
        current_day = datetime.utcnow().date()
        for i in range(0, 30):
            day = (current_day - timedelta(days=i)).strftime("%Y-%m-%d")
            if day_count_map.get(day, 0) > 0:
                streak += 1
            else:
                break

        # 本周进度：本周起始（周一）到现在的学习次数
        # week_start 使用 Monday 作为一周开始
        today = datetime.utcnow().date()
        week_start = today - timedelta(days=today.weekday())
        week_sql = """
            SELECT COUNT(*) AS cnt
            FROM learning_records lr
            INNER JOIN notes n ON lr.note_id = n.id
            WHERE n.user_id = %s
              AND lr.attempted_at >= %s
        """
        cur.execute(week_sql, (user_id, week_start))
        week_cnt_row = cur.fetchone()
        week_completed = week_cnt_row['cnt'] if week_cnt_row and week_cnt_row['cnt'] else 0

        # 周目标（简单固定值，可后续做用户配置）
        week_target = 30

        return HomeStatisticsResponse(
            today_review_count=today_review_count,
            mastered_count=mastered_count,
            needs_review_count=needs_review_count,
            needs_improve_count=needs_improve_count,
            not_mastered_count=not_mastered_count,
            total_cards_count=total_cards_count,
            streak_days=streak,
            active_days_7d=active_days_7d,
            week_completed=week_completed,
            week_target=week_target,
            trend_7d=trend_7d,
        )

    except Exception as exc:
        logger.error(f"❌ 获取首页统计数据失败: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.get("/study-center/today-review", response_model=FlashCardListResponse)
def get_today_review_cards(
    cur = Depends(get_db_cursor),
    skip: int = Query(0, ge=0, description="跳过数量"),
    limit: int = Query(100, ge=1, le=100, description="返回数量")
) -> FlashCardListResponse:
    """
    获取今日复习词条列表
    """
    try:
        user_id = get_default_user_id()
        
        # 查询今日需要复习的词条
        # 根据状态和复习间隔判断：
        # - NOT_MASTERED: 4小时后（即 last_reviewed_at + 4小时 <= NOW()）
        # - NEEDS_IMPROVE: 3天后（即 last_reviewed_at + 3天 <= NOW()）
        # - NEEDS_REVIEW（需巩固）: 1天后（即 last_reviewed_at + 1天 <= NOW()）
        # - MASTERED: 7天后（即 last_reviewed_at + 7天 <= NOW()）
        query_sql = """
            SELECT 
                fc.id,
                fc.term,
                fc.status,
                fc.note_id,
                n.title as note_title,
                fc.review_count,
                MAX(lr.attempted_at) as last_studied_at,
                MAX(lr.score) as best_score,
                COUNT(lr.id) as attempt_count,
                fc.last_reviewed_at
            FROM flash_cards fc
            INNER JOIN notes n ON fc.note_id = n.id
            LEFT JOIN learning_records lr ON fc.id = lr.card_id
            WHERE n.user_id = %s
                AND (
                    -- 未掌握：4小时后需要复习
                    (fc.status = 'NOT_MASTERED' AND (
                        fc.last_reviewed_at IS NULL OR 
                        fc.last_reviewed_at + INTERVAL '4 hours' <= NOW()
                    ))
                    OR
                    -- 需改进：3天后需要复习
                    (fc.status = 'NEEDS_IMPROVE' AND (
                        fc.last_reviewed_at IS NULL OR 
                        fc.last_reviewed_at + INTERVAL '3 days' <= NOW()
                    ))
                    OR
                    -- 需巩固：1天后需要复习
                    (fc.status = 'NEEDS_REVIEW' AND (
                        fc.last_reviewed_at IS NULL OR 
                        fc.last_reviewed_at + INTERVAL '1 day' <= NOW()
                    ))
                    OR
                    -- 已掌握：7天后需要复习（长期巩固）
                    (fc.status = 'MASTERED' AND (
                        fc.last_reviewed_at IS NULL OR 
                        fc.last_reviewed_at + INTERVAL '7 days' <= NOW()
                    ))
                )
            GROUP BY fc.id, fc.term, fc.status, fc.note_id, n.title, fc.review_count, fc.last_reviewed_at
            ORDER BY 
                CASE fc.status
                    WHEN 'NOT_MASTERED' THEN 1  -- 未掌握优先
                    WHEN 'NEEDS_IMPROVE' THEN 2
                    WHEN 'NEEDS_REVIEW' THEN 3
                    WHEN 'MASTERED' THEN 4
                    ELSE 5
                END,
                fc.last_reviewed_at ASC NULLS FIRST,
                fc.id ASC
            LIMIT %s OFFSET %s
        """
        cur.execute(query_sql, (user_id, limit, skip))
        cards = cur.fetchall()
        
        # 统计总数（使用相同的复习间隔逻辑）
        count_sql = """
            SELECT COUNT(DISTINCT fc.id) as count
            FROM flash_cards fc
            INNER JOIN notes n ON fc.note_id = n.id
            WHERE n.user_id = %s
                AND (
                    (fc.status = 'NOT_MASTERED' AND (
                        fc.last_reviewed_at IS NULL OR 
                        fc.last_reviewed_at + INTERVAL '4 hours' <= NOW()
                    ))
                    OR
                    (fc.status = 'NEEDS_IMPROVE' AND (
                        fc.last_reviewed_at IS NULL OR 
                        fc.last_reviewed_at + INTERVAL '3 days' <= NOW()
                    ))
                    OR
                    (fc.status = 'NEEDS_REVIEW' AND (
                        fc.last_reviewed_at IS NULL OR 
                        fc.last_reviewed_at + INTERVAL '1 day' <= NOW()
                    ))
                    OR
                    (fc.status = 'MASTERED' AND (
                        fc.last_reviewed_at IS NULL OR 
                        fc.last_reviewed_at + INTERVAL '7 days' <= NOW()
                    ))
                )
        """
        cur.execute(count_sql, (user_id,))
        total_row = cur.fetchone()
        total = total_row['count'] or 0
        
        # 构建响应
        card_items = []
        for card in cards:
            last_studied_at = card['last_studied_at']
            last_studied_at_str = None
            if last_studied_at:
                if hasattr(last_studied_at, 'isoformat'):
                    last_studied_at_str = last_studied_at.isoformat()
                else:
                    last_studied_at_str = str(last_studied_at)
            
            card_items.append(FlashCardListItem(
                id=card['id'],
                term=card['term'],
                status=card['status'],
                note_id=card['note_id'],
                note_title=card['note_title'] or '',
                review_count=card['review_count'] or 0,
                last_studied_at=last_studied_at_str,
                best_score=card['best_score'],
                attempt_count=card['attempt_count'] or 0,
            ))
        
        return FlashCardListResponse(cards=card_items, total=total)
        
    except Exception as exc:
        logger.error(f"❌ 获取今日复习词条列表失败: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.get("/study-center/weak-cards", response_model=FlashCardListResponse)
def get_weak_cards(
    cur = Depends(get_db_cursor),
    skip: int = Query(0, ge=0, description="跳过数量"),
    limit: int = Query(100, ge=1, le=100, description="返回数量"),
    status: str | None = Query(None, description="状态筛选：NEEDS_REVIEW（需巩固）, NEEDS_IMPROVE, NOT_MASTERED")
) -> FlashCardListResponse:
    """
    获取薄弱词条列表（需巩固、需改进、未掌握）
    """
    try:
        user_id = get_default_user_id()
        
        # 构建状态筛选条件（安全处理）
        valid_statuses = ['NEEDS_REVIEW', 'NEEDS_IMPROVE', 'NOT_MASTERED']
        if status and status.upper() in valid_statuses:
            status_list = [status.upper()]
        else:
            status_list = valid_statuses
        
        # 构建参数化查询
        placeholders = ','.join(['%s'] * len(status_list))
        query_sql = f"""
            SELECT 
                fc.id,
                fc.term,
                fc.status,
                fc.note_id,
                n.title as note_title,
                fc.review_count,
                MAX(lr.attempted_at) as last_studied_at,
                MAX(lr.score) as best_score,
                COUNT(lr.id) as attempt_count
            FROM flash_cards fc
            INNER JOIN notes n ON fc.note_id = n.id
            LEFT JOIN learning_records lr ON fc.id = lr.card_id
            WHERE n.user_id = %s
                AND fc.status IN ({placeholders})
            GROUP BY fc.id, fc.term, fc.status, fc.note_id, n.title, fc.review_count
            ORDER BY 
                CASE fc.status
                    WHEN 'NOT_MASTERED' THEN 1
                    WHEN 'NEEDS_IMPROVE' THEN 2
                    WHEN 'NEEDS_REVIEW' THEN 3
                    ELSE 4
                END,
                COALESCE(MAX(lr.score), 0) ASC,
                fc.id ASC
            LIMIT %s OFFSET %s
        """
        cur.execute(query_sql, (user_id, *status_list, limit, skip))
        cards = cur.fetchall()
        
        # 统计总数
        count_sql = f"""
            SELECT COUNT(DISTINCT fc.id) as count
            FROM flash_cards fc
            INNER JOIN notes n ON fc.note_id = n.id
            WHERE n.user_id = %s
                AND fc.status IN ({placeholders})
        """
        cur.execute(count_sql, (user_id, *status_list))
        total_row = cur.fetchone()
        total = total_row['count'] or 0
        
        # 构建响应
        card_items = []
        for card in cards:
            last_studied_at = card['last_studied_at']
            last_studied_at_str = None
            if last_studied_at:
                if hasattr(last_studied_at, 'isoformat'):
                    last_studied_at_str = last_studied_at.isoformat()
                else:
                    last_studied_at_str = str(last_studied_at)
            
            card_items.append(FlashCardListItem(
                id=card['id'],
                term=card['term'],
                status=card['status'],
                note_id=card['note_id'],
                note_title=card['note_title'] or '',
                review_count=card['review_count'] or 0,
                last_studied_at=last_studied_at_str,
                best_score=card['best_score'],
                attempt_count=card['attempt_count'] or 0,
            ))
        
        return FlashCardListResponse(cards=card_items, total=total)
        
    except Exception as exc:
        logger.error(f"❌ 获取薄弱词条列表失败: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.get("/study-center/mastered-cards", response_model=FlashCardListResponse)
def get_mastered_cards(
    cur = Depends(get_db_cursor),
    skip: int = Query(0, ge=0, description="跳过数量"),
    limit: int = Query(100, ge=1, le=100, description="返回数量")
) -> FlashCardListResponse:
    """
    获取已掌握词条列表
    """
    try:
        user_id = get_default_user_id()
        
        query_sql = """
            SELECT 
                fc.id,
                fc.term,
                fc.status,
                fc.note_id,
                n.title as note_title,
                fc.review_count,
                MAX(lr.attempted_at) as last_studied_at,
                MAX(lr.score) as best_score,
                COUNT(lr.id) as attempt_count
            FROM flash_cards fc
            INNER JOIN notes n ON fc.note_id = n.id
            LEFT JOIN learning_records lr ON fc.id = lr.card_id
            WHERE n.user_id = %s
                AND fc.status = 'MASTERED'
            GROUP BY fc.id, fc.term, fc.status, fc.note_id, n.title, fc.review_count
            ORDER BY fc.mastered_at DESC NULLS LAST, fc.id ASC
            LIMIT %s OFFSET %s
        """
        cur.execute(query_sql, (user_id, limit, skip))
        cards = cur.fetchall()
        
        # 统计总数
        count_sql = """
            SELECT COUNT(DISTINCT fc.id) as count
            FROM flash_cards fc
            INNER JOIN notes n ON fc.note_id = n.id
            WHERE n.user_id = %s
                AND fc.status = 'MASTERED'
        """
        cur.execute(count_sql, (user_id,))
        total_row = cur.fetchone()
        total = total_row['count'] or 0
        
        # 构建响应
        card_items = []
        for card in cards:
            last_studied_at = card['last_studied_at']
            last_studied_at_str = None
            if last_studied_at:
                if hasattr(last_studied_at, 'isoformat'):
                    last_studied_at_str = last_studied_at.isoformat()
                else:
                    last_studied_at_str = str(last_studied_at)
            
            card_items.append(FlashCardListItem(
                id=card['id'],
                term=card['term'],
                status=card['status'],
                note_id=card['note_id'],
                note_title=card['note_title'] or '',
                review_count=card['review_count'] or 0,
                last_studied_at=last_studied_at_str,
                best_score=card['best_score'],
                attempt_count=card['attempt_count'] or 0,
            ))
        
        return FlashCardListResponse(cards=card_items, total=total)
        
    except Exception as exc:
        logger.error(f"❌ 获取已掌握词条列表失败: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.get("/study-center/all-cards", response_model=FlashCardListResponse)
def get_all_cards(
    cur = Depends(get_db_cursor),
    skip: int = Query(0, ge=0, description="跳过数量"),
    limit: int = Query(100, ge=1, le=100, description="返回数量")
) -> FlashCardListResponse:
    """
    获取全部词条列表
    """
    try:
        user_id = get_default_user_id()
        
        query_sql = """
            SELECT 
                fc.id,
                fc.term,
                fc.status,
                fc.note_id,
                n.title as note_title,
                fc.review_count,
                MAX(lr.attempted_at) as last_studied_at,
                MAX(lr.score) as best_score,
                COUNT(lr.id) as attempt_count
            FROM flash_cards fc
            INNER JOIN notes n ON fc.note_id = n.id
            LEFT JOIN learning_records lr ON fc.id = lr.card_id
            WHERE n.user_id = %s
            GROUP BY fc.id, fc.term, fc.status, fc.note_id, n.title, fc.review_count
            ORDER BY fc.created_at DESC, fc.id ASC
            LIMIT %s OFFSET %s
        """
        cur.execute(query_sql, (user_id, limit, skip))
        cards = cur.fetchall()
        
        # 统计总数
        count_sql = """
            SELECT COUNT(DISTINCT fc.id) as count
            FROM flash_cards fc
            INNER JOIN notes n ON fc.note_id = n.id
            WHERE n.user_id = %s
        """
        cur.execute(count_sql, (user_id,))
        total_row = cur.fetchone()
        total = total_row['count'] or 0
        
        # 构建响应
        card_items = []
        for card in cards:
            last_studied_at = card['last_studied_at']
            last_studied_at_str = None
            if last_studied_at:
                if hasattr(last_studied_at, 'isoformat'):
                    last_studied_at_str = last_studied_at.isoformat()
                else:
                    last_studied_at_str = str(last_studied_at)
            
            card_items.append(FlashCardListItem(
                id=card['id'],
                term=card['term'],
                status=card['status'],
                note_id=card['note_id'],
                note_title=card['note_title'] or '',
                review_count=card['review_count'] or 0,
                last_studied_at=last_studied_at_str,
                best_score=card['best_score'],
                attempt_count=card['attempt_count'] or 0,
            ))
        
        return FlashCardListResponse(cards=card_items, total=total)
        
    except Exception as exc:
        logger.error(f"❌ 获取全部词条列表失败: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@app.get("/study-center/cards-by-note", response_model=CardsByNoteResponse)
def get_cards_by_note(
    cur = Depends(get_db_cursor),
    skip: int = Query(0, ge=0, description="跳过数量"),
    limit: int = Query(100, ge=1, le=100, description="返回数量")
) -> CardsByNoteResponse:
    """
    按笔记分类获取词条列表
    """
    try:
        user_id = get_default_user_id()
        
        query_sql = """
            SELECT 
                n.id as note_id,
                n.title as note_title,
                COUNT(fc.id) as total_count,
                COUNT(CASE WHEN fc.status = 'MASTERED' THEN 1 END) as mastered_count,
                COUNT(CASE WHEN fc.status = 'NEEDS_REVIEW' THEN 1 END) as needs_review_count,
                COUNT(CASE WHEN fc.status = 'NEEDS_IMPROVE' THEN 1 END) as needs_improve_count,
                COUNT(CASE WHEN fc.status = 'NOT_MASTERED' THEN 1 END) as not_mastered_count
            FROM notes n
            LEFT JOIN flash_cards fc ON n.id = fc.note_id
            WHERE n.user_id = %s
            GROUP BY n.id, n.title
            HAVING COUNT(fc.id) > 0
            ORDER BY n.created_at DESC
            LIMIT %s OFFSET %s
        """
        cur.execute(query_sql, (user_id, limit, skip))
        notes = cur.fetchall()
        
        # 统计总数
        count_sql = """
            SELECT COUNT(DISTINCT n.id) as count
            FROM notes n
            INNER JOIN flash_cards fc ON n.id = fc.note_id
            WHERE n.user_id = %s
        """
        cur.execute(count_sql, (user_id,))
        total_row = cur.fetchone()
        total = total_row['count'] or 0
        
        # 构建响应
        note_items = []
        for note in notes:
            note_items.append(CardsByNoteItem(
                note_id=note['note_id'],
                note_title=note['note_title'] or '',
                total_count=note['total_count'] or 0,
                mastered_count=note['mastered_count'] or 0,
                needs_review_count=note['needs_review_count'] or 0,
                needs_improve_count=note['needs_improve_count'] or 0,
                not_mastered_count=note['not_mastered_count'] or 0,
            ))
        
        return CardsByNoteResponse(notes=note_items, total=total)
        
    except Exception as exc:
        logger.error(f"❌ 按笔记分类获取词条列表失败: {exc}", exc_info=True)
        raise HTTPException(status_code=500, detail=str(exc)) from exc


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(app, host="0.0.0.0", port=8000)
