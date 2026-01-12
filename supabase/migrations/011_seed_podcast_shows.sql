-- 1. Create a Show for Pr. Erradi
INSERT INTO podcast_shows (id, title_fr, title_ar, description_fr, image_url, author_id)
VALUES (
  'e1111111-1111-1111-1111-111111111111',
  'Les Lumières de la Sagesse',
  'أنوار الحكمة',
  'Une série d''enseignements spirituels profonds par le Professeur Sidi Muhammad Erradi Guennoun.',
  'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b6/Image_created_with_a_mobile_phone.png/1200px-Image_created_with_a_mobile_phone.png', -- Re-using his image for now
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11' -- Pr. Erradi's ID from seed
) ON CONFLICT (id) DO NOTHING;

-- 2. Link existing Audio teachings to this Show
UPDATE teachings
SET podcast_show_id = 'e1111111-1111-1111-1111-111111111111'
WHERE author_id = 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'
AND type = 'AUDIO';
