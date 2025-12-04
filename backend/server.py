from typing import List

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

try:
    from .curious_student_agent import run_curious_student_agent
    from .simple_explainer_agent import run_simple_explainer_agent
except ImportError:  # pragma: no cover
    from curious_student_agent import run_curious_student_agent
    from simple_explainer_agent import run_simple_explainer_agent


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
    ]
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
    key = category.lower()
    terms = TERMS_LIBRARY.get(key)
    if not terms:
        raise HTTPException(status_code=404, detail="暂不支持当前术语类别")
    return TermsResponse(category=key, terms=terms)


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(app, host="0.0.0.0", port=8000)
