const { body, param, query, validationResult } = require('express-validator');
const { ValidationError } = require('../utils/errors');

/**
 * Middleware pour gérer les résultats de validation
 */
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    const errorMessages = errors.array().map(err => err.msg).join(', ');
    throw new ValidationError(errorMessages);
  }

  next();
};

/**
 * Validations pour les campagnes
 */
const campaignValidation = {
  create: [
    body('name')
      .trim()
      .notEmpty().withMessage('Le nom de la campagne est requis')
      .isLength({ min: 3, max: 100 }).withMessage('Le nom doit contenir entre 3 et 100 caractères'),

    body('start_date')
      .notEmpty().withMessage('La date de début est requise')
      .isISO8601().withMessage('Format de date invalide'),

    body('end_date')
      .notEmpty().withMessage('La date de fin est requise')
      .isISO8601().withMessage('Format de date invalide')
      .custom((endDate, { req }) => {
        if (new Date(endDate) <= new Date(req.body.start_date)) {
          throw new Error('La date de fin doit être après la date de début');
        }
        return true;
      }),

    body('description')
      .optional()
      .trim()
      .isLength({ max: 500 }).withMessage('La description ne peut pas dépasser 500 caractères'),

    body('category')
      .optional()
      .trim()
      .isLength({ max: 50 }).withMessage('La catégorie ne peut pas dépasser 50 caractères'),

    body('is_public')
      .optional()
      .isBoolean().withMessage('is_public doit être un booléen'),

    body('access_code')
      .optional({ nullable: true, checkFalsy: true }) // Allow null or empty string
      .trim()
      .isLength({ min: 4, max: 20 }).withMessage('Le code d\'accès doit contenir entre 4 et 20 caractères'),

    body('tasks')
      .isArray({ min: 1 }).withMessage('Au moins une tâche est requise')
      .custom((tasks) => {
        for (const task of tasks) {
          if (!task.name || typeof task.name !== 'string') {
            throw new Error('Chaque tâche doit avoir un nom');
          }
          if (!task.total_number || typeof task.total_number !== 'number' || task.total_number <= 0) {
            throw new Error('Chaque tâche doit avoir un nombre total positif');
          }
        }
        return true;
      }),

    handleValidationErrors
  ],

  update: [
    param('id')
      .isUUID().withMessage('ID de campagne invalide'),

    body('name')
      .optional()
      .trim()
      .isLength({ min: 3, max: 100 }).withMessage('Le nom doit contenir entre 3 et 100 caractères'),

    body('description')
      .optional()
      .trim()
      .isLength({ max: 500 }).withMessage('La description ne peut pas dépasser 500 caractères'),

    body('start_date')
      .optional()
      .isISO8601().withMessage('Format de date invalide'),

    body('end_date')
      .optional()
      .isISO8601().withMessage('Format de date invalide'),

    handleValidationErrors
  ]
};

/**
 * Validations pour les souscriptions
 */
const subscriptionValidation = {
  subscribe: [
    body('campaign_id')
      .notEmpty().withMessage('L\'ID de la campagne est requis')
      .isUUID().withMessage('ID de campagne invalide'),

    body('access_code')
      .optional()
      .trim(),

    body('task_subscriptions')
      .isArray({ min: 1 }).withMessage('Au moins une tâche doit être sélectionnée')
      .custom((subscriptions) => {
        for (const sub of subscriptions) {
          if (!sub.task_id || typeof sub.task_id !== 'string') {
            throw new Error('Chaque souscription doit avoir un task_id');
          }
          if (!sub.quantity || typeof sub.quantity !== 'number' || sub.quantity <= 0) {
            throw new Error('Chaque souscription doit avoir une quantité positive');
          }
        }
        return true;
      }),

    handleValidationErrors
  ]
};

/**
 * Validations pour les tâches
 */
const taskValidation = {
  updateProgress: [
    param('id')
      .isUUID().withMessage('ID de tâche utilisateur invalide'),

    body('completed_quantity')
      .notEmpty().withMessage('La quantité complétée est requise')
      .isInt({ min: 0 }).withMessage('La quantité doit être un nombre positif'),

    handleValidationErrors
  ],

  markComplete: [
    param('id')
      .isUUID().withMessage('ID de tâche utilisateur invalide'),

    handleValidationErrors
  ],

  finishTask: [
    param('id')
      .isUUID().withMessage('ID de tâche utilisateur invalide'),

    body('actual_completed_quantity')
      .notEmpty().withMessage('La quantité accomplie est requise')
      .isInt({ min: 0 }).withMessage('La quantité doit être un nombre positif ou zéro'),

    handleValidationErrors
  ]
};

/**
 * Validations pour le profil
 */
const profileValidation = {
  update: [
    body('display_name')
      .optional()
      .trim()
      .isLength({ min: 2, max: 100 }).withMessage('Le nom doit contenir entre 2 et 100 caractères'),

    body('phone')
      .optional()
      .trim()
      .isMobilePhone().withMessage('Numéro de téléphone invalide'),

    body('address')
      .optional()
      .trim()
      .isLength({ max: 200 }).withMessage('L\'adresse ne peut pas dépasser 200 caractères'),

    body('date_of_birth')
      .optional()
      .isISO8601().withMessage('Format de date invalide'),

    handleValidationErrors
  ]
};

/**
 * Validations pour les requêtes de recherche
 */
const searchValidation = {
  campaigns: [
    query('search')
      .optional()
      .trim(),

    query('category')
      .optional()
      .trim(),

    query('is_active')
      .optional()
      .isBoolean().withMessage('is_active doit être un booléen'),

    query('page')
      .optional()
      .isInt({ min: 1 }).withMessage('La page doit être un nombre positif'),

    query('limit')
      .optional()
      .isInt({ min: 1, max: 100 }).withMessage('La limite doit être entre 1 et 100'),

    handleValidationErrors
  ]
};

module.exports = {
  campaignValidation,
  subscriptionValidation,
  taskValidation,
  profileValidation,
  searchValidation,
  handleValidationErrors
};
