-- ============================================
-- MIGRATION: 008_remove_prophet
-- DESCRIPTION: Remove 'Prophet Muhammad (SAW)' node to make Cheikh Ahmad current root.
-- ============================================

-- 1. Find and Delete the specific Prophet node
-- CASCADE will automatically remove the relation 'Muhammad (SAW) -> Cheikh Ahmad'
DELETE FROM public.silsilas 
WHERE name = 'Prophet Muhammad (SAW)';
