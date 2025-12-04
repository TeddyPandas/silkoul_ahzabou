-- ============================================
-- MIGRATION: 004_update_rls_policies.sql
-- ============================================

-- Modifier la politique tasks_update_disabled pour être moins restrictive
-- On supprime l'ancienne politique
DROP POLICY IF EXISTS "tasks_update_disabled" ON public.tasks;

-- On crée une nouvelle politique qui autorise le créateur de la campagne à modifier
-- uniquement le nom et l'objectif journalier
CREATE POLICY "tasks_update_creator"
    ON public.tasks
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.campaigns
            WHERE id = tasks.campaign_id
            AND created_by = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.campaigns
            WHERE id = tasks.campaign_id
            AND created_by = auth.uid()
        )
    );
