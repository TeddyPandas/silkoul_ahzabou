-- 1. Fix incorrect image URLs for existing quizzes
UPDATE quizzes SET image_url = 'assets/images/quizzes/fiqh_thumb.png' WHERE title = 'Les Piliers de l''Islam';
UPDATE quizzes SET image_url = 'assets/images/quizzes/sirah_thumb.png' WHERE title = 'Vie du Prophète (PSL) - Débuts';
UPDATE quizzes SET image_url = 'assets/images/quizzes/tariqa_thumb.png' WHERE title = 'Bases de la Tariqa';

-- 2. Delete unwanted placeholder quizzes (those with example.com URLs)
-- This is a drastic but effective measure if they are duplicates or leftovers
DELETE FROM quizzes WHERE image_url LIKE '%example.com%';

-- 3. Remove existing duplicate quizzes keeping only the oldest one
WITH Duplicates AS (
    SELECT 
        id,
        ROW_NUMBER() OVER (PARTITION BY title, category ORDER BY created_at ASC) as row_num
    FROM quizzes
)
DELETE FROM quizzes
WHERE id IN (
    SELECT id 
    FROM Duplicates 
    WHERE row_num > 1
);

-- 4. Add unique constraint to prevent future duplicates
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'unique_quiz_title_category'
    ) THEN
        ALTER TABLE quizzes ADD CONSTRAINT unique_quiz_title_category UNIQUE (title, category);
    END IF;
END $$;
