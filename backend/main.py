try:
    from .curious_student_agent import run_curious_student_agent
    from .simple_explainer_agent import run_simple_explainer_agent
except ImportError:
    from curious_student_agent import run_curious_student_agent
    from simple_explainer_agent import run_simple_explainer_agent


def _read_user_text(choice: str) -> str:
    if choice == "2":
        print("请输入需要解释的JSON, 输入空行结束:")
        lines = []
        while True:
            try:
                line = input()
            except EOFError:
                break
            if not line.strip() and lines:
                break
            lines.append(line)
        return "\n".join(lines).strip()
    return input("请输入你的问题或词汇描述: ").strip()


def main():
    print("请输入角色选择: 1=好奇学生, 2=解释官")
    choice = input("选择: ").strip()
    user_text = _read_user_text(choice)

    if choice == "2":
        response = run_simple_explainer_agent(user_text)
    else:
        response = run_curious_student_agent(user_text)

    print("\n模型回复:\n")
    print(response)


if __name__ == "__main__":
    main()
