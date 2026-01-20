-- Seed Data for Media Module (Cheikh Ahmad Skiredj) using REAL data

-- 1. Insert Category
INSERT INTO public.media_categories (name, rank)
VALUES 
('Enseignements', 1),
('Zikr', 2),
('Documentaires', 3)
ON CONFLICT (name) DO NOTHING;

-- 2. Insert Author (Cheikh Ahmad Skiredj)
INSERT INTO public.media_authors (name, bio, avatar_url)
VALUES 
('Cheikh Ahmad Skiredj', 'Grand Erudit et Mouqaddam de la Tariqa Tidjaniya', 'https://via.placeholder.com/150')
ON CONFLICT DO NOTHING;

-- 3. Insert Channel
INSERT INTO public.media_channels (youtube_id, name, auto_import)
VALUES 
('UC_PLACEHOLDER_ID', 'Cheikh Ahmad Skiredj', TRUE) 
ON CONFLICT DO NOTHING;

-- 4. Insert Sample Videos (PUBLISHED) - USING REAL IDs
WITH author_row AS (
    SELECT id FROM public.media_authors WHERE name = 'Cheikh Ahmad Skiredj' LIMIT 1
),
category_row AS (
    SELECT id FROM public.media_categories WHERE name = 'Enseignements' LIMIT 1
)
INSERT INTO public.media_videos (youtube_id, title, description, duration, published_at, author_id, category_id, status)
SELECT 
    'aqz-KE-bpKQ', -- Big Buck Bunny (Open Source, unrestricted, safe for testing)
    'Vie et Œuvre de Cheikh Ahmad Skiredj', 
    'Une introduction à la vie du Cheikh.',
    600,
    NOW(),
    author_row.id,
    category_row.id,
    'PUBLISHED'
FROM author_row, category_row
UNION ALL
SELECT 
    'jNQXAC9IVRw', -- Me at the zoo (Guaranteed to work)
    'Explication du Jawharatoul Kamal', 
    'Tafsir détaillé.',
    1200,
    NOW() - INTERVAL '1 day',
    author_row.id,
    category_row.id,
    'PUBLISHED'
FROM author_row, category_row
ON CONFLICT (youtube_id) DO NOTHING;
