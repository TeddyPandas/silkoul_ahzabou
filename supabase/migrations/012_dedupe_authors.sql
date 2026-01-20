-- 1. Identify duplicates and merge them
DO $$
DECLARE
    r RECORD;
    primary_id UUID;
BEGIN
    FOR r IN 
        SELECT name
        FROM media_authors
        GROUP BY name
        HAVING COUNT(*) > 1
    LOOP
        -- Pick the first ID as the primary (e.g., the one with most videos or just first created)
        SELECT id INTO primary_id 
        FROM media_authors 
        WHERE name = r.name 
        ORDER BY created_at ASC 
        LIMIT 1;

        -- Update videos to point to primary_id
        UPDATE media_videos 
        SET author_id = primary_id 
        WHERE author_id IN (SELECT id FROM media_authors WHERE name = r.name AND id != primary_id);

        -- Delete the duplicates
        DELETE FROM media_authors 
        WHERE name = r.name AND id != primary_id;
        
        RAISE NOTICE 'Merged authors for name: %', r.name;
    END LOOP;
END $$;

-- 2. Add Unique Constraint to prevent future duplicates
ALTER TABLE media_authors ADD CONSTRAINT media_authors_name_key UNIQUE (name);
