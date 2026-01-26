-- =============================================================================
-- 数据库迁移脚本（PostgreSQL）
-- 项目：闪词学习 (newstudy)
-- 说明：幂等脚本，可重复执行。适用于新库初始化或从旧结构迁移。
-- 执行：psql $DATABASE_URL -f sql/migration_export.sql
--      或：psql -h HOST -p PORT -U USER -d DB -f sql/migration_export.sql
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. 扩展（如未安装 pgvector，可注释掉下一行）
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS vector;

-- -----------------------------------------------------------------------------
-- 2. 枚举类型
-- -----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'card_status') THEN
        CREATE TYPE card_status AS ENUM (
            'NOT_STARTED',
            'NEEDS_REVIEW',
            'NEEDS_IMPROVE',
            'NOT_MASTERED',
            'MASTERED'
        );
    END IF;
END
$$;

-- -----------------------------------------------------------------------------
-- 3. 用户表
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

COMMENT ON TABLE users IS '用户表';
COMMENT ON COLUMN users.username IS '用户名';
COMMENT ON COLUMN users.email IS '邮箱';

-- -----------------------------------------------------------------------------
-- 4. 笔记表
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS notes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    markdown_content TEXT,
    default_role VARCHAR(50) DEFAULT '5岁孩子',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 若表已存在，补充可能缺失的列（来自后续迁移）
ALTER TABLE notes ADD COLUMN IF NOT EXISTS default_role VARCHAR(50) DEFAULT '5岁孩子';
ALTER TABLE notes ADD COLUMN IF NOT EXISTS markdown_content TEXT;
COMMENT ON COLUMN notes.default_role IS '默认学习角色（如5岁孩子、小学生等）';

CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC);

COMMENT ON TABLE notes IS '笔记表';
COMMENT ON COLUMN notes.user_id IS '用户ID';
COMMENT ON COLUMN notes.title IS '笔记标题';
COMMENT ON COLUMN notes.content IS '原始内容';
COMMENT ON COLUMN notes.markdown_content IS 'Markdown格式的笔记内容';

-- -----------------------------------------------------------------------------
-- 5. 闪词表
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS flash_cards (
    id SERIAL PRIMARY KEY,
    note_id INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    term VARCHAR(100) NOT NULL,
    status card_status NOT NULL DEFAULT 'NOT_STARTED',
    review_count INTEGER DEFAULT 0,
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    mastered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 为已存在的表补充可能缺失的列
ALTER TABLE flash_cards ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 0;
ALTER TABLE flash_cards ADD COLUMN IF NOT EXISTS mastered_at TIMESTAMP WITH TIME ZONE;
-- 若 status 仍为 VARCHAR，需先运行 migrations/migrate_card_status_enum.py 再建枚举约束

CREATE INDEX IF NOT EXISTS idx_flash_cards_note_id ON flash_cards(note_id);
CREATE INDEX IF NOT EXISTS idx_flash_cards_status ON flash_cards(status);
CREATE INDEX IF NOT EXISTS idx_flash_cards_term ON flash_cards(term);

COMMENT ON TABLE flash_cards IS '闪词表';
COMMENT ON COLUMN flash_cards.note_id IS '笔记ID';
COMMENT ON COLUMN flash_cards.term IS '闪词内容';
COMMENT ON COLUMN flash_cards.status IS '学习状态: NOT_STARTED, NEEDS_REVIEW, NEEDS_IMPROVE, NOT_MASTERED, MASTERED';
COMMENT ON COLUMN flash_cards.review_count IS '复习次数';
COMMENT ON COLUMN flash_cards.last_reviewed_at IS '最后复习时间';
COMMENT ON COLUMN flash_cards.mastered_at IS '掌握时间';

-- -----------------------------------------------------------------------------
-- 6. 学习记录表（费曼学习）
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS learning_records (
    id SERIAL PRIMARY KEY,
    card_id INTEGER NOT NULL REFERENCES flash_cards(id) ON DELETE CASCADE,
    note_id INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    selected_role VARCHAR(50) NOT NULL,
    user_explanation TEXT NOT NULL,
    score INTEGER NOT NULL,
    ai_feedback TEXT NOT NULL,
    status card_status NOT NULL,
    attempt_number INTEGER NOT NULL DEFAULT 1,
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_learning_records_card_id ON learning_records(card_id);
CREATE INDEX IF NOT EXISTS idx_learning_records_note_id ON learning_records(note_id);
CREATE INDEX IF NOT EXISTS idx_learning_records_attempted_at ON learning_records(attempted_at DESC);

COMMENT ON TABLE learning_records IS '学习记录表（费曼学习）';
COMMENT ON COLUMN learning_records.card_id IS '闪词卡片ID';
COMMENT ON COLUMN learning_records.note_id IS '笔记ID（冗余，便于查询）';
COMMENT ON COLUMN learning_records.selected_role IS '选择的角色（如5岁孩子、同事等）';
COMMENT ON COLUMN learning_records.user_explanation IS '用户的解释内容';
COMMENT ON COLUMN learning_records.score IS 'AI评估分数（0-100）';
COMMENT ON COLUMN learning_records.ai_feedback IS 'AI反馈内容';
COMMENT ON COLUMN learning_records.status IS '本次评估的状态';
COMMENT ON COLUMN learning_records.attempt_number IS '第几次尝试（同一卡片）';
COMMENT ON COLUMN learning_records.attempted_at IS '尝试时间';

-- -----------------------------------------------------------------------------
-- 7. 更新时间触发器（notes / flash_cards）
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_notes_updated_at ON notes;
CREATE TRIGGER update_notes_updated_at
    BEFORE UPDATE ON notes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_flash_cards_updated_at ON flash_cards;
CREATE TRIGGER update_flash_cards_updated_at
    BEFORE UPDATE ON flash_cards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- -----------------------------------------------------------------------------
-- 8. 默认数据
-- -----------------------------------------------------------------------------
INSERT INTO users (username, email)
VALUES ('default_user', 'default@example.com')
ON CONFLICT (username) DO NOTHING;

COMMIT;

-- =============================================================================
-- 使用说明
-- =============================================================================
-- 1) 全新库：直接执行本文件即可。
-- 2) 已有库（从旧结构升级）：
--    - 若 flash_cards.status / learning_records.status 仍是 VARCHAR，请先执行：
--      uv run python migrations/migrate_card_status_enum.py
--    - 再执行本文件，用于查漏补缺（列、索引、注释、触发器、默认用户）。
-- 3) 若环境中未安装 pgvector，请将第 1 节中的 CREATE EXTENSION vector 注释掉。
-- =============================================================================
