const { supabase, supabaseAdmin } = require('../config/supabase');
const { NotFoundError, ValidationError, AuthenticationError } = require('../utils/errors');
const { successResponse, createdResponse } = require('../utils/response');

/**
 * Récupérer le profil de l'utilisateur connecté
 */
const getMyProfile = async (req, res) => {
  const userId = req.userId;

  const { data: profile, error } = await supabase
    .from('profiles')
    .select(`
      *,
      silsila:silsilas(id, name, description, level)
    `)
    .eq('id', userId)
    .single();

  if (error || !profile) {
    throw new NotFoundError('Profil non trouvé');
  }

  return successResponse(res, 200, 'Profil récupéré', profile);
};

/**
 * Récupérer un profil public par ID
 */
const getProfileById = async (req, res) => {
  const { id } = req.params;

  const { data: profile, error } = await supabase
    .from('profiles')
    .select(`
      id,
      display_name,
      avatar_url,
      created_at,
      silsila:silsilas(id, name, level)
    `)
    .eq('id', id)
    .single();

  if (error || !profile) {
    throw new NotFoundError('Profil non trouvé');
  }

  return successResponse(res, 200, 'Profil récupéré', profile);
};

/**
 * Mettre à jour le profil de l'utilisateur
 */
const updateProfile = async (req, res) => {
  const userId = req.userId;
  const updates = req.body;

  // Empêcher la modification de certains champs
  delete updates.id;
  delete updates.email;
  delete updates.created_at;

  const { data: profile, error } = await supabase
    .from('profiles')
    .update(updates)
    .eq('id', userId)
    .select()
    .single();

  if (error) {
    throw new ValidationError(`Erreur lors de la mise à jour du profil: ${error.message}`);
  }

  return successResponse(res, 200, 'Profil mis à jour', profile);
};

/**
 * Créer ou mettre à jour le profil après l'inscription
 */
const createOrUpdateProfile = async (req, res) => {
  const userId = req.userId;
  const { display_name, phone, address, date_of_birth, silsila_id, avatar_url } = req.body;

  // Vérifier si le profil existe déjà
  const { data: existingProfile } = await supabase
    .from('profiles')
    .select('id')
    .eq('id', userId)
    .single();

  let profile;
  let message;

  if (existingProfile) {
    // Mettre à jour le profil existant
    const { data, error } = await supabase
      .from('profiles')
      .update({
        display_name,
        phone,
        address,
        date_of_birth,
        silsila_id,
        avatar_url
      })
      .eq('id', userId)
      .select()
      .single();

    if (error) {
      throw new ValidationError(`Erreur lors de la mise à jour: ${error.message}`);
    }

    profile = data;
    message = 'Profil mis à jour';
  } else {
    // Créer un nouveau profil
    const { data, error } = await supabase
      .from('profiles')
      .insert({
        id: userId,
        display_name,
        phone,
        address,
        date_of_birth,
        silsila_id,
        avatar_url,
        email: req.user.email
      })
      .select()
      .single();

    if (error) {
      throw new ValidationError(`Erreur lors de la création: ${error.message}`);
    }

    profile = data;
    message = 'Profil créé';
  }

  return successResponse(res, 200, message, profile);
};

/**
 * Récupérer toutes les silsilas (chaînes d'initiation)
 */
const getSilsilas = async (req, res) => {
  const { data: silsilas, error } = await supabase
    .from('silsilas')
    .select('*')
    .order('level', { ascending: true });

  if (error) {
    throw new ValidationError(`Erreur lors de la récupération des silsilas: ${error.message}`);
  }

  return successResponse(res, 200, 'Silsilas récupérées', silsilas);
};

/**
 * Créer une nouvelle silsila (admin uniquement)
 */
const createSilsila = async (req, res) => {
  const { name, parent_id, description } = req.body;

  // Calculer le niveau basé sur le parent
  let level = 0;
  if (parent_id) {
    const { data: parent } = await supabase
      .from('silsilas')
      .select('level')
      .eq('id', parent_id)
      .single();

    if (parent) {
      level = parent.level + 1;
    }
  }

  const { data: silsila, error } = await supabase
    .from('silsilas')
    .insert({
      name,
      parent_id,
      level,
      description
    })
    .select()
    .single();

  if (error) {
    throw new ValidationError(`Erreur lors de la création: ${error.message}`);
  }

  return createdResponse(res, 'Silsila créée', silsila);
};

/**
 * Connexion avec email et mot de passe
 */
const loginWithEmail = async (req, res) => {
  const { email, password } = req.body;

  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  });

  if (error) {
    throw new AuthenticationError('Email ou mot de passe incorrect');
  }

  return successResponse(res, 200, 'Connexion réussie', {
    user: data.user,
    session: data.session
  });
};

/**
 * Inscription avec email et mot de passe
 */
const signupWithEmail = async (req, res) => {
  const { email, password, display_name } = req.body;

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        display_name
      }
    }
  });

  if (error) {
    throw new ValidationError(`Erreur lors de l'inscription: ${error.message}`);
  }

  // Créer le profil
  if (data.user) {
    await supabase.from('profiles').insert({
      id: data.user.id,
      email: data.user.email,
      display_name: display_name || email.split('@')[0]
    });
  }

  return createdResponse(res, 'Inscription réussie', {
    user: data.user,
    session: data.session
  });
};

/**
 * Déconnexion
 */
const logout = async (req, res) => {
  const { error } = await supabase.auth.signOut();

  if (error) {
    throw new ValidationError(`Erreur lors de la déconnexion: ${error.message}`);
  }

  return successResponse(res, 200, 'Déconnexion réussie');
};

/**
 * Rafraîchir le token de session
 */
const refreshToken = async (req, res) => {
  const { refresh_token } = req.body;

  const { data, error } = await supabase.auth.refreshSession({
    refresh_token
  });

  if (error) {
    throw new AuthenticationError('Token de rafraîchissement invalide');
  }

  return successResponse(res, 200, 'Token rafraîchi', {
    session: data.session
  });
};

/**
 * Rechercher des utilisateurs
 */
const searchUsers = async (req, res) => {
  const { query, limit = 20 } = req.query;

  let dbQuery = supabase
    .from('profiles')
    .select('id, display_name, avatar_url')
    .limit(limit);

  if (query) {
    dbQuery = dbQuery.or(`display_name.ilike.%${query}%,email.ilike.%${query}%`);
  }

  const { data: users, error } = await dbQuery;

  if (error) {
    throw new ValidationError(`Erreur lors de la recherche: ${error.message}`);
  }

  return successResponse(res, 200, 'Utilisateurs trouvés', users);
};

module.exports = {
  getMyProfile,
  getProfileById,
  updateProfile,
  createOrUpdateProfile,
  getSilsilas,
  createSilsila,
  loginWithEmail,
  signupWithEmail,
  logout,
  refreshToken,
  searchUsers
};
