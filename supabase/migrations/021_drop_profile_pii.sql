-- ============================================
-- MIGRATION: 021_drop_profile_pii
-- Remove Email and Phone from public profiles table
-- Data is already secure in auth.users
-- ============================================

-- 1. Drop indexes first
DROP INDEX IF EXISTS public.idx_profiles_email;

-- 2. Drop columns
ALTER TABLE public.profiles
DROP COLUMN email,
DROP COLUMN phone;
