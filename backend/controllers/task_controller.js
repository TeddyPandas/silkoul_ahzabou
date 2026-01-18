const { supabase, supabaseAdmin } = require('../config/supabase'); // Keep admin for now if needed, but we replace usage
const { createClient } = require('@supabase/supabase-js');
const { NotFoundError, ValidationError, AuthorizationError, ConflictError } = require('../utils/errors');
const { successResponse, createdResponse } = require('../utils/response');

// Helper to create scoped client
const createScopedClient = (req) => {
  return createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY,
    {
      global: {
        headers: {
          Authorization: req.headers.authorization
        }
      }
    }
  );
};

/**
 * S'abonner à une campagne avec sélection de tâches
 * Utilise une fonction RPC pour garantir l'atomicité
 */
const subscribeToCampaign = async (req, res) => {
  const { campaign_id, access_code, task_subscriptions } = req.body;
  const userId = req.userId;

  console.log(`[subscribeToCampaign] User ${userId} subscribing to ${campaign_id}`);
  console.log(`[subscribeToCampaign] Payload:`, JSON.stringify(task_subscriptions));

  const supabaseUser = createScopedClient(req);

  // Étape 1: Vérifications préliminaires rapides
  // On utilise le client scopé pour vérifier l'accès (RLS devrait bloquer si privé/sans code, mais on a besoin de vérifier le code manuellement si retourné)
  const { data: campaign, error: campaignError } = await supabaseUser
    .from('campaigns')
    .select('is_public, access_code')
    .eq('id', campaign_id)
    .single();

  if (campaignError || !campaign) {
    console.error('[subscribeToCampaign] Campaign lookup error:', campaignError);
    // Si RLS bloque (ex: privé non créé par user), on peut avoir une erreur.
    // Mais pour s'abonner, la campagne doit être visible.
    // Si c'est privé, l'utilisateur a dû saisir un code pour voir les détails AVANT de s'abonner.
    // Ici on revérifie.
    throw new NotFoundError('Campagne non trouvée ou accès refusé');
  }

  if (!campaign.is_public) {
    if (!access_code || access_code !== campaign.access_code) {
      throw new AuthorizationError('Code d\'accès invalide pour cette campagne privée');
    }
  }

  // Étape 1.5: Nettoyage pré-abonnement (Sanitization)
  if (task_subscriptions && task_subscriptions.length > 0) {
    const taskIds = task_subscriptions.map(t => t.task_id);

    const { data: existingTasks } = await supabaseUser
      .from('user_tasks')
      .select('id, task_id, subscribed_quantity, completed_quantity')
      .eq('user_id', userId)
      .in('task_id', taskIds)
      .eq('is_completed', true);

    if (existingTasks && existingTasks.length > 0) {
      for (const task of existingTasks) {
        if (task.subscribed_quantity > task.completed_quantity) {
          await supabaseUser
            .from('user_tasks')
            .update({ subscribed_quantity: task.completed_quantity })
            .eq('id', task.id);
        }
      }
    }
  }

  // Étape 2: Appeler la fonction RPC pour une transaction atomique
  // Note: RPC call with scoped client ensuring RLS context if needed provided the RPC handles it or is security defeater
  // The RPC 'register_and_subscribe' is SECURITY DEFINER or takes user_id explicitly.
  // We use the authenticated client to call it.
  const { error: rpcError } = await supabaseUser.rpc('register_and_subscribe', {
    p_user_id: userId,
    p_campaign_id: campaign_id,
    p_tasks: task_subscriptions,
  });

  if (rpcError) {
    console.error('[subscribeToCampaign] RPC Error:', rpcError);
    if (rpcError.message.includes('already subscribed')) {
      throw new ConflictError('Vous êtes déjà abonné à cette campagne.');
    }
    if (rpcError.message.includes('not found')) {
      throw new NotFoundError('La campagne ou une des tâches est introuvable.');
    }
    if (rpcError.message.includes('User already subscribed')) {
      throw new ConflictError('Vous êtes déjà abonné à cette campagne.');
    }
    if (rpcError.message.includes('Insufficient quantity')) {
      throw new ValidationError('La quantité demandée pour une tâche est indisponible (Stock insuffisant).');
    }
    // Erreur générique
    throw new ValidationError(`Erreur lors de l'abonnement: ${rpcError.message}`);
  }

  // Étape 3: Retourner une réponse de succès
  if (task_subscriptions && task_subscriptions.length > 0) {
    const taskIds = task_subscriptions.map(t => t.task_id);
    await supabaseUser
      .from('user_tasks')
      .update({ is_completed: false })
      .eq('user_id', userId)
      .in('task_id', taskIds);
  }

  return createdResponse(res, 'Abonnement réussi', { success: true });
};

/**
 * Récupérer les tâches de l'utilisateur
 */
const getUserTasks = async (req, res) => {
  const userId = req.userId;
  const { campaign_id, is_completed } = req.query;
  const supabaseUser = createScopedClient(req);

  let query = supabaseUser
    .from('user_tasks')
    .select(`
      *,
      task:tasks(
        *,
        campaign:campaigns(id, name, start_date, end_date, category)
      )
    `)
    .eq('user_id', userId);

  if (campaign_id) {
    query = query.eq('task.campaign_id', campaign_id);
  }

  if (is_completed !== undefined) {
    query = query.eq('is_completed', is_completed === 'true');
  }

  query = query.order('created_at', { ascending: false });

  const { data: userTasks, error } = await query;

  if (error) {
    throw new ValidationError(`Erreur lors de la récupération des tâches: ${error.message}`);
  }

  return successResponse(res, 200, 'Tâches récupérées', userTasks);
};

/**
 * Mettre à jour le progrès d'une tâche (incrémentiel)
 */
const updateTaskProgress = async (req, res) => {
  const { id } = req.params;
  const { completed_quantity } = req.body;
  const userId = req.userId;
  const supabaseUser = createScopedClient(req);

  console.log(`[updateTaskProgress] TaskId: ${id}, User: ${userId}, Qty: ${completed_quantity}`);

  const { data: userTask, error: fetchError } = await supabaseUser
    .from('user_tasks')
    .select('*, task:tasks(remaining_number)') // Fetch task info too just in case
    .eq('id', id)
    .eq('user_id', userId)
    .single();

  if (fetchError || !userTask) {
    throw new NotFoundError('Tâche non trouvée');
  }

  if (completed_quantity > userTask.subscribed_quantity) {
    throw new ValidationError(
      `La quantité complétée ne peut pas dépasser la quantité souscrite (${userTask.subscribed_quantity})`
    );
  }

  const updates = {
    completed_quantity,
    is_completed: completed_quantity >= userTask.subscribed_quantity
  };

  if (updates.is_completed && !userTask.is_completed) {
    updates.completed_at = new Date().toISOString();
  }

  console.log(`[updateTaskProgress] Updates to apply:`, updates);

  const { data: updatedTask, error: updateError } = await supabaseUser
    .from('user_tasks')
    .update(updates)
    .eq('id', id)
    .eq('user_id', userId)
    .select()
    .single();

  console.log(`[updateTaskProgress] Updated Task Result:`, updatedTask);

  if (updateError) {
    throw new ValidationError(`Erreur lors de la mise à jour: ${updateError.message}`);
  }

  return successResponse(res, 200, 'Progrès mis à jour', updatedTask);
};

/**
 * Marquer une tâche comme complète (système d'honneur)
 */
const markTaskComplete = async (req, res) => {
  const { id } = req.params;
  const userId = req.userId;
  const supabaseUser = createScopedClient(req);

  const { data: userTask, error: fetchError } = await supabaseUser
    .from('user_tasks')
    .select('*')
    .eq('id', id)
    .eq('user_id', userId)
    .single();

  if (fetchError || !userTask) {
    throw new NotFoundError('Tâche non trouvée');
  }

  if (userTask.is_completed) {
    throw new ValidationError('Cette tâche est déjà marquée comme complète');
  }

  const { data: updatedTask, error: updateError } = await supabaseUser
    .from('user_tasks')
    .update({
      is_completed: true,
      completed_quantity: userTask.subscribed_quantity,
      completed_at: new Date().toISOString()
    })
    .eq('id', id)
    .eq('user_id', userId)
    .select()
    .single();

  if (updateError) {
    throw new ValidationError(`Erreur lors de la mise à jour: ${updateError.message}`);
  }

  return successResponse(res, 200, 'Tâche marquée comme complète', updatedTask);
};

/**
 * Récupérer les statistiques des tâches de l'utilisateur
 */
const getUserTaskStats = async (req, res) => {
  const userId = req.userId;
  const supabaseUser = createScopedClient(req);

  const { data: stats, error } = await supabaseUser
    .from('user_tasks')
    .select('subscribed_quantity, completed_quantity, is_completed')
    .eq('user_id', userId);

  if (error) {
    throw new ValidationError(`Erreur lors de la récupération des statistiques: ${error.message}`);
  }

  const totalSubscribed = stats.reduce((sum, task) => sum + task.subscribed_quantity, 0);
  const totalCompleted = stats.reduce((sum, task) => sum + task.completed_quantity, 0);
  const completedTasks = stats.filter(task => task.is_completed).length;
  const totalTasks = stats.length;
  const progressPercentage = totalSubscribed > 0 ? (totalCompleted / totalSubscribed) * 100 : 0;

  return successResponse(res, 200, 'Statistiques récupérées', {
    total_subscribed: totalSubscribed,
    total_completed: totalCompleted,
    completed_tasks: completedTasks,
    total_tasks: totalTasks,
    progress_percentage: Math.round(progressPercentage * 100) / 100
  });
};

/**
 * Se désabonner d'une campagne
 */
const unsubscribeFromCampaign = async (req, res) => {
  const { campaign_id } = req.params;
  const userId = req.userId;
  const supabaseUser = createScopedClient(req);

  // Vérifier que l'utilisateur est abonné
  const { data: subscription, error: fetchError } = await supabaseUser
    .from('user_campaigns')
    .select('id')
    .eq('user_id', userId)
    .eq('campaign_id', campaign_id)
    .single();

  if (fetchError || !subscription) {
    throw new NotFoundError('Abonnement non trouvé');
  }

  // NOTE: Restoration logic requires update permissions on 'tasks' table.
  // RLS policies must allow authenticated users to UPDATE tasks if strictly controlled by RPC/Backend?
  // Or we might need to use a SERVICE ROLE KEY here if restoring global pool needs special permission?
  // For now, let's assume valid RLS or user is creator. If not, this might fail without Admin.
  // Actually, standard users shouldn't update 'tasks' table directly typically.
  // But let's try with user client first. If fails, we might need a dedicated RPC for unsubscribe too.

  // Retrieving user tasks
  const { data: userTasks } = await supabaseUser
    .from('user_tasks')
    .select('*, task:tasks(*)')
    .eq('user_id', userId)
    .eq('task.campaign_id', campaign_id);

  if (userTasks) {
    for (const userTask of userTasks) {
      const remainingQuantity = userTask.subscribed_quantity - userTask.completed_quantity;
      if (remainingQuantity > 0) {
        // Warning: This update might fail if RLS prevents UPDATE on tasks.
        // Ideally this should be an RPC 'unsubscribe_and_restore'
        // FIX: Update using ADMIN client to bypass RLS policies on 'tasks' table
        await supabaseAdmin
          .from('tasks')
          .update({
            remaining_number: userTask.task.remaining_number + remainingQuantity
          })
          .eq('id', userTask.task_id);
      }
    }
  }

  const { error: deleteError } = await supabaseUser
    .from('user_campaigns')
    .delete()
    .eq('id', subscription.id);

  if (deleteError) {
    throw new ValidationError(`Erreur lors du désabonnement: ${deleteError.message}`);
  }

  return successResponse(res, 200, 'Désabonnement réussi');
};

/**
 * Récupérer les tâches souscrites par l'utilisateur pour une campagne spécifique
 */
const getUserTasksForCampaign = async (req, res) => {
  const { campaignId } = req.params;
  const userId = req.userId;
  const supabaseUser = createScopedClient(req);

  const { data: userTasks, error } = await supabaseUser
    .from('user_tasks')
    .select(`
      id,
      task_id,
      subscribed_quantity,
      completed_quantity,
      is_completed,
      task:tasks!inner(campaign_id)
    `)
    .eq('user_id', userId)
    .eq('task.campaign_id', campaignId);

  if (error) {
    throw new ValidationError(`Erreur lors de la récupération des tâches: ${error.message}`);
  }

  const subscribedTasks = (userTasks || []).map(ut => ({
    id: ut.id,
    task_id: ut.task_id,
    subscribed_quantity: ut.subscribed_quantity,
    completed_quantity: ut.completed_quantity,
    is_completed: ut.is_completed
  }));

  return successResponse(res, 200, 'Tâches souscrites récupérées', subscribedTasks);
};

/**
 * Terminer une tâche avec retour du reste au pool global
 */
const finishTask = async (req, res) => {
  const { id } = req.params;
  const { actual_completed_quantity } = req.body;
  const userId = req.userId;
  const supabaseUser = createScopedClient(req);

  if (actual_completed_quantity === undefined || actual_completed_quantity === null) {
    throw new ValidationError('La quantité accomplie est requise');
  }

  if (actual_completed_quantity < 0) {
    throw new ValidationError('La quantité accomplie ne peut pas être négative');
  }

  const { data: userTask, error: fetchError } = await supabaseUser
    .from('user_tasks')
    .select(`
      *,
      task:tasks(id, remaining_number, campaign_id)
    `)
    .eq('id', id)
    .eq('user_id', userId)
    .single();

  if (fetchError || !userTask) {
    throw new NotFoundError('Tâche non trouvée');
  }

  if (userTask.is_completed) {
    throw new ValidationError('Cette tâche est déjà terminée');
  }

  if (actual_completed_quantity > userTask.subscribed_quantity) {
    throw new ValidationError(
      `La quantité accomplie (${actual_completed_quantity}) ne peut pas dépasser la quantité souscrite (${userTask.subscribed_quantity})`
    );
  }

  const returnedQuantity = userTask.subscribed_quantity - actual_completed_quantity;

  if (returnedQuantity > 0) {
    const newRemaining = userTask.task.remaining_number + returnedQuantity;
    // FIX: Update using ADMIN client to bypass RLS policies on 'tasks' table
    const { error: taskUpdateError } = await supabaseAdmin
      .from('tasks')
      .update({ remaining_number: newRemaining })
      .eq('id', userTask.task_id);

    if (taskUpdateError) {
      throw new ValidationError(`Erreur lors de la mise à jour du pool: ${taskUpdateError.message}`);
    }
  }

  const { data: updatedUserTask, error: updateError } = await supabaseUser
    .from('user_tasks')
    .update({
      completed_quantity: actual_completed_quantity,
      subscribed_quantity: actual_completed_quantity,
      is_completed: true,
      completed_at: new Date().toISOString()
    })
    .eq('id', id)
    .eq('user_id', userId)
    .select()
    .single();

  if (updateError) {
    throw new ValidationError(`Erreur lors de la mise à jour de la tâche: ${updateError.message}`);
  }

  return successResponse(res, 200, 'Tâche terminée avec succès', {
    user_task: updatedUserTask,
    returned_to_pool: returnedQuantity
  });
};

/**
 * Ajouter des tâches à un abonnement existant (Pour "Aider" / "Prendre plus")
 */
const addTasksToSubscription = async (req, res) => {
  const { campaign_id, task_subscriptions } = req.body;
  const userId = req.userId;
  const supabaseUser = createScopedClient(req);

  // Validation basique
  if (!task_subscriptions || task_subscriptions.length === 0) {
    throw new ValidationError("Aucune tâche sélectionnée.");
  }

  // Appel RPC sécurisé (Security Definer)
  const { data, error } = await supabaseUser.rpc('add_tasks_to_subscription', {
    p_user_id: userId,
    p_campaign_id: campaign_id,
    p_tasks: task_subscriptions
  });

  if (error) {
    console.error('RPC Error details:', error);
    throw new ValidationError(`Erreur lors de l'ajout: ${error.message}`);
  }

  return successResponse(res, 200, 'Tâches ajoutées avec succès', { added: task_subscriptions.length });
};

module.exports = {
  subscribeToCampaign,
  addTasksToSubscription,
  getUserTasks,
  updateTaskProgress,
  markTaskComplete,
  getUserTaskStats,
  unsubscribeFromCampaign,
  getUserTasksForCampaign,
  finishTask
};

