from typing import Annotated, List

from langchain_core.messages import BaseMessage, HumanMessage, SystemMessage
from langgraph.graph import END, StateGraph, add_messages
from typing_extensions import TypedDict

try:
    from .llm import get_default_llm
    from .system_prompt import simple_explanation_system_prompt
except ImportError:
    from llm import get_default_llm
    from system_prompt import simple_explanation_system_prompt


class AgentState(TypedDict):
    messages: Annotated[List[BaseMessage], add_messages]


def _build_graph():
    llm = get_default_llm()
    graph = StateGraph(AgentState)

    def call_model(state: AgentState):
        conversation = [SystemMessage(content=simple_explanation_system_prompt.strip())]
        conversation.extend(state["messages"])
        response = llm.invoke(conversation)
        return {"messages": [response]}

    graph.add_node("llm", call_model)
    graph.set_entry_point("llm")
    graph.add_edge("llm", END)
    return graph.compile()


_SIMPLE_EXPLAINER_GRAPH = _build_graph()


def run_simple_explainer_agent(user_text: str) -> str:
    """
    以 LangGraph 执行提示词,返回模型回复内容。
    """
    result = _SIMPLE_EXPLAINER_GRAPH.invoke({"messages": [HumanMessage(content=user_text)]})
    return result["messages"][-1].content


__all__ = ["run_simple_explainer_agent"]

