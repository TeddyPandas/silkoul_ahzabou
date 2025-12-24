const { supabase, supabaseAdmin } = require('../config/supabase');
const { NotFoundError, ValidationError, AuthorizationError } = require('../utils/errors');
const { successResponse, createdResponse, paginatedResponse } = require('../utils/response');

/**
 * Créer une nouvelle campagne avec ses tâches
 */
const createCampaign = async (req, res) => {
  const { name, description, start_date, end_date, category, is_public, access_code, tasks } = req.body;
  const userId = req.userId;

  // Générer une référence unique pour la campagne
  const reference = `${name.toLowerCase().replace(/\s+/g, '-')}-${Date.now()}`;

  // Créer la campagne
  //const { data: campaign, error: campaignError } = await supabase
  const { data: campaign, error: campaignError } = await supabaseAdmin
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
    throw new ValidationError(`Erreur lors de la création de la campagne: ${campaignError.message}`);
  }

  // Créer les tâches associées
  const tasksToInsert = tasks.map(task => ({
    campaign_id: campaign.id,
    name: task.name,
    total_number: task.total_number,
    remaining_number: task.total_number,
    daily_goal: task.daily_goal || null
  }));

  const { data: createdTasks, error: tasksError } = await supabaseAdmin
    .from('tasks')
    .insert(tasksToInsert)
    .select();

  if (tasksError) {
    // Supprimer la campagne si les tâches échouent
    await supabaseAdmin.from('campaigns').delete().eq('id', campaign.id);
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

  // Utiliser supabaseAdmin pour contourner RLS car nous gérons les permissions manuellement ici
  let query = supabaseAdmin
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

  // Utiliser supabaseAdmin pour pouvoir récupérer la campagne même si privée (RLS)
  // afin de vérifier ensuite les permissions applicatives
  const { data: campaign, error } = await supabaseAdmin
    .from('campaigns')
    .select(`
      *,
      creator:created_by(id, display_name, avatar_url, email),
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

  return successResponse(res, 200, 'Campagne récupérée', campaign);
};

/**
 * Mettre à jour une campagne
 */
const updateCampaign = async (req, res) => {
  const { id } = req.params;
  const userId = req.userId;
  const updates = req.body;

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
  const { data: updatedCampaign, error } = await supabaseAdmin
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
  const { error } = await supabaseAdmin
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

  let campaigns = [];

  if (type === 'all' || type === 'created') {
    // Campagnes créées par l'utilisateur
    // const { data: createdCampaigns, error: createdError } = await supabase
    const { data: createdCampaigns, error: createdError } = await supabaseAdmin
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
    // const { data: subscribedCampaigns, error: subscribedError } = await supabase
    const { data: subscribedCampaigns, error: subscribedError } = await supabaseAdmin
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

  // Vérifier l'existence de la souscription
  // const { data, error } = await supabase
  const { data, error } = await supabaseAdmin
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
