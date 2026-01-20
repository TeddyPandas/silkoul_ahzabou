const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const { errorHandler, notFoundHandler } = require('./utils/errors');

// Import des routes
const campaignRoutes = require('./routes/campaigns');
const taskRoutes = require('./routes/tasks');
const userRoutes = require('./routes/users');
const authRoutes = require('./routes/auth');
const mediaRoutes = require('./routes/media');

// Initialiser Express
const app = express();

// Configuration du port
const PORT = process.env.PORT || 3000;

// ==================== Middlewares ====================

// Sécurité avec Helmet
app.use(helmet());

// CORS
// CORS
const allowedOrigins = [
  'http://localhost:3000',
  'http://localhost:5000',
  'http://localhost:8080',
  /\.vercel\.app$/, // Example for web deployment
];

app.use(cors({
  origin: (origin, callback) => {
    // allow requests with no origin (like mobile apps or curl requests)
    if (!origin) return callback(null, true);
    if (allowedOrigins.some(ao => (typeof ao === 'string' ? ao === origin : ao.test(origin)))) {
      return callback(null, true);
    }
    return callback(new Error('CORS Policy: Access denied'), false);
  },
  credentials: true,
  optionsSuccessStatus: 200
}));

// Body parser
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logger (uniquement en développement)
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// ==================== Routes ====================

// Route de santé
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Silkoul Ahzabou Tidiani API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Route d'information
app.get('/', (req, res) => {
  res.status(200).json({
    name: 'Silkoul Ahzabou Tidiani API',
    version: '1.0.0',
    description: 'Backend API pour la gestion des campagnes de Zikr',
    endpoints: {
      health: '/health',
      campaigns: '/api/campaigns',
      tasks: '/api/tasks',
      users: '/api/users'
    }
  });
});

// Routes principales
app.use('/api/auth', authRoutes);
app.use('/api/campaigns', campaignRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/users', userRoutes);
app.use('/api/media', mediaRoutes);

// ==================== Gestion des erreurs ====================

// Route non trouvée
app.use(notFoundHandler);

// Gestionnaire d'erreurs global
app.use(errorHandler);

// ==================== Démarrage du serveur ====================

const server = app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║     🕌  Silkoul Ahzabou Tidiani API                       ║
║                                                            ║
║     Server running on port ${PORT}                           ║
║     Environment: ${process.env.NODE_ENV || 'development'}                        ║
║     Time: ${new Date().toLocaleString()}                       ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
  `);

  console.log('\n📍 Available endpoint examples:');
  console.log(`   - Health Check: GET http://localhost:${PORT}/health`);
  console.log(`   - Auth:         POST http://localhost:${PORT}/api/auth/signup`);
  console.log(`   - Auth:         POST http://localhost:${PORT}/api/auth/login`);
  console.log(`   - Users:        GET http://localhost:${PORT}/api/users/me (needs token)`);
  console.log(`   - Campaigns:    GET http://localhost:${PORT}/api/campaigns`);
  console.log(`   - Campaigns:    GET http://localhost:${PORT}/api/campaigns/{id}`);
  console.log(`   - Tasks:        GET http://localhost:${PORT}/api/tasks (needs token)`);
  console.log(`   - Tasks:        POST http://localhost:${PORT}/api/tasks/subscribe (needs token)`);
  console.log(`   - Tasks:        PUT http://localhost:${PORT}/api/tasks/{id}/progress (needs token)`);
  console.log('\n✨ Ready to serve requests!\n');
});

// Gestion de l'arrêt propre
process.on('SIGTERM', () => {
  console.log('👋 SIGTERM received, closing server gracefully...');
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('\n👋 SIGINT received, closing server gracefully...');
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
});

// Gestion des erreurs non capturées
process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  server.close(() => {
    process.exit(1);
  });
});

process.on('uncaughtException', (error) => {
  console.error('❌ Uncaught Exception:', error);
  server.close(() => {
    process.exit(1);
  });
});

module.exports = app;
