-- ============================================
-- MIGRATION: 002_silsila_graph
-- DESCRIPTION: Transition from Token Tree to DAG (Multiple Parents)
-- ============================================

-- 1. Add new columns to 'silsilas' table
ALTER TABLE public.silsilas 
ADD COLUMN IF NOT EXISTS is_global BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 2. Create Junction Table for Many-to-Many relationships
-- This allows one person to have multiple spiritual fathers (paths)
CREATE TABLE IF NOT EXISTS public.silsila_relations (
    parent_id UUID NOT NULL REFERENCES public.silsilas(id) ON DELETE CASCADE,
    child_id UUID NOT NULL REFERENCES public.silsilas(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (parent_id, child_id),
    CONSTRAINT no_self_loop CHECK (parent_id != child_id)
);

CREATE INDEX idx_silsila_relations_parent ON public.silsila_relations(parent_id);
CREATE INDEX idx_silsila_relations_child ON public.silsila_relations(child_id);

-- 3. Data Migration (Optional - if preserving existing data)
-- Move existing parent_id relations to the new table
INSERT INTO public.silsila_relations (parent_id, child_id)
SELECT parent_id, id 
FROM public.silsilas 
WHERE parent_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- 4. Clean up (Optional - keep parent_id for a while if backward compatibility needed)
-- ALTER TABLE public.silsilas DROP COLUMN parent_id;

-- 5. Seed Data: Create the Grand Cheikh (if not exists)
INSERT INTO public.silsilas (name, level, is_global, description)
VALUES ('Cheikh Ahmad At Tidiani Cherif', 100, TRUE, 'Le Pôle Caché, Fondateur de la Tariqa')
ON CONFLICT DO NOTHING; -- Note: Needs a unique constraint on name or ID to work effectively
