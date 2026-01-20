const { supabase } = require('../config/supabase');
const { AuthenticationError } = require('../utils/errors');

/**
 * Middleware pour vérifier l'authentification de l'utilisateur
 * Extrait et vérifie le token JWT de Supabase
 */
const authenticate = async (req, res, next) => {
  try {
    // Récupérer le token de l'en-tête Authorization
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AuthenticationError('Token d\'authentification manquant');
    }

    const token = authHeader.split(' ')[1];

    // Vérifier le token avec Supabase
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      throw new AuthenticationError('Token invalide ou expiré');
    }

    // Attacher l'utilisateur à la requête
    req.user = user;
    req.userId = user.id;

    // Configurer le client Supabase avec le token de l'utilisateur pour RLS
    req.supabase = supabase;

    next();
  } catch (error) {
    if (error instanceof AuthenticationError) {
      next(error);
    } else {
      next(new AuthenticationError('Erreur d\'authentification'));
    }
  }
};

/**
 * Middleware optionnel - authentifie si un token est présent
 */
const optionalAuthenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      const { data: { user }, error } = await supabase.auth.getUser(token);

      if (!error && user) {
        req.user = user;
        req.userId = user.id;
        req.supabase = supabase;
      }
    }

    next();
  } catch (error) {
    // Continuer même en cas d'erreur (authentification optionnelle)
    next();
  }
};

/**
 * Middleware pour vérifier si l'utilisateur est un administrateur
 */
const isAdmin = async (req, res, next) => {
  try {
    if (!req.userId) {
      throw new AuthenticationError('Authentification requise');
    }

    const { data: profile, error } = await req.supabase
      .from('profiles')
      .select('role')
      .eq('id', req.userId)
      .single();

    if (error || !profile || profile.role !== 'ADMIN') {
      throw new AuthenticationError('Accès refusé : Droits administrateur requis');
    }

    next();
  } catch (error) {
    next(error);
  }
};

module.exports = {
  authenticate,
  optionalAuthenticate,
  isAdmin
};
