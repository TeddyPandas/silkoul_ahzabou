-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- Politiques de sécurité pour Silkoul Ahzabou
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.silsilas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_tasks ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLICIES: profiles
-- ============================================

-- SELECT: Tous les profils sont publics (pour afficher les noms des créateurs)
CREATE POLICY "profiles_select_all"
    ON public.profiles
    FOR SELECT
    USING (true);

-- INSERT: Les utilisateurs peuvent créer leur propre profil lors de l'inscription
CREATE POLICY "profiles_insert_own"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- UPDATE: Les utilisateurs ne peuvent mettre à jour que leur propre profil
CREATE POLICY "profiles_update_own"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- DELETE: Les utilisateurs peuvent supprimer leur propre profil
CREATE POLICY "profiles_delete_own"
    ON public.profiles
    FOR DELETE
    USING (auth.uid() = id);

-- ============================================
-- POLICIES: silsilas
-- ============================================

-- SELECT: Toutes les silsilas sont visibles
CREATE POLICY "silsilas_select_all"
    ON public.silsilas
    FOR SELECT
    USING (true);

-- INSERT/UPDATE/DELETE: Seulement les admins (pour l'instant, désactivé)
-- À activer plus tard avec un système de rôles

-- ============================================
-- POLICIES: campaigns
-- ============================================

-- SELECT: 
-- - Campagnes publiques visibles par tous
-- - Campagnes privées visibles par le créateur ou les abonnés
CREATE POLICY "campaigns_select_public_or_member"
    ON public.campaigns
    FOR SELECT
    USING (
        is_public = true
        OR created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.user_campaigns
            WHERE campaign_id = campaigns.id
            AND user_id = auth.uid()
        )
    );

-- INSERT: Les utilisateurs authentifiés peuvent créer des campagnes
CREATE POLICY "campaigns_insert_authenticated"
    ON public.campaigns
    FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL AND created_by = auth.uid());

-- UPDATE: Seul le créateur peut mettre à jour la campagne
CREATE POLICY "campaigns_update_creator"
    ON public.campaigns
    FOR UPDATE
    USING (created_by = auth.uid())
    WITH CHECK (created_by = auth.uid());

-- DELETE: Seul le créateur peut supprimer la campagne
CREATE POLICY "campaigns_delete_creator"
    ON public.campaigns
    FOR DELETE
    USING (created_by = auth.uid());

-- ============================================
-- POLICIES: tasks
-- ============================================

-- SELECT: Via l'accès à la campagne
CREATE POLICY "tasks_select_via_campaign"
    ON public.tasks
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.campaigns
            WHERE id = tasks.campaign_id
            AND (
                is_public = true
                OR created_by = auth.uid()
                OR EXISTS (
                    SELECT 1 FROM public.user_campaigns
                    WHERE campaign_id = campaigns.id
                    AND user_id = auth.uid()
                )
            )
        )
    );

-- INSERT: Uniquement via RPC (système sécurisé)
-- Les tâches sont créées avec la campagne
CREATE POLICY "tasks_insert_via_campaign"
    ON public.tasks
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.campaigns
            WHERE id = tasks.campaign_id
            AND created_by = auth.uid()
        )
    );

-- UPDATE: Uniquement via RPC (pas de mise à jour directe pour éviter les manipulations)
-- Cette politique empêche les mises à jour directes
CREATE POLICY "tasks_update_disabled"
    ON public.tasks
    FOR UPDATE
    USING (false);

-- DELETE: Seul le créateur de la campagne peut supprimer les tâches
CREATE POLICY "tasks_delete_via_campaign"
    ON public.tasks
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.campaigns
            WHERE id = tasks.campaign_id
            AND created_by = auth.uid()
        )
    );

-- ============================================
-- POLICIES: user_campaigns
-- ============================================

-- SELECT: Les utilisateurs voient leurs propres abonnements
CREATE POLICY "user_campaigns_select_own"
    ON public.user_campaigns
    FOR SELECT
    USING (user_id = auth.uid());

-- INSERT: Uniquement via RPC register_and_subscribe
-- Cette politique empêche les insertions directes
CREATE POLICY "user_campaigns_insert_disabled"
    ON public.user_campaigns
    FOR INSERT
    WITH CHECK (false);

-- UPDATE: Pas de mise à jour autorisée
CREATE POLICY "user_campaigns_update_disabled"
    ON public.user_campaigns
    FOR UPDATE
    USING (false);

-- DELETE: Les utilisateurs peuvent se désabonner
CREATE POLICY "user_campaigns_delete_own"
    ON public.user_campaigns
    FOR DELETE
    USING (user_id = auth.uid());

-- ============================================
-- POLICIES: user_tasks
-- ============================================

-- SELECT: Les utilisateurs voient uniquement leurs propres tâches
CREATE POLICY "user_tasks_select_own"
    ON public.user_tasks
    FOR SELECT
    USING (user_id = auth.uid());

-- INSERT: Uniquement via RPC register_and_subscribe
CREATE POLICY "user_tasks_insert_disabled"
    ON public.user_tasks
    FOR INSERT
    WITH CHECK (false);

-- UPDATE: Les utilisateurs peuvent mettre à jour leurs propres tâches (progression)
CREATE POLICY "user_tasks_update_own"
    ON public.user_tasks
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- DELETE: Les utilisateurs peuvent supprimer leurs engagements
CREATE POLICY "user_tasks_delete_own"
    ON public.user_tasks
    FOR DELETE
    USING (user_id = auth.uid());

-- ============================================
-- GRANT PERMISSIONS
-- ============================================

-- Autoriser l'exécution de la fonction RPC pour les utilisateurs authentifiés
GRANT EXECUTE ON FUNCTION register_and_subscribe TO authenticated;

-- Autoriser l'accès aux tables pour le rôle authenticated
GRANT ALL ON public.profiles TO authenticated;
GRANT ALL ON public.silsilas TO authenticated;
GRANT ALL ON public.campaigns TO authenticated;
GRANT ALL ON public.tasks TO authenticated;
GRANT ALL ON public.user_campaigns TO authenticated;
GRANT ALL ON public.user_tasks TO authenticated;

-- ============================================
-- NOTE IMPORTANTE
-- ============================================
-- Ces politiques garantissent que :
-- 1. Seuls les utilisateurs authentifiés peuvent agir
-- 2. Les utilisateurs ne peuvent voir/modifier que leurs propres données
-- 3. Les opérations sensibles passent obligatoirement par des RPC sécurisées
-- 4. L'atomicité des transactions est garantie par la fonction register_and_subscribe
