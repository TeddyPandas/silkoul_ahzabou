const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { subscriptionValidation, taskValidation } = require('../middleware/validation');
const { catchAsync } = require('../utils/response');
const {
  subscribeToCampaign,
  getUserTasks,
  updateTaskProgress,
  markTaskComplete,
  getUserTaskStats,
  unsubscribeFromCampaign,
  getUserTasksForCampaign,
  finishTask
} = require('../controllers/task_controller');

/**
 * @route   POST /api/tasks/subscribe
 * @desc    S'abonner à une campagne avec sélection de tâches
 * @access  Private
 */
router.post(
  '/subscribe',
  authenticate,
  subscriptionValidation.subscribe,
  catchAsync(subscribeToCampaign)
);

/**
 * @route   GET /api/tasks
 * @desc    Récupérer les tâches de l'utilisateur
 * @access  Private
 */
router.get(
  '/',
  authenticate,
  catchAsync(getUserTasks)
);

/**
 * @route   GET /api/tasks/stats
 * @desc    Récupérer les statistiques des tâches de l'utilisateur
 * @access  Private
 */
router.get(
  '/stats',
  authenticate,
  catchAsync(getUserTaskStats)
);

/**
 * @route   PUT /api/tasks/:id/progress
 * @desc    Mettre à jour le progrès d'une tâche (incrémentiel)
 * @access  Private
 */
router.put(
  '/:id/progress',
  authenticate,
  taskValidation.updateProgress,
  catchAsync(updateTaskProgress)
);

/**
 * @route   PUT /api/tasks/:id/complete
 * @desc    Marquer une tâche comme complète
 * @access  Private
 */
router.put(
  '/:id/complete',
  authenticate,
  taskValidation.markComplete,
  catchAsync(markTaskComplete)
);

/**
 * @route   PUT /api/tasks/:id/finish
 * @desc    Terminer une tâche et retourner le reste au pool global
 * @access  Private
 */
router.put(
  '/:id/finish',
  authenticate,
  taskValidation.finishTask,
  catchAsync(finishTask)
);

/**
 * @route   DELETE /api/tasks/unsubscribe/:campaign_id
 * @desc    Se désabonner d'une campagne
 * @access  Private
 */
router.delete(
  '/unsubscribe/:campaign_id',
  authenticate,
  catchAsync(unsubscribeFromCampaign)
);

/**
 * @route   GET /api/tasks/campaign/:campaignId/my-subscriptions
 * @desc    Récupérer les tâches souscrites par l'utilisateur pour une campagne
 * @access  Private
 */
router.get(
  '/campaign/:campaignId/my-subscriptions',
  authenticate,
  catchAsync(getUserTasksForCampaign)
);

module.exports = router;


