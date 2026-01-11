-- Migration for Teachings (Videos/Podcasts) and Articles module
-- File: supabase/migrations/006_teachings_schema.sql

-- Enable pg_trgm for text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Authors Table (e.g. Sidi Muhammad Erradi Guennoun)
CREATE TABLE IF NOT EXISTS authors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    bio TEXT,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Categories Table
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_fr VARCHAR(100) NOT NULL,
    name_ar VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    icon_name VARCHAR(50), -- Flutter icon name or URL
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Teachings (Videos & Audio)
CREATE TABLE IF NOT EXISTS teachings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_fr VARCHAR(255) NOT NULL,
    title_ar VARCHAR(255) NOT NULL,
    description_fr TEXT,
    description_ar TEXT,
    type VARCHAR(20) NOT NULL CHECK (type IN ('VIDEO', 'AUDIO')),
    media_url TEXT NOT NULL, -- YouTube URL or Storage URL
    thumbnail_url TEXT,
    duration_seconds INTEGER DEFAULT 0,
    author_id UUID REFERENCES authors(id) ON DELETE SET NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    views_count BIGINT DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Articles (Texts)
CREATE TABLE IF NOT EXISTS articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_fr VARCHAR(255) NOT NULL,
    title_ar VARCHAR(255) NOT NULL,
    content_fr TEXT, -- HTML or Markdown
    content_ar TEXT, -- HTML or Markdown
    author_id UUID REFERENCES authors(id) ON DELETE SET NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    read_time_minutes INTEGER DEFAULT 5,
    views_count BIGINT DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Interactions (Favorites, History, Progress)
CREATE TABLE IF NOT EXISTS user_interactions (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    item_id UUID NOT NULL, -- Can refer to teaching_id or article_id
    item_type VARCHAR(20) NOT NULL CHECK (item_type IN ('TEACHING', 'ARTICLE')),
    is_favorite BOOLEAN DEFAULT FALSE,
    last_position_seconds INTEGER DEFAULT 0, -- For video/audio resume
    last_read_percentage INTEGER DEFAULT 0, -- For article scroll position
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, item_id, item_type)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_teachings_category ON teachings(category_id);
CREATE INDEX IF NOT EXISTS idx_teachings_author ON teachings(author_id);
CREATE INDEX IF NOT EXISTS idx_articles_category ON articles(category_id);
CREATE INDEX IF NOT EXISTS idx_articles_author ON articles(author_id);

-- Search Indexes (GIN for Full Text Search)
CREATE INDEX IF NOT EXISTS idx_teachings_title_fr_trgm ON teachings USING gin (title_fr gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_teachings_title_ar_trgm ON teachings USING gin (title_ar gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_articles_title_fr_trgm ON articles USING gin (title_fr gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_articles_title_ar_trgm ON articles USING gin (title_ar gin_trgm_ops);

-- RLS Policies (Row Level Security)
ALTER TABLE authors ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachings ENABLE ROW LEVEL SECURITY;
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interactions ENABLE ROW LEVEL SECURITY;

-- Public Read Access
CREATE POLICY "Public authors are viewable by everyone" ON authors FOR SELECT USING (true);
CREATE POLICY "Public categories are viewable by everyone" ON categories FOR SELECT USING (true);
CREATE POLICY "Public teachings are viewable by everyone" ON teachings FOR SELECT USING (true);
CREATE POLICY "Public articles are viewable by everyone" ON articles FOR SELECT USING (true);

-- User Interactions: Users can manage their own data
CREATE POLICY "Users can view own interactions" ON user_interactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own interactions" ON user_interactions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own interactions" ON user_interactions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own interactions" ON user_interactions FOR DELETE USING (auth.uid() = user_id);
