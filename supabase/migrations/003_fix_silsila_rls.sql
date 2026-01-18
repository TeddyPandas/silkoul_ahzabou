-- ============================================
-- MIGRATION: 003_fix_silsila_rls
-- DESCRIPTION: Enable RLS Policies for Silsila tables
-- ============================================

-- 1. Enable RLS on tables (if not already acting restricted)
ALTER TABLE public.silsilas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.silsila_relations ENABLE ROW LEVEL SECURITY;

-- 2. Policies for 'silsilas' table
-- READ: Public can read all silsilas
CREATE POLICY "Public can view silsilas" 
ON public.silsilas FOR SELECT 
TO authenticated, anon 
USING (true);

-- INSERT: Authenticated users can create silsilas (e.g., local muqaddams)
-- Note: In a stricter app, we might restrict 'is_global' creation to admins only.
CREATE POLICY "Authenticated users can create silsilas" 
ON public.silsilas FOR INSERT 
TO authenticated 
WITH CHECK (true);

-- UPDATE: Authenticated users can update silsilas (Simplification for now)
-- Ideally: only the creator should update, but we don't have created_by yet.
-- Allowing all authenticated for now to unblock.
CREATE POLICY "Authenticated users can update silsilas" 
ON public.silsilas FOR UPDATE 
TO authenticated 
USING (true);

-- 3. Policies for 'silsila_relations' table
-- READ: Public can read relations
CREATE POLICY "Public can view silsila relations" 
ON public.silsila_relations FOR SELECT 
TO authenticated, anon 
USING (true);

-- INSERT: Authenticated users can link nodes
CREATE POLICY "Authenticated users can create relations" 
ON public.silsila_relations FOR INSERT 
TO authenticated 
WITH CHECK (true);

-- 4. Policies for 'profiles' update (ensure user can update their own silsila_id)
-- Verify existing policy or create one
CREATE POLICY "Users can update their own profile silsila" 
ON public.profiles FOR UPDATE 
TO authenticated 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);
