-- Create Tables for Media Module (Video/Podcast)

-- 1. Authors (Speakers/Guides)
CREATE TABLE IF NOT EXISTS public.media_authors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Categories (Themes: Zikr, Causerie, etc.)
CREATE TABLE IF NOT EXISTS public.media_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    rank INTEGER DEFAULT 0, -- For sorting
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Channels (YouTube source channels for the scraper)
CREATE TABLE IF NOT EXISTS public.media_channels (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    youtube_id TEXT NOT NULL UNIQUE, -- The Channel ID (ex: UC...)
    name TEXT NOT NULL,
    thumbnail_url TEXT,
    auto_import BOOLEAN DEFAULT TRUE,
    last_scraped_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Videos
-- Status Enum behavior modeled with text check constraint for flexibility
CREATE TABLE IF NOT EXISTS public.media_videos (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    youtube_id TEXT NOT NULL UNIQUE, -- The Video ID
    title TEXT NOT NULL,
    description TEXT,
    duration INTEGER, -- In seconds
    
    -- Metadata
    channel_id UUID REFERENCES public.media_channels(id) ON DELETE SET NULL,
    author_id UUID REFERENCES public.media_authors(id) ON DELETE SET NULL,
    category_id UUID REFERENCES public.media_categories(id) ON DELETE SET NULL,
    
    -- Media specific
    published_at TIMESTAMPTZ, -- When it was published on YouTube
    created_at TIMESTAMPTZ DEFAULT now(), -- When we imported it
    
    -- Features
    custom_subtitle_url TEXT, -- Path to .srt/.vtt in Storage
    
    -- Moderation
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PUBLISHED', 'ARCHIVED'))
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_media_videos_status ON public.media_videos(status);
CREATE INDEX IF NOT EXISTS idx_media_videos_author ON public.media_videos(author_id);
CREATE INDEX IF NOT EXISTS idx_media_videos_category ON public.media_videos(category_id);
CREATE INDEX IF NOT EXISTS idx_media_videos_published_at ON public.media_videos(published_at DESC);

-- RLS Policies (Row Level Security)
ALTER TABLE public.media_authors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media_videos ENABLE ROW LEVEL SECURITY;

-- Policy: Everyone can READ PUBLISHED content
CREATE POLICY "Everyone can read authors" ON public.media_authors FOR SELECT USING (true);
CREATE POLICY "Everyone can read categories" ON public.media_categories FOR SELECT USING (true);
CREATE POLICY "Everyone can read published videos" ON public.media_videos FOR SELECT USING (status = 'PUBLISHED');

-- Policy: Authenticated users (or just Admins later) can INSERT for now (to facilitate scraper/admin usage)
-- In a real prod env, we would restrict this to a SERVICE_ROLE or specific ADMIN role.
-- For now, allow authenticated to insert/update for development.
CREATE POLICY "Auth can manage media" ON public.media_videos USING (auth.role() = 'authenticated');
CREATE POLICY "Auth can manage authors" ON public.media_authors USING (auth.role() = 'authenticated');
CREATE POLICY "Auth can manage categories" ON public.media_categories USING (auth.role() = 'authenticated');
CREATE POLICY "Auth can manage channels" ON public.media_channels USING (auth.role() = 'authenticated');
