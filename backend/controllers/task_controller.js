const { supabase, supabaseAdmin } = require('../config/supabase');
const { NotFoundError, ValidationError, AuthorizationError, ConflictError } = require('../utils/errors');
const { successResponse, createdResponse } = require('../utils/response');

/**
 * S'abonner à une campagne avec sélection de tâches
 * Utilise une fonction RPC pour garantir l'atomicité
 */
const subscribeToCampaign = async (req, res) => {
  const { campaign_id, access_code, task_subscriptions } = req.body;
  const userId = req.userId;

  // Étape 1: Vérifications préliminaires rapides
  const { data: campaign, error: campaignError } = await supabase
    .from('campaigns')
    .select('is_public, access_code')
    .eq('id', campaign_id)
    .single();

  if (campaignError || !campaign) {
    throw new NotFoundError('Campagne non trouvée');
  }

  if (!campaign.is_public) {
    if (!access_code || access_code !== campaign.access_code) {
      throw new AuthorizationError('Code d\'accès invalide pour cette campagne privée');
    }
  }

  // Étape 2: Appeler la fonction RPC pour une transaction atomique
  // La RPC gère la logique complexe:
  // - Vérifie si l'utilisateur est déjà abonné
  // - Vérifie la disponibilité des quantités pour chaque tâche
  // - Crée l'enregistrement user_campaigns
  // - Crée les enregistrements user_tasks
  // - Décrémente les quantités restantes sur les tâches
  // - Annule tout en cas d'erreur (rollback)
  const { error: rpcError } = await supabase.rpc('register_and_subscribe', {
    p_user_id: userId,
    p_campaign_id: campaign_id,
    p_tasks: task_subscriptions,
  });

  if (rpcError) {
    // Traduire les erreurs de la base de données en erreurs HTTP claires
    if (rpcError.message.includes('already subscribed')) {
      throw new ConflictError('Vous êtes déjà abonné à cette campagne.');
    }
    if (rpcError.message.includes('not found')) {
      throw new NotFoundError('La campagne ou une des tâches est introuvable.');
    }
    if (rpcError.message.includes('Insufficient quantity')) {
      throw new ValidationError('La quantité demandée pour une tâche est indisponible.');
    }
    // Erreur générique si non reconnue
    throw new ValidationError(`Erreur lors de l'abonnement: ${rpcError.message}`);
  }

  // Étape 3: Retourner une réponse de succès
  // Les données détaillées ne sont pas retournées par la RPC, 
  // mais on confirme que l'opération a réussi.
  return createdResponse(res, 'Abonnement à la campagne réussi.');
};

/**
 * Récupérer les tâches de l'utilisateur
 */
const getUserTasks = async (req, res) => {
  const userId = req.userId;
  const { campaign_id, is_completed } = req.query;

  let query = supabase
    .from('user_tasks')
    .select(`
      *,
      task:tasks(
        *,
        campaign:campaigns(id, name, start_date, end_date, category)
      )
    `)
    .eq('user_id', userId);

  // Filtrer par campagne si spécifié
  if (campaign_id) {
    query = query.eq('task.campaign_id', campaign_id);
  }

  // Filtrer par statut de complétion
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

  // Récupérer la tâche utilisateur
  const { data: userTask, error: fetchError } = await supabase
    .from('user_tasks')
    .select('*')
    .eq('id', id)
    .eq('user_id', userId)
    .single();

  if (fetchError || !userTask) {
    throw new NotFoundError('Tâche non trouvée');
  }

  // Vérifier que la nouvelle quantité ne dépasse pas la quantité souscrite
  if (completed_quantity > userTask.subscribed_quantity) {
    throw new ValidationError(
      `La quantité complétée ne peut pas dépasser la quantité souscrite (${userTask.subscribed_quantity})`
    );
  }

  // Mettre à jour la tâche
  const updates = {
    completed_quantity,
    is_completed: completed_quantity >= userTask.subscribed_quantity
  };

  if (updates.is_completed && !userTask.is_completed) {
    updates.completed_at = new Date().toISOString();
  }

  const { data: updatedTask, error: updateError } = await supabase
    .from('user_tasks')
    .update(updates)
    .eq('id', id)
    .eq('user_id', userId)
    .select()
    .single();

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

  // Récupérer la tâche utilisateur
  const { data: userTask, error: fetchError } = await supabase
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

  // Marquer comme complète
  const { data: updatedTask, error: updateError } = await supabase
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

  // Statistiques globales
  const { data: stats, error } = await supabase
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

  // Vérifier que l'utilisateur est abonné
  const { data: subscription, error: fetchError } = await supabase
    .from('user_campaigns')
    .select('id')
    .eq('user_id', userId)
    .eq('campaign_id', campaign_id)
    .single();

  if (fetchError || !subscription) {
    throw new NotFoundError('Abonnement non trouvé');
  }

  // Récupérer les user_tasks pour remettre les quantités dans les tâches
  const { data: userTasks } = await supabase
    .from('user_tasks')
    .select('*, task:tasks(*)')
    .eq('user_id', userId)
    .eq('task.campaign_id', campaign_id);

  // Remettre les quantités non complétées dans les tâches
  if (userTasks) {
    for (const userTask of userTasks) {
      const remainingQuantity = userTask.subscribed_quantity - userTask.completed_quantity;
      
      if (remainingQuantity > 0) {
        await supabase
          .from('tasks')
          .update({
            remaining_number: userTask.task.remaining_number + remainingQuantity
          })
          .eq('id', userTask.task_id);
      }
    }
  }

  // Supprimer l'abonnement (cascade supprimera les user_tasks)
  const { error: deleteError } = await supabase
    .from('user_campaigns')
    .delete()
    .eq('id', subscription.id);

  if (deleteError) {
    throw new ValidationError(`Erreur lors du désabonnement: ${deleteError.message}`);
  }

  return successResponse(res, 200, 'Désabonnement réussi');
};

module.exports = {
  subscribeToCampaign,
  getUserTasks,
  updateTaskProgress,
  markTaskComplete,
  getUserTaskStats,
  unsubscribeFromCampaign
};
