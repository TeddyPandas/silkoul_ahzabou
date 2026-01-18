-- ============================================
-- MIGRATION: 006_enable_silsila_delete
-- DESCRIPTION: Enable DELETE operations for authenticated users (with safeguards)
-- ============================================

-- 1. Policy for 'silsilas' (Nodes)
-- Allow deletion ONLY if the node is NOT global (protecting Seed Data)
DROP POLICY IF EXISTS "Authenticated users can delete local silsilas" ON public.silsilas;
CREATE POLICY "Authenticated users can delete local silsilas" 
ON public.silsilas FOR DELETE 
TO authenticated 
USING (is_global = FALSE);

-- 2. Policy for 'silsila_relations' (Edges)
-- Allow deletion of any relation (links/edges)
-- This allows unlinking nodes without deleting the nodes themselves.
DROP POLICY IF EXISTS "Authenticated users can delete relations" ON public.silsila_relations;
CREATE POLICY "Authenticated users can delete relations" 
ON public.silsila_relations FOR DELETE 
TO authenticated 
USING (true);
