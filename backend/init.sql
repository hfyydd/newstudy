-- PostgreSQL数据库初始化脚本

-- 创建数据库结构
CREATE DATABASE IF NOT EXISTS newstudy;

-- 连接到数据库
\c newstudy;

-- 创建notes表
CREATE TABLE IF NOT EXISTS notes (
    id TEXT PRIMARY KEY,
    title TEXT,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- 创建flash_cards表
CREATE TABLE IF NOT EXISTS flash_cards (
    id TEXT PRIMARY KEY,
    note_id TEXT NOT NULL,
    term TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'notStarted',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    last_reviewed_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT fk_note FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
    CONSTRAINT unique_note_term UNIQUE(note_id, term)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_flash_cards_note_id ON flash_cards(note_id);
CREATE INDEX IF NOT EXISTS idx_flash_cards_status ON flash_cards(status);
CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at);

-- 创建更新时间触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 创建触发器
CREATE TRIGGER update_notes_updated_at 
    BEFORE UPDATE ON notes 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 插入示例数据（可选）
INSERT INTO notes (id, title, content) VALUES 
('example-note-1', '示例笔记', '这是一个示例笔记，用于测试系统功能。包含一些专业术语如人工智能、机器学习等。')
ON CONFLICT (id) DO NOTHING;

-- 插入示例闪词卡片
INSERT INTO flash_cards (id, note_id, term, status) VALUES 
('card-1', 'example-note-1', '人工智能', 'notStarted'),
('card-2', 'example-note-1', '机器学习', 'notStarted')
ON CONFLICT (id) DO NOTHING;

-- 授权给应用用户
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO newstudy_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO newstudy_user;