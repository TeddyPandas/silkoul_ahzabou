-- ============================================
-- FIX: Make register_and_subscribe SECURITY DEFINER
-- This allows the function to bypass RLS policies (specifically the one blocking inserts on user_campaigns)
-- ============================================

CREATE OR REPLACE FUNCTION register_and_subscribe(
    p_user_id UUID,
    p_campaign_id UUID,
    p_tasks JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER -- <--- CRITICAL CHANGE: Run with privileges of the creator (postgres/admin)
SET search_path = public -- Secure search path
AS $$
DECLARE
    task_item JSONB;
    task_uuid UUID;
    task_quantity INTEGER;
    current_remaining INTEGER;
BEGIN
    -- 1. Vérifier que la campagne existe
    IF NOT EXISTS (SELECT 1 FROM public.campaigns WHERE id = p_campaign_id) THEN
        RAISE EXCEPTION 'Campaign not found';
    END IF;

    -- 2. Vérifier que l'utilisateur n'est pas déjà abonné
    IF EXISTS (
        SELECT 1 FROM public.user_campaigns 
        WHERE user_id = p_user_id AND campaign_id = p_campaign_id
    ) THEN
        RAISE EXCEPTION 'User already subscribed to this campaign';
    END IF;

    -- 3. Créer l'entrée user_campaigns
    -- This works now because SECURITY DEFINER bypasses the "CHECK (false)" RLS policy
    INSERT INTO public.user_campaigns (user_id, campaign_id)
    VALUES (p_user_id, p_campaign_id);

    -- 4. Traiter chaque tâche sélectionnée
    FOR task_item IN SELECT * FROM jsonb_array_elements(p_tasks)
    LOOP
        task_uuid := (task_item->>'task_id')::UUID;
        task_quantity := (task_item->>'quantity')::INTEGER;

        -- Vérifier que la tâche existe et appartient à la campagne
        SELECT remaining_number INTO current_remaining
        FROM public.tasks
        WHERE id = task_uuid AND campaign_id = p_campaign_id
        FOR UPDATE; -- Lock pour éviter race conditions

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Task not found or does not belong to campaign';
        END IF;

        -- Vérifier qu'il reste assez de quantité disponible
        IF current_remaining < task_quantity THEN
            RAISE EXCEPTION 'Not enough remaining quantity for task %', task_uuid;
        END IF;

        -- Décrémenter atomiquement le remaining_number
        UPDATE public.tasks
        SET remaining_number = remaining_number - task_quantity
        WHERE id = task_uuid;

        -- Créer l'entrée user_tasks
        INSERT INTO public.user_tasks (
            user_id, 
            task_id, 
            subscribed_quantity
        )
        VALUES (
            p_user_id,
            task_uuid,
            task_quantity
        );
    END LOOP;

    -- 5. Ajouter des points à l'utilisateur
    UPDATE public.profiles
    SET points = points + 10
    WHERE id = p_user_id;

END;
$$;
