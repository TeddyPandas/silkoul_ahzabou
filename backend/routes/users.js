const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { authenticate, isAdmin } = require('../middleware/auth');
const { profileValidation, handleValidationErrors } = require('../middleware/validation');
const { catchAsync } = require('../utils/response');
const {
  getMyProfile,
  getProfileById,
  updateProfile,
  createOrUpdateProfile,
  getSilsilas,
  createSilsila,
  searchUsers
} = require('../controllers/user_controller');



// ==================== Routes de profil ====================

/**
 * @route   GET /api/users/me
 * @desc    Récupérer le profil de l'utilisateur connecté
 * @access  Private
 */
router.get(
  '/me',
  authenticate,
  catchAsync(getMyProfile)
);

/**
 * @route   PUT /api/users/me
 * @desc    Mettre à jour le profil de l'utilisateur
 * @access  Private
 */
router.put(
  '/me',
  authenticate,
  profileValidation.update,
  catchAsync(updateProfile)
);

/**
 * @route   POST /api/users/profile
 * @desc    Créer ou mettre à jour le profil complet
 * @access  Private
 */
router.post(
  '/profile',
  authenticate,
  [
    body('display_name')
      .notEmpty().withMessage('Le nom est requis')
      .trim()
      .isLength({ min: 2, max: 100 }).withMessage('Le nom doit contenir entre 2 et 100 caractères'),
    body('phone')
      .optional()
      .trim()
      .isMobilePhone().withMessage('Numéro de téléphone invalide'),
    body('address')
      .optional()
      .trim(),
    body('date_of_birth')
      .optional()
      .isISO8601().withMessage('Format de date invalide'),
    body('silsila_id')
      .optional()
      .isUUID().withMessage('ID de silsila invalide'),
    handleValidationErrors
  ],
  catchAsync(createOrUpdateProfile)
);

/**
 * @route   GET /api/users/:id
 * @desc    Récupérer un profil public par ID
 * @access  Public
 */
router.get(
  '/:id',
  catchAsync(getProfileById)
);

/**
 * @route   GET /api/users/search
 * @desc    Rechercher des utilisateurs
 * @access  Public
 */
router.get(
  '/search',
  catchAsync(searchUsers)
);

// ==================== Routes Silsila ====================

/**
 * @route   GET /api/users/silsilas
 * @desc    Récupérer toutes les silsilas
 * @access  Public
 */
router.get(
  '/silsilas',
  catchAsync(getSilsilas)
);


/**
 * @route   POST /api/users/silsilas
 * @desc    Créer une nouvelle silsila
 * @access  Private (Admin)
 */
router.post(
  '/silsilas',
  authenticate,
  isAdmin,
  [
    body('name')
      .notEmpty().withMessage('Le nom de la silsila est requis')
      .trim(),
    body('parent_id')
      .optional()
      .isUUID().withMessage('ID parent invalide'),
    body('description')
      .optional()
      .trim(),
    handleValidationErrors
  ],
  catchAsync(createSilsila)
);

module.exports = router;
