"""
迁移脚本：将 flash_cards 和 learning_records 表的 status 字段改为枚举类型

此脚本执行以下操作：
1. 创建 card_status 枚举类型（如果不存在）
2. 将现有的小写状态值转换为大写
3. 修改 flash_cards 表的 status 列为 card_status 类型
4. 修改 learning_records 表的 status 列为 card_status 类型
"""

import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv
from pathlib import Path

# 加载环境变量
env_path = Path(__file__).parent.parent / ".env"
load_dotenv(dotenv_path=env_path)


def parse_database_url(url: str) -> dict:
    """解析数据库连接 URL"""
    import re
    pattern = r'postgresql://([^:]+):([^@]+)@([^:]+):(\d+)/(.+)'
    match = re.match(pattern, url)
    if not match:
        raise ValueError(f"无效的 DATABASE_URL: {url}")

    return {
        'user': match.group(1),
        'password': match.group(2),
        'host': match.group(3),
        'port': match.group(4),
        'database': match.group(5),
    }


def migrate():
    """执行迁移"""
    DATABASE_URL = os.getenv("DATABASE_URL")
    if not DATABASE_URL:
        raise ValueError("DATABASE_URL 未配置！")

    db_params = parse_database_url(DATABASE_URL)

    print(f"🔄 连接数据库: {db_params['host']}:{db_params['port']}/{db_params['database']}")

    conn = psycopg2.connect(
        host=db_params['host'],
        port=db_params['port'],
        database=db_params['database'],
        user=db_params['user'],
        password=db_params['password'],
    )

    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            # 1. 检查并创建 card_status 枚举类型
            print("\n1️⃣ 检查 card_status 枚举类型...")
            cur.execute("""
                SELECT EXISTS (
                    SELECT 1 FROM pg_type
                    WHERE typname = 'card_status'
                )
            """)
            enum_exists = cur.fetchone()['exists']

            if not enum_exists:
                print("   创建 card_status 枚举类型...")
                cur.execute("""
                    CREATE TYPE card_status AS ENUM (
                        'NOT_STARTED',
                        'NEEDS_REVIEW',
                        'NEEDS_IMPROVE',
                        'NOT_MASTERED',
                        'MASTERED'
                    )
                """)
                print("   ✅ card_status 枚举类型已创建")
            else:
                print("   ℹ️ card_status 枚举类型已存在，跳过创建")

            # 2. 检查并转换 flash_cards 表中的状态值
            print("\n2️⃣ 转换 flash_cards 表的状态值...")
            cur.execute("""
                SELECT data_type
                FROM information_schema.columns
                WHERE table_name = 'flash_cards'
                  AND column_name = 'status'
            """)
            row = cur.fetchone()
            flash_cards_data_type = row['data_type'] if row else None

            if flash_cards_data_type == 'character varying':
                # 列还是 VARCHAR 类型，可以正常转换
                cur.execute("""
                    UPDATE flash_cards
                    SET status = CASE UPPER(status)
                        WHEN 'NOT_STARTED' THEN 'NOT_STARTED'
                        WHEN 'NEEDS_REVIEW' THEN 'NEEDS_REVIEW'
                        WHEN 'NEEDS_IMPROVE' THEN 'NEEDS_IMPROVE'
                        WHEN 'NOT_MASTERED' THEN 'NOT_MASTERED'
                        WHEN 'MASTERED' THEN 'MASTERED'
                        WHEN 'NEEDSREVIEW' THEN 'NEEDS_REVIEW'
                        WHEN 'NEEDSIMPROVE' THEN 'NEEDS_IMPROVE'
                        WHEN 'NOTMASTERED' THEN 'NOT_MASTERED'
                        WHEN 'NOTSTARTED' THEN 'NOT_STARTED'
                        ELSE 'NOT_STARTED'
                    END
                    WHERE status IS NOT NULL
                """)
                updated = cur.rowcount
                print(f"   ✅ 已更新 {updated} 条 flash_cards 记录")
            elif flash_cards_data_type == 'USER-DEFINED':
                # 列已是枚举类型，直接更新不匹配的值
                # 先检查有多少条记录的值不在枚举中
                cur.execute("""
                    SELECT COUNT(*) as count
                    FROM flash_cards
                    WHERE status NOT IN ('NOT_STARTED', 'NEEDS_REVIEW', 'NEEDS_IMPROVE', 'NOT_MASTERED', 'MASTERED')
                """)
                count = cur.fetchone()['count']
                if count > 0:
                    print(f"   ⚠️ 发现 {count} 条记录的状态值不在枚举范围内")
                    # 需要先把列转回 VARCHAR 才能更新
                    print("   🔄 将 status 列临时转为 VARCHAR...")
                    cur.execute("""
                        ALTER TABLE flash_cards ALTER COLUMN status TYPE VARCHAR(20)
                    """)
                    # 更新值为大写
                    cur.execute("""
                        UPDATE flash_cards
                        SET status = UPPER(status)
                        WHERE status IS NOT NULL
                    """)
                    updated = cur.rowcount
                    print(f"   ✅ 已更新 {updated} 条 flash_cards 记录为大写")
                else:
                    print("   ℹ️ flash_cards 表中所有状态值已是有效的枚举值")
            else:
                print(f"   ℹ️ flash_cards.status 列类型为: {flash_cards_data_type}")

            # 3. 检查并转换 learning_records 表中的状态值
            print("\n3️⃣ 转换 learning_records 表的状态值...")
            cur.execute("""
                SELECT data_type
                FROM information_schema.columns
                WHERE table_name = 'learning_records'
                  AND column_name = 'status'
            """)
            row = cur.fetchone()
            learning_records_data_type = row['data_type'] if row else None

            if learning_records_data_type == 'character varying':
                cur.execute("""
                    UPDATE learning_records
                    SET status = CASE UPPER(status)
                        WHEN 'NOT_STARTED' THEN 'NOT_STARTED'
                        WHEN 'NEEDS_REVIEW' THEN 'NEEDS_REVIEW'
                        WHEN 'NEEDS_IMPROVE' THEN 'NEEDS_IMPROVE'
                        WHEN 'NOT_MASTERED' THEN 'NOT_MASTERED'
                        WHEN 'MASTERED' THEN 'MASTERED'
                        WHEN 'NEEDSREVIEW' THEN 'NEEDS_REVIEW'
                        WHEN 'NEEDSIMPROVE' THEN 'NEEDS_IMPROVE'
                        WHEN 'NOTMASTERED' THEN 'NOT_MASTERED'
                        WHEN 'NOTSTARTED' THEN 'NOT_STARTED'
                        ELSE 'NOT_STARTED'
                    END
                    WHERE status IS NOT NULL
                """)
                updated = cur.rowcount
                print(f"   ✅ 已更新 {updated} 条 learning_records 记录")
            elif learning_records_data_type == 'USER-DEFINED':
                cur.execute("""
                    SELECT COUNT(*) as count
                    FROM learning_records
                    WHERE status NOT IN ('NOT_STARTED', 'NEEDS_REVIEW', 'NEEDS_IMPROVE', 'NOT_MASTERED', 'MASTERED')
                """)
                count = cur.fetchone()['count']
                if count > 0:
                    print(f"   ⚠️ 发现 {count} 条记录的状态值不在枚举范围内")
                    print("   🔄 将 status 列临时转为 VARCHAR...")
                    cur.execute("""
                        ALTER TABLE learning_records ALTER COLUMN status TYPE VARCHAR(20)
                    """)
                    cur.execute("""
                        UPDATE learning_records
                        SET status = UPPER(status)
                        WHERE status IS NOT NULL
                    """)
                    updated = cur.rowcount
                    print(f"   ✅ 已更新 {updated} 条 learning_records 记录为大写")
                else:
                    print("   ℹ️ learning_records 表中所有状态值已是有效的枚举值")
            else:
                print(f"   ℹ️ learning_records.status 列类型为: {learning_records_data_type}")

            # 4. 修改 flash_cards 表的 status 列为枚举类型
            print("\n4️⃣ 修改 flash_cards.status 列为枚举类型...")
            cur.execute("""
                SELECT column_default
                FROM information_schema.columns
                WHERE table_name = 'flash_cards'
                  AND column_name = 'status'
            """)
            row = cur.fetchone()
            current_default = row['column_default'] if row else None

            # 如果当前列不是枚举类型，进行转换
            cur.execute("""
                SELECT data_type
                FROM information_schema.columns
                WHERE table_name = 'flash_cards'
                  AND column_name = 'status'
            """)
            row = cur.fetchone()
            data_type = row['data_type'] if row else None

            if data_type and data_type != 'USER-DEFINED':
                print(f"   当前类型: {data_type}")
                # 先删除默认值
                cur.execute("""
                    ALTER TABLE flash_cards ALTER COLUMN status DROP DEFAULT
                """)

                # 转换为枚举类型
                cur.execute("""
                    ALTER TABLE flash_cards ALTER COLUMN status TYPE card_status
                    USING status::card_status
                """)

                # 设置新的默认值
                cur.execute("""
                    ALTER TABLE flash_cards ALTER COLUMN status SET DEFAULT 'NOT_STARTED'
                """)
                print("   ✅ flash_cards.status 列已转换为 card_status 枚举类型")
            else:
                print("   ℹ️ flash_cards.status 列已经是枚举类型，跳过")

            # 5. 修改 learning_records 表的 status 列为枚举类型
            print("\n5️⃣ 修改 learning_records.status 列为枚举类型...")
            cur.execute("""
                SELECT data_type
                FROM information_schema.columns
                WHERE table_name = 'learning_records'
                  AND column_name = 'status'
            """)
            row = cur.fetchone()
            data_type = row['data_type'] if row else None

            if data_type and data_type != 'USER-DEFINED':
                print(f"   当前类型: {data_type}")
                cur.execute("""
                    ALTER TABLE learning_records ALTER COLUMN status TYPE card_status
                    USING status::card_status
                """)
                print("   ✅ learning_records.status 列已转换为 card_status 枚举类型")
            else:
                print("   ℹ️ learning_records.status 列已经是枚举类型，跳过")

            conn.commit()

            print("\n" + "="*50)
            print("✅ 迁移完成！")
            print("="*50)

            # 显示统计信息
            cur.execute("""
                SELECT status, COUNT(*) as count
                FROM flash_cards
                GROUP BY status
                ORDER BY status
            """)
            print("\n📊 flash_cards 状态分布:")
            for row in cur.fetchall():
                print(f"   {row['status']}: {row['count']} 条")

    except Exception as e:
        conn.rollback()
        print(f"\n❌ 迁移失败: {e}")
        raise
    finally:
        conn.close()


if __name__ == "__main__":
    migrate()
