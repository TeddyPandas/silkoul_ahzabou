-- Seed Data for Teachings Module
-- File: supabase/migrations/007_seed_teachings_data.sql

-- 1. Insert Author
INSERT INTO authors (id, name, bio, image_url)
VALUES 
    ('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 'Sidi Muhammad Erradi Guennoun', 'Un grand savant et éducateur spirituel.', 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Image_created_with_a_mobile_phone.png/1200px-Image_created_with_a_mobile_phone.png')
ON CONFLICT (id) DO NOTHING;

-- 2. Insert Categories
INSERT INTO categories (id, name_fr, name_ar, slug, icon_name)
VALUES 
    ('c1eebc99-9c0b-4ef8-bb6d-6bb9bd380c11', 'Spiritualité', 'روحانيات', 'spiritualite', 'spa'),
    ('c2eebc99-9c0b-4ef8-bb6d-6bb9bd380c22', 'Science', 'علم', 'science', 'science'),
    ('c3eebc99-9c0b-4ef8-bb6d-6bb9bd380c33', 'Histoire', 'تاريخ', 'histoire', 'history')
ON CONFLICT (id) DO NOTHING;

-- 3. Insert Teachings (Podcasts - Audio)
INSERT INTO teachings (title_fr, title_ar, type, media_url, thumbnail_url, duration_seconds, author_id, category_id, published_at)
VALUES 
    (
        'La purification du cœur', 
        'تزكية النفس', 
        'AUDIO', 
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', 
        'https://images.unsplash.com/photo-1519834785169-98be25ec3f84?auto=format&fit=crop&q=80&w=800', 
        360, -- 6 mins
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 
        'c1eebc99-9c0b-4ef8-bb6d-6bb9bd380c11',
        NOW() - INTERVAL '1 day'
    ),
    (
        'L''importance du savoir', 
        'أهمية العلم', 
        'AUDIO', 
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', 
        'https://images.unsplash.com/photo-1532012197267-da84d127e765?auto=format&fit=crop&q=80&w=800', 
        420, -- 7 mins
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 
        'c2eebc99-9c0b-4ef8-bb6d-6bb9bd380c22',
        NOW() - INTERVAL '2 days'
    ),
    (
        'Histoire des prophètes', 
        'قصص الأنبياء', 
        'AUDIO', 
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', 
        'https://images.unsplash.com/photo-1461360370896-922624d12aa1?auto=format&fit=crop&q=80&w=800', 
        600, -- 10 mins
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 
        'c3eebc99-9c0b-4ef8-bb6d-6bb9bd380c33',
        NOW() - INTERVAL '5 days'
    ),
    (
        'Le bon comportement', 
        'حسن الخلق', 
        'AUDIO', 
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', 
        'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?auto=format&fit=crop&q=80&w=800', 
        300, 
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 
        'c1eebc99-9c0b-4ef8-bb6d-6bb9bd380c11',
        NOW() - INTERVAL '6 days'
    ),
    (
        'Méditation matinale', 
        'أذكار الصباح', 
        'AUDIO', 
        'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', 
        'https://plus.unsplash.com/premium_photo-1664303228186-bea431f081c7?auto=format&fit=crop&q=80&w=800', 
        500, 
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 
        'c1eebc99-9c0b-4ef8-bb6d-6bb9bd380c11',
        NOW() - INTERVAL '1 hour'
    );

-- 4. Insert Teachings (Videos)
INSERT INTO teachings (title_fr, title_ar, type, media_url, thumbnail_url, duration_seconds, author_id, category_id, published_at)
VALUES 
    (
        'Conférence sur la paix', 
        'محاضرة عن السلام', 
        'VIDEO', 
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ', -- Example link
        'https://img.youtube.com/vi/dQw4w9WgXcQ/0.jpg', 
        1200, 
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 
        'c1eebc99-9c0b-4ef8-bb6d-6bb9bd380c11',
        NOW() - INTERVAL '3 weeks'
    ),
    (
        'Lumières de la sagesse', 
        'أنوار الحكمة', 
        'VIDEO', 
        'https://www.youtube.com/watch?v=ScMzIvxBSi4', 
        'https://img.youtube.com/vi/ScMzIvxBSi4/0.jpg', 
        900, 
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 
        'c1eebc99-9c0b-4ef8-bb6d-6bb9bd380c11',
        NOW() - INTERVAL '1 month'
    );

-- 5. Insert Articles
INSERT INTO articles (title_fr, title_ar, content_fr, content_ar, read_time_minutes, author_id, category_id, published_at)
VALUES 
    (
        'Les bienfaits de la patience', 
        'فضائل الصبر', 
        '<h1>La Patience</h1><p>La patience est une vertu essentielle...</p><p>Elle nous permet de surmonter les épreuves.</p>', 
        '<h1>الصبر</h1><p>الصبر ضياء...</p>', 
        5, 
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11', 
        'c1eebc99-9c0b-4ef8-bb6d-6bb9bd380c11',
        NOW()
    );
