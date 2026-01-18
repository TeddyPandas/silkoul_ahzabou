const scraper = require('../services/media_scraper');

exports.sync = async (req, res) => {
    try {
        // Optional: Allow overriding channel query from body
        // Default inside service is "Cheikh Ahmad Skiredj"
        const channelQuery = req.body.channelQuery;

        console.log(`Received sync request${channelQuery ? ' for ' + channelQuery : ''}`);

        const result = await scraper.syncChannel(channelQuery);

        if (result.success) {
            res.json({
                message: 'Synchronization successful',
                data: result
            });
        } else {
            console.error('Sync failed:', result.error);
            res.status(500).json({
                message: 'Synchronization failed',
                error: result.error
            });
        }
    } catch (err) {
        console.error('Server error during sync:', err);
        res.status(500).json({
            message: 'Internal server error',
            error: err.message
        });
    }
};
