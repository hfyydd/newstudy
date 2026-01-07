-- 数据库初始化 SQL 脚本
-- 用于直接执行 SQL 创建表结构

-- 启用 pgvector 扩展
CREATE EXTENSION IF NOT EXISTS vector;

-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- 创建笔记表
CREATE TABLE IF NOT EXISTS notes (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    markdown_content TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON notes(user_id);
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC);

-- 创建闪词表
CREATE TABLE IF NOT EXISTS flash_cards (
    id SERIAL PRIMARY KEY,
    note_id INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    term VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'not_started',
    review_count INTEGER DEFAULT 0,
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    mastered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_flash_cards_note_id ON flash_cards(note_id);
CREATE INDEX IF NOT EXISTS idx_flash_cards_status ON flash_cards(status);
CREATE INDEX IF NOT EXISTS idx_flash_cards_term ON flash_cards(term);

-- 创建学习记录表
CREATE TABLE IF NOT EXISTS learning_records (
    id SERIAL PRIMARY KEY,
    card_id INTEGER NOT NULL REFERENCES flash_cards(id) ON DELETE CASCADE,
    note_id INTEGER NOT NULL REFERENCES notes(id) ON DELETE CASCADE,
    selected_role VARCHAR(50) NOT NULL,
    user_explanation TEXT NOT NULL,
    score INTEGER NOT NULL,
    ai_feedback TEXT NOT NULL,
    status VARCHAR(20) NOT NULL,
    attempt_number INTEGER NOT NULL DEFAULT 1,
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_learning_records_card_id ON learning_records(card_id);
CREATE INDEX IF NOT EXISTS idx_learning_records_note_id ON learning_records(note_id);
CREATE INDEX IF NOT EXISTS idx_learning_records_attempted_at ON learning_records(attempted_at DESC);

-- 添加学习记录表注释
COMMENT ON TABLE learning_records IS '学习记录表';
COMMENT ON COLUMN learning_records.card_id IS '闪词卡片ID';
COMMENT ON COLUMN learning_records.note_id IS '笔记ID（冗余，便于查询）';
COMMENT ON COLUMN learning_records.selected_role IS '选择的角色（如5岁孩子、同事等）';
COMMENT ON COLUMN learning_records.user_explanation IS '用户的解释内容';
COMMENT ON COLUMN learning_records.score IS 'AI评估分数（0-100）';
COMMENT ON COLUMN learning_records.ai_feedback IS 'AI反馈内容';
COMMENT ON COLUMN learning_records.status IS '本次评估的状态';
COMMENT ON COLUMN learning_records.attempt_number IS '第几次尝试（同一卡片）';
COMMENT ON COLUMN learning_records.attempted_at IS '尝试时间';

-- 插入默认用户（用于本地调试）
-- 如果用户已存在则忽略
INSERT INTO users (username, email)
VALUES ('default_user', 'default@example.com')
ON CONFLICT (username) DO NOTHING;

-- 添加注释
COMMENT ON TABLE users IS '用户表';
COMMENT ON TABLE notes IS '笔记表';
COMMENT ON TABLE flash_cards IS '闪词表';

COMMENT ON COLUMN users.username IS '用户名';
COMMENT ON COLUMN users.email IS '邮箱';
COMMENT ON COLUMN notes.user_id IS '用户ID';
COMMENT ON COLUMN notes.title IS '笔记标题';
COMMENT ON COLUMN notes.content IS '原始内容';
COMMENT ON COLUMN notes.markdown_content IS 'Markdown格式的笔记内容';
COMMENT ON COLUMN flash_cards.note_id IS '笔记ID';
COMMENT ON COLUMN flash_cards.term IS '闪词内容';
COMMENT ON COLUMN flash_cards.status IS '学习状态: not_started, needs_review（需巩固）, needs_improve, not_mastered, mastered';
COMMENT ON COLUMN flash_cards.review_count IS '复习次数';
COMMENT ON COLUMN flash_cards.last_reviewed_at IS '最后复习时间';
COMMENT ON COLUMN flash_cards.mastered_at IS '掌握时间';

