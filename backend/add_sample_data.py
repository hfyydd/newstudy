"""
添加模拟数据到数据库
用于测试和演示
"""

from database import db
from datetime import datetime, timedelta

def add_sample_data():
    """添加模拟笔记和闪词数据"""
    
    # 创建几个示例笔记
    notes_data = [
        {
            "title": "机器学习基础",
            "content": """
机器学习是人工智能的一个分支，它使计算机能够从数据中学习，而无需明确编程。

主要概念：
1. 监督学习：使用标记数据训练模型
2. 无监督学习：从未标记数据中发现模式
3. 强化学习：通过与环境交互来学习

常用算法：
- 线性回归
- 决策树
- 神经网络
- 支持向量机
            """.strip()
        },
        {
            "title": "Python编程技巧",
            "content": """
Python是一种高级编程语言，以其简洁和可读性而闻名。

重要特性：
1. 动态类型
2. 解释型语言
3. 丰富的标准库
4. 强大的第三方生态系统

常用库：
- NumPy：数值计算
- Pandas：数据分析
- Matplotlib：数据可视化
- Flask：Web开发
            """.strip()
        },
        {
            "title": "数据结构与算法",
            "content": """
数据结构是计算机科学的基础，用于组织和存储数据。

基本数据结构：
1. 数组：连续内存存储
2. 链表：动态内存分配
3. 栈：后进先出（LIFO）
4. 队列：先进先出（FIFO）
5. 树：层次结构
6. 图：网络结构

常见算法：
- 排序算法：快速排序、归并排序
- 搜索算法：二分查找、深度优先搜索
- 动态规划：解决优化问题
            """.strip()
        },
        {
            "title": "Web开发基础",
            "content": """
Web开发涉及创建网站和Web应用程序。

前端技术：
- HTML：页面结构
- CSS：样式设计
- JavaScript：交互逻辑
- React/Vue：现代框架

后端技术：
- Node.js：JavaScript运行时
- Python Flask/Django：Python框架
- 数据库：MySQL、PostgreSQL、MongoDB

全栈开发需要同时掌握前后端技术。
            """.strip()
        },
        {
            "title": "数据库设计原理",
            "content": """
数据库设计是构建高效数据存储系统的关键。

核心概念：
1. 关系模型：表、行、列
2. 主键和外键：数据完整性
3. 索引：提高查询性能
4. 范式化：减少数据冗余

SQL基础：
- SELECT：查询数据
- INSERT：插入数据
- UPDATE：更新数据
- DELETE：删除数据

NoSQL数据库：
- MongoDB：文档数据库
- Redis：键值存储
- Cassandra：列式存储
            """.strip()
        }
    ]
    
    # 创建笔记
    created_notes = []
    for note_data in notes_data:
        note = db.create_note(
            title=note_data["title"],
            content=note_data["content"]
        )
        created_notes.append(note)
        print(f"✓ 创建笔记: {note.title} (ID: {note.id})")
    
    # 为每个笔记添加一些闪词卡片
    flash_cards_data = [
        # 机器学习基础
        ["机器学习", "监督学习", "无监督学习", "强化学习", "线性回归", "决策树", "神经网络", "支持向量机", "特征工程", "过拟合"],
        # Python编程技巧
        ["动态类型", "解释型语言", "标准库", "NumPy", "Pandas", "Matplotlib", "Flask", "列表推导式", "装饰器", "生成器"],
        # 数据结构与算法
        ["数组", "链表", "栈", "队列", "树", "图", "快速排序", "归并排序", "二分查找", "动态规划"],
        # Web开发基础
        ["HTML", "CSS", "JavaScript", "React", "Vue", "Node.js", "Flask", "Django", "MySQL", "PostgreSQL"],
        # 数据库设计原理
        ["关系模型", "主键", "外键", "索引", "范式化", "SQL", "MongoDB", "Redis", "NoSQL", "数据完整性"]
    ]
    
    # 为每个笔记添加闪词卡片，并设置一些学习状态
    status_distribution = ["MASTERED", "NEEDS_REVIEW", "NEEDS_IMPROVE", "NOT_STARTED"]

    for i, note in enumerate(created_notes):
        terms = flash_cards_data[i] if i < len(flash_cards_data) else []

        # 创建闪词卡片
        cards = db.create_flash_cards(note.id, terms)
        print(f"✓ 为笔记 '{note.title}' 创建了 {len(cards)} 个闪词卡片")

        # 更新一些卡片的学习状态（模拟学习进度）
        if cards:
            conn = db._get_connection()
            try:
                cursor = conn.cursor()

                # 随机设置一些卡片的状态
                for j, card in enumerate(cards):
                    # 根据索引分配状态，模拟学习进度
                    if j < len(cards) * 0.3:  # 30% 已掌握
                        status = "MASTERED"
                    elif j < len(cards) * 0.5:  # 20% 待复习
                        status = "NEEDS_REVIEW"
                    elif j < len(cards) * 0.7:  # 20% 需改进
                        status = "NEEDS_IMPROVE"
                    else:  # 30% 未开始
                        status = "NOT_STARTED"
                    
                    # 更新状态
                    cursor.execute("""
                        UPDATE flash_cards 
                        SET status = ? 
                        WHERE id = ?
                    """, (status, card.id))
                
                conn.commit()
                print(f"✓ 更新了笔记 '{note.title}' 的闪词卡片学习状态")
            finally:
                conn.close()
    
    print("\n✅ 模拟数据添加完成！")
    print(f"共创建 {len(created_notes)} 个笔记")
    
    # 显示统计信息
    print("\n📊 数据统计：")
    for note in created_notes:
        progress = db.get_flash_card_progress(note.id)
        print(f"  - {note.title}: {progress['total']} 个词条, "
              f"{progress['mastered']} 已掌握, "
              f"{progress['needsReview']} 待复习")

if __name__ == "__main__":
    add_sample_data()
