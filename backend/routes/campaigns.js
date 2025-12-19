const express = require('express');
const router = express.Router();
const { authenticate, optionalAuthenticate } = require('../middleware/auth');
const { campaignValidation, searchValidation } = require('../middleware/validation');
const { catchAsync } = require('../utils/response');
const {
  createCampaign,
  getCampaigns,
  getCampaignById,
  updateCampaign,
  deleteCampaign,
  getUserCampaigns,
  checkSubscription
} = require('../controllers/campaign_controller');

/**
 * @route   POST /api/campaigns
 * @desc    Créer une nouvelle campagne
 * @access  Private
 */
router.post(
  '/',
  authenticate,
  campaignValidation.create,
  catchAsync(createCampaign)
);

/**
 * @route   GET /api/campaigns
 * @desc    Récupérer toutes les campagnes (publiques + créées par l'utilisateur)
 * @access  Public/Private (optionnel)
 */
router.get(
  '/',
  optionalAuthenticate,
  searchValidation.campaigns,
  catchAsync(getCampaigns)
);

/**
 * @route   GET /api/campaigns/my
 * @desc    Récupérer les campagnes de l'utilisateur (créées et souscrites)
 * @access  Private
 */
router.get(
  '/my',
  authenticate,
  catchAsync(getUserCampaigns)
);

/**
 * @route   GET /api/campaigns/:campaignId/subscription
 * @desc    Vérifier si l'utilisateur est abonné à une campagne
 * @access  Private
 */
router.get(
  '/:campaignId/subscription',
  authenticate,
  catchAsync(checkSubscription)
);

/**
 * @route   GET /api/campaigns/:id
 * @desc    Récupérer une campagne spécifique
 * @access  Public/Private
 */
router.get(
  '/:id',
  optionalAuthenticate,
  catchAsync(getCampaignById)
);

/**
 * @route   PUT /api/campaigns/:id
 * @desc    Mettre à jour une campagne
 * @access  Private (créateur uniquement)
 */
router.put(
  '/:id',
  authenticate,
  campaignValidation.update,
  catchAsync(updateCampaign)
);

/**
 * @route   DELETE /api/campaigns/:id
 * @desc    Supprimer une campagne
 * @access  Private (créateur uniquement)
 */
router.delete(
  '/:id',
  authenticate,
  catchAsync(deleteCampaign)
);

module.exports = router;
