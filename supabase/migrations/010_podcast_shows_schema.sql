-- Create Podcast Shows table
CREATE TABLE IF NOT EXISTS podcast_shows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_fr VARCHAR(255) NOT NULL,
    title_ar VARCHAR(255) NOT NULL,
    description_fr TEXT,
    description_ar TEXT,
    image_url TEXT,
    author_id UUID REFERENCES authors(id) ON DELETE SET NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add Foreign Key to Teachings (Episodes)
ALTER TABLE teachings ADD COLUMN IF NOT EXISTS podcast_show_id UUID REFERENCES podcast_shows(id) ON DELETE SET NULL;

-- Enable RLS
ALTER TABLE podcast_shows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public podcast_shows are viewable by everyone" ON podcast_shows FOR SELECT USING (true);
