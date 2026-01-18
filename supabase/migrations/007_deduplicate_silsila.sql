-- ============================================
-- SQL: 007_deduplicate_silsila
-- DESCRIPTION: Deduplicate nodes that have the exact same name (case sensitive or insensitive).
-- This handles the case where users created local nodes that duplicate global nodes.
-- ============================================

DO $$ 
DECLARE 
    r RECORD;
    keeper_id UUID;
    bad_id UUID;
BEGIN
    -- Loop through all names that appear more than once
    FOR r IN 
        SELECT lower(name) as lname, count(*) 
        FROM public.silsilas 
        GROUP BY lower(name) 
        HAVING count(*) > 1
    LOOP
        -- Strategy: 
        -- 1. Prefer Global nodes as 'Keeper'
        -- 2. If multiple globals (unlikely) or no globals, pick the OLDEST one.
        
        -- Identify the KEEPER
        SELECT id INTO keeper_id
        FROM public.silsilas
        WHERE lower(name) = r.lname
        ORDER BY is_global DESC, created_at ASC
        LIMIT 1;

        -- Loop through BAD nodes (same name, but not keeper)
        FOR bad_id IN 
            SELECT id FROM public.silsilas 
            WHERE lower(name) = r.lname AND id != keeper_id
        LOOP
            RAISE NOTICE 'Merging duplicate "%" (Bad: %) into (Keeper: %)', r.lname, bad_id, keeper_id;

            -- 1. Move CHILDREN of bad node to keeper
            -- Update silsila_relations where bad_node is the PARENT
            -- Handle conflicts (if keeper already has that child) by doing nothing (which means we delete the bad relation later via cascade or manually)
            
            -- Simple update might fail on constraint violation, so we use INSERT ON CONFLICT DO NOTHING then DELETE
            INSERT INTO public.silsila_relations (parent_id, child_id)
            SELECT keeper_id, child_id 
            FROM public.silsila_relations 
            WHERE parent_id = bad_id
            ON CONFLICT DO NOTHING;

            -- 2. Move PARENTS of bad node to keeper
            -- Update silsila_relations where bad_node is the CHILD
            INSERT INTO public.silsila_relations (parent_id, child_id)
            SELECT parent_id, keeper_id 
            FROM public.silsila_relations 
            WHERE child_id = bad_id
            ON CONFLICT DO NOTHING;

            -- 3. Delete the bad node
            -- This will CASCADE delete the old relations involving bad_id
            DELETE FROM public.silsilas WHERE id = bad_id;
            
        END LOOP;
    END LOOP;
END $$;
