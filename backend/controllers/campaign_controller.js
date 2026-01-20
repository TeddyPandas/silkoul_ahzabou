const { createClient } = require('@supabase/supabase-js');
const { NotFoundError, ValidationError, AuthorizationError } = require('../utils/errors');
const { successResponse, createdResponse, paginatedResponse } = require('../utils/response');

/**
 * Créer une nouvelle campagne avec ses tâches
 */
const createCampaign = async (req, res) => {
  const { name, description, start_date, end_date, category, is_public, access_code, tasks } = req.body;
  const userId = req.userId;

  // Créer un client Supabase scopé à l'utilisateur pour respecter RLS
  const supabaseUser = createClient(
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

  // Générer une référence unique pour la campagne
  const reference = `${name.toLowerCase().replace(/\s+/g, '-')}-${Date.now()}`;

  console.log(`[createCampaign] Attempting to create campaign for userId: ${userId}`);

  // Créer la campagne
  const { data: campaign, error: campaignError } = await supabaseUser
    .from('campaigns')
    .insert({
      name,
      reference,
      description,
      start_date,
      end_date,
      created_by: userId,
      category,
      is_public: is_public !== undefined ? is_public : true,
      access_code: !is_public ? access_code : null
    })
    .select()
    .single();

  if (campaignError) {
    console.error('[createCampaign] Supabase Error:', campaignError);
    throw new ValidationError(`Erreur lors de la création de la campagne: ${campaignError.message} (Code: ${campaignError.code})`);
  }

  // Créer les tâches associées
  const tasksToInsert = tasks.map(task => ({
    campaign_id: campaign.id,
    name: task.name,
    total_number: task.total_number,
    remaining_number: task.total_number,
    daily_goal: task.daily_goal || null
  }));

  const { data: createdTasks, error: tasksError } = await supabaseUser
    .from('tasks')
    .insert(tasksToInsert)
    .select();

  if (tasksError) {
    // Supprimer la campagne si les tâches échouent
    await supabaseUser.from('campaigns').delete().eq('id', campaign.id);
    throw new ValidationError(`Erreur lors de la création des tâches: ${tasksError.message}`);
  }

  // Retourner la campagne avec ses tâches
  const response = {
    ...campaign,
    tasks: createdTasks
  };

  return createdResponse(res, 'Campagne créée avec succès', response);
};

/**
 * Récupérer toutes les campagnes (publiques ou celles de l'utilisateur)
 */
const getCampaigns = async (req, res) => {
  const { search, category, is_active, page = 1, limit = 20 } = req.query;
  const userId = req.userId;

  console.log(`[getCampaigns] User ID: ${userId || 'Anonymous'}`);

  // Déterminer quel client utiliser
  // - Si utilisateur connecté : Client scopé (avec Authorization header)
  // - Si anonyme : Client public (anon key)
  let supabaseClient;

  if (userId && req.headers.authorization) {
    // Créer un client scopé pour l'utilisateur
    supabaseClient = createClient(
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
  } else {
    // Utiliser le client global (anon) importé depuis la config
    const { supabase } = require('../config/supabase');
    supabaseClient = supabase;
  }

  let query = supabaseClient
    .from('campaigns')
    .select(`
      id, name, reference, description, start_date, end_date, created_by, category, is_public, is_weekly, created_at,
      creator:created_by(id, display_name, avatar_url),
      tasks(id, name, total_number, remaining_number, daily_goal)
    `, { count: 'exact' });

  // Filtrer par campagnes publiques ou créées par l'utilisateur
  // MODIFICATION: On affiche toutes les campagnes (même privées) car elles sont "verrouillées" par code
  // et non cachées.
  // if (userId) {
  //   query = query.or(`is_public.eq.true,created_by.eq.${userId}`);
  // } else {
  //   query = query.eq('is_public', true);
  // }

  // On ne filtre plus sur is_public pour les rendre visibles dans la liste. 
  // La sécurité se fait au moment de l'accès aux détails (getCampaignById).

  // Recherche par nom ou description
  if (search) {
    query = query.or(`name.ilike.%${search}%,description.ilike.%${search}%`);
  }

  // Filtrer par catégorie
  if (category) {
    query = query.eq('category', category);
  }

  // Filtrer par statut actif
  if (is_active === 'true') {
    const now = new Date().toISOString();
    query = query.lte('start_date', now).gte('end_date', now);
  }

  // Pagination
  const offset = (page - 1) * limit;
  query = query.range(offset, offset + limit - 1);

  // Trier par date de création (plus récentes en premier)
  query = query.order('created_at', { ascending: false });

  const { data: campaigns, error, count } = await query;

  if (error) {
    throw new ValidationError(`Erreur lors de la récupération des campagnes: ${error.message}`);
  }

  return paginatedResponse(res, campaigns, {
    page: parseInt(page),
    limit: parseInt(limit),
    total: count
  });
};

/**
 * Récupérer une campagne spécifique par ID
 */
const getCampaignById = async (req, res) => {
  const { id } = req.params;
  const { code } = req.query; // Code d'accès optionnel
  const userId = req.userId;

  // Déterminer quel client utiliser
  let supabaseClient;

  if (userId && req.headers.authorization) {
    supabaseClient = createClient(
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
  } else {
    const { supabase } = require('../config/supabase');
    supabaseClient = supabase;
  }

  // Utiliser le client approprié
  const { data: campaign, error } = await supabaseClient
    .from('campaigns')
    .select(`
      *,
      creator:created_by(id, display_name, avatar_url),
      tasks(id, name, total_number, remaining_number, daily_goal, created_at)
    `)
    .eq('id', id)
    .single();

  if (error || !campaign) {
    throw new NotFoundError('Campagne non trouvée');
  }

  // Vérifier l'accès aux campagnes privées
  if (!campaign.is_public && campaign.created_by !== userId) {
    // 1. Vérifier si l'utilisateur est déjà abonné
    const { data: subscription } = await supabaseAdmin
      .from('user_campaigns')
      .select('id')
      .eq('campaign_id', id)
      .eq('user_id', userId)
      .single();

    if (subscription) {
      // Accès autorisé car abonné
      return successResponse(res, 200, 'Campagne récupérée', campaign);
    }

    // 2. Vérifier si un code d'accès correct est fourni
    if (code && code === campaign.access_code) {
      // Accès autorisé temporairement pour voir les détails (avant souscription)
      return successResponse(res, 200, 'Campagne récupérée (code valide)', campaign);
    }

    // 3. Sinon, accès refusé
    throw new AuthorizationError('Campagne privée : Code d\'accès requis');
  }

  // 4. Enrichir les données avec le nombre de complétions (Calculé via user_tasks)
  if (campaign.tasks && campaign.tasks.length > 0) {
    const taskIds = campaign.tasks.map(t => t.id);

    // On utilise supabaseAdmin pour l'accès global et supabaseClient pour l'accès local (fallback si admin mal configuré)
    const { supabaseAdmin: supabaseAdminClient } = require('../config/supabase');

    // 1. GLOBAL STATS (Try Admin)
    const { data: adminStats, error: adminError } = await supabaseAdminClient
      .from('user_tasks')
      .select('task_id, completed_quantity, is_completed')
      .in('task_id', taskIds)
      .eq('is_completed', true);

    // 2. USER STATS (Fallback/Supplement)
    let userStats = [];
    if (userId && supabaseClient) {
      const { data: myStats, error: myError } = await supabaseClient
        .from('user_tasks')
        .select('task_id, completed_quantity, is_completed')
        .in('task_id', taskIds)
        .eq('is_completed', true);

      if (myStats) userStats = myStats;
      if (myError) console.log('[getCampaignById] User stats error:', myError);
    }

    console.log(`[getCampaignById] Campaign ${id} - Stats Query:`, {
      adminResults: adminStats?.length || 0,
      userResults: userStats.length,
      adminError: adminError?.message
    });

    // 3. MERGE STATS
    const completionMap = {};

    // Process Admin Data
    if (!adminError && adminStats) {
      adminStats.forEach(stat => {
        completionMap[stat.task_id] = (completionMap[stat.task_id] || 0) + 1;
      });
    }

    // Process User Data (Ensure at least my data is counted if Admin failed/blocked)
    // Note: If Admin works, it includes User data. If Admin fails (RLS), it's 0.
    // We can't easily know if Admin "included" User data blindly without IDs.
    // But logically: Global >= Local.

    // Heuristic: Calculate local counts explicitly and override if Global < Local
    const localMap = {};
    userStats.forEach(stat => {
      localMap[stat.task_id] = (localMap[stat.task_id] || 0) + 1;
    });

    // Merge: Key exists in global? Max(global, local). Else set local.
    Object.keys(localMap).forEach(taskId => {
      const globalCount = completionMap[taskId] || 0;
      const localCount = localMap[taskId];
      if (localCount > globalCount) {
        completionMap[taskId] = localCount;
      }
    });

    console.log(`[getCampaignById] Final Completion Map:`, completionMap);

    // Attacher le compte aux tâches
    campaign.tasks = campaign.tasks.map(task => ({
      ...task,
      completed_count: completionMap[task.id] || 0
    }));
  }

  return successResponse(res, 200, 'Campagne récupérée', campaign);
};

/**
 * Mettre à jour une campagne
 */
const updateCampaign = async (req, res) => {
  const { id } = req.params;
  const userId = req.userId;
  const updates = req.body;

  // Client non scopé pour la lecture publique (si nécessaire) ou scopé
  const { supabase } = require('../config/supabase');

  // Client scopé pour l'écriture
  const supabaseUser = createClient(
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

  // Vérifier que l'utilisateur est le créateur
  const { data: campaign } = await supabase
    .from('campaigns')
    .select('created_by')
    .eq('id', id)
    .single();

  if (!campaign) {
    throw new NotFoundError('Campagne non trouvée');
  }

  if (campaign.created_by !== userId) {
    throw new AuthorizationError('Vous n\'êtes pas autorisé à modifier cette campagne');
  }

  // Mettre à jour la campagne
  const { data: updatedCampaign, error } = await supabaseUser
    .from('campaigns')
    .update(updates)
    .eq('id', id)
    .select()
    .single();

  if (error) {
    throw new ValidationError(`Erreur lors de la mise à jour: ${error.message}`);
  }

  return successResponse(res, 200, 'Campagne mise à jour', updatedCampaign);
};

/**
 * Supprimer une campagne
 */
const deleteCampaign = async (req, res) => {
  const { id } = req.params;
  const userId = req.userId;

  // Client scopé pour l'écriture
  const supabaseUser = createClient(
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

  const { supabase } = require('../config/supabase');

  // Vérifier que l'utilisateur est le créateur
  const { data: campaign } = await supabase
    .from('campaigns')
    .select('created_by')
    .eq('id', id)
    .single();

  if (!campaign) {
    throw new NotFoundError('Campagne non trouvée');
  }

  if (campaign.created_by !== userId) {
    throw new AuthorizationError('Vous n\'êtes pas autorisé à supprimer cette campagne');
  }

  // Supprimer la campagne (cascade supprimera les tâches et souscriptions)
  const { error } = await supabaseUser
    .from('campaigns')
    .delete()
    .eq('id', id);

  if (error) {
    throw new ValidationError(`Erreur lors de la suppression: ${error.message}`);
  }

  return successResponse(res, 200, 'Campagne supprimée avec succès');
};

/**
 * Récupérer les campagnes de l'utilisateur (créées et souscrites)
 */
const getUserCampaigns = async (req, res) => {
  const userId = req.userId;
  const { type = 'all' } = req.query; // all, created, subscribed

  // Initialiser le client scopé uniquement si l'utilisateur est connecté
  // Ce endpoint est protégé, donc req.userId devrait être présent
  const supabaseUser = createClient(
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

  let campaigns = [];

  if (type === 'all' || type === 'created') {
    // Campagnes créées par l'utilisateur
    const { data: createdCampaigns, error: createdError } = await supabaseUser
      .from('campaigns')
      .select(`
        *,
        tasks(id, name, total_number, remaining_number, daily_goal),
        subscribers_count:user_campaigns(count)
      `)
      .eq('created_by', userId)
      .order('created_at', { ascending: false });

    if (!createdError) {
      campaigns = campaigns.concat(createdCampaigns.map(c => ({
        ...c,
        relation: 'created',
        subscribers_count: c.subscribers_count?.[0]?.count ?? 0
      })));
    }
  }

  if (type === 'all' || type === 'subscribed') {
    // Campagnes auxquelles l'utilisateur est abonné
    const { data: subscribedCampaigns, error: subscribedError } = await supabaseUser
      .from('user_campaigns')
      .select(`
        campaign:campaigns(
          *,
          creator:created_by(id, display_name, avatar_url),
          tasks(id, name, total_number, remaining_number, daily_goal),
          subscribers_count:user_campaigns(count)
        )
      `)
      .eq('user_id', userId);

    if (!subscribedError && subscribedCampaigns) {
      campaigns = campaigns.concat(
        subscribedCampaigns
          .filter(uc => uc.campaign)
          .map(uc => ({
            ...uc.campaign,
            relation: 'subscribed',
            subscribers_count: uc.campaign.subscribers_count?.[0]?.count ?? 0
          }))
      );
    }
  }

  if (campaigns.length > 0) {
    console.log('[getUserCampaigns] Sample campaign:', JSON.stringify(campaigns[0], null, 2));
  }
  return successResponse(res, 200, 'Campagnes de l\'utilisateur récupérées', campaigns);
};

/**
 * Vérifier si l'utilisateur est abonné à une campagne
 * Endpoint optimisé pour une vérification rapide sans charger toutes les données
 */
const checkSubscription = async (req, res) => {
  const { campaignId } = req.params;
  const userId = req.userId;

  // Créer un client scopé pour l'utilisateur
  const supabaseUser = createClient(
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

  // Vérifier l'existence de la souscription
  // const { data, error } = await supabase
  const { data, error } = await supabaseUser
    .from('user_campaigns')
    .select('id')
    .eq('campaign_id', campaignId)
    .eq('user_id', userId)
    .maybeSingle();

  if (error) {
    throw new ValidationError(`Erreur lors de la vérification de la souscription: ${error.message}`);
  }

  return successResponse(res, 200, 'Statut de souscription vérifié', {
    isSubscribed: data !== null
  });
};

module.exports = {
  createCampaign,
  getCampaigns,
  getCampaignById,
  updateCampaign,
  deleteCampaign,
  getUserCampaigns,
  checkSubscription
};
