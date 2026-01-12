-- Fonction pour ajouter des tâches à un abonnement existant
-- Utilisé quand un utilisateur veut prendre plus de Juz pour aider

CREATE OR REPLACE FUNCTION add_tasks_to_subscription(
  p_user_id UUID,
  p_campaign_id UUID,
  p_tasks JSONB
) RETURNS VOID AS $$
DECLARE
  v_task JSONB;
  v_task_id UUID;
  v_quantity INT;
  v_remaining INT;
  v_subscription_id UUID;
BEGIN
  -- 1. Vérifier que l'utilisateur est bien abonné
  SELECT id INTO v_subscription_id
  FROM user_campaigns
  WHERE user_id = p_user_id AND campaign_id = p_campaign_id;

  IF v_subscription_id IS NULL THEN
    RAISE EXCEPTION 'User not subscribed to this campaign';
  END IF;

  -- 2. Boucler sur les tâches demandées
  FOR v_task IN SELECT * FROM jsonb_array_elements(p_tasks)
  LOOP
    v_task_id := (v_task->>'task_id')::UUID;
    v_quantity := (v_task->>'quantity')::INT;

    -- Verrouiller la tâche pour update
    SELECT remaining_number INTO v_remaining
    FROM tasks
    WHERE id = v_task_id
    FOR UPDATE;

    IF v_remaining IS NULL THEN
      RAISE EXCEPTION 'Task not found: %', v_task_id;
    END IF;

    IF v_remaining < v_quantity THEN
      RAISE EXCEPTION 'Insufficient quantity for task %', v_task_id;
    END IF;

    -- Créer ou mettre à jour la user_task
    -- Si l'utilisateur avait déjà cette tâche (ex: abandonnée puis reprise?), on gère l'upsert ?
    -- Pour le Coran, c'est généralement des nouveaux Juz.
    -- On fait un INSERT simple, car user_task est unique par (user_id, task_id) ?
    -- Vérifions si une user_task existe déjà
    IF EXISTS (SELECT 1 FROM user_tasks WHERE user_id = p_user_id AND task_id = v_task_id) THEN
        -- Si elle existe déjà, on ajoute à la quantité souscrite (cas rare pour Coran, possible pour Zikr)
        UPDATE user_tasks
        SET subscribed_quantity = subscribed_quantity + v_quantity,
            is_completed = false -- On réouvre si c'était fini ? Discutable. Pour l'aide, oui.
        WHERE user_id = p_user_id AND task_id = v_task_id;
    ELSE
        -- Nouvelle user_task
        INSERT INTO user_tasks (user_id, task_id, subscribed_quantity, completed_quantity, is_completed)
        VALUES (p_user_id, v_task_id, v_quantity, 0, false);
    END IF;

    -- Décrémenter le pool global
    UPDATE tasks
    SET remaining_number = remaining_number - v_quantity
    WHERE id = v_task_id;
    
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
