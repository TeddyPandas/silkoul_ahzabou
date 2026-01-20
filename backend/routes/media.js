const express = require('express');
const router = express.Router();
const mediaController = require('../controllers/media_controller');

const { authenticate, isAdmin } = require('../middleware/auth');

/**
 * @route POST /api/media/sync
 * @desc Trigger manual synchronization of YouTube content
 * @access Private (Admin)
 */
router.post('/sync', authenticate, isAdmin, mediaController.sync);

module.exports = router;
