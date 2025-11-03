const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { authenticate } = require('../middleware/auth');
const { handleValidationErrors } = require('../middleware/validation');
const { catchAsync } = require('../utils/response');
const {
  loginWithEmail,
  signupWithEmail,
  logout,
  refreshToken,
} = require('../controllers/user_controller');

/**
 * @route   POST /api/auth/login
 * @desc    Connexion avec email et mot de passe
 * @access  Public
 */
router.post(
  '/login',
  [
    body('email').isEmail().withMessage('Email invalide'),
    body('password').notEmpty().withMessage('Mot de passe requis'),
    handleValidationErrors,
  ],
  catchAsync(loginWithEmail)
);

/**
 * @route   POST /api/auth/signup
 * @desc    Inscription avec email et mot de passe
 * @access  Public
 */
router.post(
  '/signup',
  [
    body('email').isEmail().withMessage('Email invalide'),
    body('password').isLength({ min: 6 }).withMessage('Le mot de passe doit contenir au moins 6 caractères'),
    body('display_name').optional().trim().isLength({ min: 2 }).withMessage('Le nom doit contenir au moins 2 caractères'),
    handleValidationErrors,
  ],
  catchAsync(signupWithEmail)
);

/**
 * @route   POST /api/auth/logout
 * @desc    Déconnexion
 * @access  Private
 */
router.post('/logout', authenticate, catchAsync(logout));

/**
 * @route   POST /api/auth/refresh
 * @desc    Rafraîchir le token de session
 * @access  Public
 */
router.post(
  '/refresh',
  [
    body('refresh_token').notEmpty().withMessage('Token de rafraîchissement requis'),
    handleValidationErrors,
  ],
  catchAsync(refreshToken)
);

module.exports = router;
