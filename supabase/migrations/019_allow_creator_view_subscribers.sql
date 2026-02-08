-- ============================================
-- Migration 019: Allow campaign creators to see subscribers
-- FIXED VERSION - Avoids infinite recursion
-- ============================================

-- First, drop the policies if they exist (from previous attempt)
DROP POLICY IF EXISTS "user_campaigns_select_creator" ON public.user_campaigns;
DROP POLICY IF EXISTS "user_tasks_select_creator" ON public.user_tasks;

-- Create a helper function to check if user is campaign creator
-- Using SECURITY DEFINER to bypass RLS in the check
CREATE OR REPLACE FUNCTION public.is_campaign_creator(p_campaign_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM campaigns 
        WHERE id = p_campaign_id 
        AND created_by = auth.uid()
    );
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.is_campaign_creator(UUID) TO authenticated;

-- Now create the policy using the helper function
CREATE POLICY "user_campaigns_select_creator"
    ON public.user_campaigns
    FOR SELECT
    USING (
        user_id = auth.uid() 
        OR public.is_campaign_creator(campaign_id)
    );

-- Drop the old policy that only allowed own subscriptions
DROP POLICY IF EXISTS "user_campaigns_select_own" ON public.user_campaigns;

-- For user_tasks, create similar helper function
CREATE OR REPLACE FUNCTION public.is_task_campaign_creator(p_task_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM tasks t
        JOIN campaigns c ON c.id = t.campaign_id
        WHERE t.id = p_task_id 
        AND c.created_by = auth.uid()
    );
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.is_task_campaign_creator(UUID) TO authenticated;

-- Create the policy for user_tasks
CREATE POLICY "user_tasks_select_creator"
    ON public.user_tasks
    FOR SELECT
    USING (
        user_id = auth.uid() 
        OR public.is_task_campaign_creator(task_id)
    );

-- Drop the old policy that only allowed own tasks
DROP POLICY IF EXISTS "user_tasks_select_own" ON public.user_tasks;
