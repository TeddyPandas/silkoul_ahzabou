/**
 * Fonctions utilitaires pour standardiser les réponses API
 */

/**
 * Réponse de succès standard
 * @param {object} res - Objet response Express
 * @param {number} statusCode - Code de statut HTTP
 * @param {string} message - Message de succès
 * @param {object} data - Données à retourner
 */
const successResponse = (res, statusCode = 200, message = 'Succès', data = null) => {
  const response = {
    status: 'success',
    message
  };

  if (data !== null) {
    response.data = data;
  }

  return res.status(statusCode).json(response);
};

/**
 * Réponse de succès pour la création
 */
const createdResponse = (res, message = 'Créé avec succès', data = null) => {
  return successResponse(res, 201, message, data);
};

/**
 * Réponse de succès sans contenu
 */
const noContentResponse = (res) => {
  return res.status(204).send();
};

/**
 * Réponse avec pagination
 */
const paginatedResponse = (res, data, pagination) => {
  return res.status(200).json({
    status: 'success',
    data,
    pagination: {
      page: pagination.page,
      limit: pagination.limit,
      total: pagination.total,
      totalPages: Math.ceil(pagination.total / pagination.limit)
    }
  });
};

/**
 * Wrapper async pour gérer les erreurs dans les routes
 */
const catchAsync = (fn) => {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};

module.exports = {
  successResponse,
  createdResponse,
  noContentResponse,
  paginatedResponse,
  catchAsync
};
