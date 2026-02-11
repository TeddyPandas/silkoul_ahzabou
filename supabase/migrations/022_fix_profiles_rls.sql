-- ============================================
-- FIX: 022_fix_profiles_rls
-- Restore Public Read Access to Profiles
-- Since PII (email/phone) is removed, this is SAFE.
-- This fixes the "Login Loop" by allowing the app to load the Admin Profile.
-- ============================================

-- 1. Ensure RLS is enabled
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. Drop potential conflicting policies
DROP POLICY IF EXISTS "profiles_select_all" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_read_public" ON public.profiles;

-- 3. Re-create Public Read Policy
-- This allows:
--  - App to load current user's profile (fixing the loop)
--  - App to show other users in leaderboards/social
CREATE POLICY "profiles_select_all"
ON public.profiles
FOR SELECT
USING (true);

-- 4. Ensure Update is secure (Owner only)
-- (This might already exist, but safe to re-assert if needed, 
--  otherwise ignore if you have existing update policies)
-- DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
-- CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE USING (auth.uid() = id);
