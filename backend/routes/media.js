const express = require('express');
const router = express.Router();
const mediaController = require('../controllers/media_controller');

/**
 * @route POST /api/media/sync
 * @desc Trigger manual synchronization of YouTube content
 * @access Public (should be secured in production)
 */
router.post('/sync', mediaController.sync);

module.exports = router;
