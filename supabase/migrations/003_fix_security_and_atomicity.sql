-- ============================================
-- MIGRATION: 003_fix_security_and_atomicity.sql
-- ============================================

-- 1. RPC: unsubscribe_campaign
-- Permet de se désabonner atomiquement en restituant les quantités
CREATE OR REPLACE FUNCTION unsubscribe_campaign(
    p_campaign_id UUID
)
RETURNS VOID AS $$
DECLARE
    v_user_id UUID;
    v_subscription_id UUID;
    v_task_record RECORD;
    v_remaining_quantity INTEGER;
BEGIN
    -- Récupérer l'ID de l'utilisateur courant
    v_user_id := auth.uid();
    
    -- Vérifier si l'utilisateur est abonné
    SELECT id INTO v_subscription_id
    FROM public.user_campaigns
    WHERE user_id = v_user_id AND campaign_id = p_campaign_id;

    IF v_subscription_id IS NULL THEN
        RAISE EXCEPTION 'Subscription not found';
    END IF;

    -- Parcourir les tâches utilisateur pour cette campagne
    FOR v_task_record IN 
        SELECT ut.task_id, ut.subscribed_quantity, ut.completed_quantity
        FROM public.user_tasks ut
        JOIN public.tasks t ON ut.task_id = t.id
        WHERE ut.user_id = v_user_id AND t.campaign_id = p_campaign_id
    LOOP
        -- Calculer la quantité à restituer (ce qui n'a pas été fait)
        v_remaining_quantity := v_task_record.subscribed_quantity - v_task_record.completed_quantity;

        -- Si il reste de la quantité à faire, on la remet dans le pot commun
        IF v_remaining_quantity > 0 THEN
            UPDATE public.tasks
            SET remaining_number = remaining_number + v_remaining_quantity
            WHERE id = v_task_record.task_id;
        END IF;
    END LOOP;

    -- Supprimer l'abonnement (la cascade supprimera les user_tasks)
    DELETE FROM public.user_campaigns
    WHERE id = v_subscription_id;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Accorder les droits d'exécution
GRANT EXECUTE ON FUNCTION unsubscribe_campaign(UUID) TO authenticated;


-- 2. TRIGGER: on_auth_user_created
-- Crée automatiquement le profil lors de l'inscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, display_name, created_at, updated_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        NOW(),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer le trigger sur auth.users
-- Note: Cela nécessite des droits superadmin, si cela échoue, l'utilisateur devra le faire via le dashboard
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
