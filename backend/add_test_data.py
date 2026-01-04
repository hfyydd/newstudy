#!/usr/bin/env python3
"""
添加测试数据脚本
清空数据库并填充测试笔记和词条
"""

from database import db
from datetime import datetime
import uuid

def clear_all_data():
    """清空所有数据"""
    conn = db._get_connection()
    cursor = conn.cursor()
    
    cursor.execute("DELETE FROM flash_cards")
    deleted_cards = cursor.rowcount
    
    cursor.execute("DELETE FROM notes")
    deleted_notes = cursor.rowcount
    
    conn.commit()
    conn.close()
    
    print(f"✓ 已清空 {deleted_notes} 个笔记和 {deleted_cards} 个词条")
    return deleted_notes, deleted_cards


def add_test_notes():
    """添加测试笔记"""
    test_notes = [
        {
            "title": "机器学习基础",
            "content": """
机器学习是人工智能的一个分支，它使计算机能够从数据中学习，而无需明确编程。

核心概念：
1. 监督学习：使用标记的训练数据来训练模型，例如分类和回归任务。
2. 无监督学习：从未标记的数据中发现模式，例如聚类和降维。
3. 强化学习：通过与环境交互来学习最优策略。

常用算法：
- 线性回归：用于预测连续值
- 决策树：用于分类和回归
- 神经网络：用于复杂模式识别
- 支持向量机：用于分类任务

评估指标：
- 准确率：分类正确的样本比例
- 精确率和召回率：用于不平衡数据集
- F1分数：精确率和召回率的调和平均
            """.strip()
        },
        {
            "title": "经济学原理",
            "content": """
经济学是研究如何分配稀缺资源以满足人类无限需求的学科。

基本概念：
1. 供给与需求：市场价格由供给和需求的平衡决定。
2. 机会成本：选择一种方案而放弃另一种方案的成本。
3. 边际效用：每增加一单位消费带来的额外满足感。

市场类型：
- 完全竞争市场：大量买家和卖家，产品同质
- 垄断市场：单一卖家控制市场
- 寡头垄断：少数几个大企业控制市场
- 垄断竞争：许多卖家，产品有差异

宏观经济指标：
- GDP：国内生产总值，衡量国家经济总量
- 通货膨胀率：物价水平上涨的速度
- 失业率：劳动力中失业人口的比例
- 利率：借贷资金的成本
            """.strip()
        },
        {
            "title": "Python编程基础",
            "content": """
Python是一种高级编程语言，以其简洁的语法和强大的功能而闻名。

基本语法：
1. 变量和数据类型：整数、浮点数、字符串、布尔值、列表、字典等。
2. 控制流：if/else条件语句、for和while循环。
3. 函数：使用def关键字定义，支持参数和返回值。

数据结构：
- 列表（list）：有序的可变序列
- 元组（tuple）：有序的不可变序列
- 字典（dict）：键值对映射
- 集合（set）：无序的唯一元素集合

面向对象编程：
- 类（class）：定义对象的模板
- 对象（object）：类的实例
- 继承：子类继承父类的属性和方法
- 封装：将数据和方法封装在类中
- 多态：同一接口可以有不同实现

常用库：
- NumPy：数值计算
- Pandas：数据处理
- Matplotlib：数据可视化
- Flask/Django：Web开发框架
            """.strip()
        },
        {
            "title": "数据库设计",
            "content": """
数据库是存储和管理数据的系统，关系型数据库使用表来组织数据。

核心概念：
1. 表（Table）：数据的二维结构，由行和列组成。
2. 主键（Primary Key）：唯一标识表中每一行的字段。
3. 外键（Foreign Key）：建立表之间关系的字段。
4. 索引（Index）：提高查询速度的数据结构。

SQL操作：
- SELECT：查询数据
- INSERT：插入新记录
- UPDATE：更新现有记录
- DELETE：删除记录

数据库设计原则：
- 第一范式（1NF）：每个字段都是原子值
- 第二范式（2NF）：消除部分依赖
- 第三范式（3NF）：消除传递依赖

事务特性（ACID）：
- 原子性（Atomicity）：事务要么全部执行，要么全部回滚
- 一致性（Consistency）：事务前后数据库状态一致
- 隔离性（Isolation）：并发事务互不干扰
- 持久性（Durability）：提交的事务永久保存
            """.strip()
        },
        {
            "title": "Web开发基础",
            "content": """
Web开发涉及创建在互联网上运行的应用程序。

前端技术：
1. HTML：网页结构和内容标记语言。
2. CSS：样式表，控制网页的外观和布局。
3. JavaScript：客户端脚本语言，实现交互功能。

后端技术：
- 服务器：处理请求和响应的计算机
- API：应用程序接口，定义服务之间的通信方式
- 数据库：存储应用数据
- 认证和授权：用户身份验证和权限管理

HTTP协议：
- GET：获取资源
- POST：创建新资源
- PUT：更新资源
- DELETE：删除资源

前端框架：
- React：组件化UI库
- Vue.js：渐进式JavaScript框架
- Angular：完整的前端框架

后端框架：
- Express.js：Node.js的Web框架
- Django：Python的Web框架
- Spring Boot：Java的Web框架
            """.strip()
        }
    ]
    
    created_notes = []
    for note_data in test_notes:
        note = db.create_note(
            title=note_data["title"],
            content=note_data["content"]
        )
        created_notes.append(note)
        print(f"✓ 创建笔记: {note.title} (ID: {note.id[:8]}...)")
    
    return created_notes


def add_test_flashcards(notes):
    """为笔记生成测试词条"""
    # 为每个笔记预定义的词条列表
    terms_map = {
        "机器学习基础": [
            "机器学习", "监督学习", "无监督学习", "强化学习", 
            "线性回归", "决策树", "神经网络", "支持向量机",
            "特征工程", "过拟合", "交叉验证", "准确率", 
            "精确率", "召回率", "F1分数"
        ],
        "经济学原理": [
            "供给与需求", "机会成本", "边际效用", "完全竞争市场",
            "垄断市场", "寡头垄断", "GDP", "通货膨胀率",
            "失业率", "利率", "货币政策", "财政政策",
            "市场均衡", "价格弹性"
        ],
        "Python编程基础": [
            "变量", "数据类型", "控制流", "函数", "列表",
            "元组", "字典", "集合", "类", "对象",
            "继承", "封装", "多态", "NumPy", "Pandas",
            "Matplotlib", "Flask", "Django"
        ],
        "数据库设计": [
            "表", "主键", "外键", "索引", "第一范式",
            "第二范式", "第三范式", "SELECT", "INSERT",
            "UPDATE", "DELETE", "事务", "ACID",
            "原子性", "一致性", "隔离性", "持久性"
        ],
        "Web开发基础": [
            "HTML", "CSS", "JavaScript", "服务器", "API",
            "GET", "POST", "PUT", "DELETE", "React",
            "Vue.js", "Angular", "Express.js", "Django",
            "Spring Boot", "认证", "授权"
        ]
    }
    
    import random
    
    # 为每个笔记生成词条
    for note in notes:
        terms = terms_map.get(note.title, [])
        
        if terms:
            cards = db.create_flash_cards(note.id, terms)
            print(f"✓ 为笔记 '{note.title}' 生成了 {len(cards)} 个词条")
            
            # 随机设置一些词条的状态（模拟学习进度）
            conn = db._get_connection()
            cursor = conn.cursor()
            
            for term in terms:
                # 随机分配状态
                status_weights = {
                    'notStarted': 0.3,
                    'needsReview': 0.25,
                    'needsImprove': 0.25,
                    'mastered': 0.2
                }
                status = random.choices(
                    list(status_weights.keys()),
                    weights=list(status_weights.values())
                )[0]
                
                cursor.execute("""
                    UPDATE flash_cards 
                    SET status = ?
                    WHERE note_id = ? AND term = ?
                """, (status, note.id, term))
            
            conn.commit()
            conn.close()
        else:
            print(f"⚠️  笔记 '{note.title}' 没有预定义的词条")


def main():
    """主函数"""
    print("=" * 60)
    print("开始添加测试数据")
    print("=" * 60)
    
    # 1. 清空所有数据
    print("\n[1/3] 清空数据库...")
    clear_all_data()
    
    # 2. 添加测试笔记
    print("\n[2/3] 添加测试笔记...")
    notes = add_test_notes()
    
    # 3. 生成词条
    print("\n[3/3] 生成闪词卡片...")
    add_test_flashcards(notes)
    
    # 4. 统计结果
    print("\n" + "=" * 60)
    print("测试数据添加完成！")
    print("=" * 60)
    
    # 统计
    all_notes = db.list_notes()
    print(f"\n📝 笔记总数: {len(all_notes)}")
    
    import sqlite3
    conn = sqlite3.connect('notes.db')
    cursor = conn.cursor()
    
    cursor.execute("SELECT COUNT(*) FROM flash_cards")
    total_cards = cursor.fetchone()[0]
    print(f"📚 词条总数: {total_cards}")
    
    cursor.execute("SELECT status, COUNT(*) as count FROM flash_cards GROUP BY status")
    status_stats = cursor.fetchall()
    print("\n📊 词条状态统计:")
    for status, count in status_stats:
        status_name = {
            'notStarted': '未开始',
            'needsReview': '需要复习',
            'needsImprove': '需要改进',
            'mastered': '已掌握'
        }.get(status, status)
        print(f"  - {status_name}: {count} 个")
    
    conn.close()
    print("\n✓ 完成！")


if __name__ == "__main__":
    main()
