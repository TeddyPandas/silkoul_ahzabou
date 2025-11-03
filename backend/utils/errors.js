/**
 * Classes d'erreurs personnalisées pour l'application
 */

class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

class ValidationError extends AppError {
  constructor(message = 'Erreur de validation') {
    super(message, 400);
  }
}

class AuthenticationError extends AppError {
  constructor(message = 'Non authentifié') {
    super(message, 401);
  }
}

class AuthorizationError extends AppError {
  constructor(message = 'Non autorisé') {
    super(message, 403);
  }
}

class NotFoundError extends AppError {
  constructor(message = 'Ressource non trouvée') {
    super(message, 404);
  }
}

class ConflictError extends AppError {
  constructor(message = 'Conflit de ressource') {
    super(message, 409);
  }
}

class InternalError extends AppError {
  constructor(message = 'Erreur interne du serveur') {
    super(message, 500);
  }
}

// Gestionnaire d'erreurs global
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log de l'erreur en mode développement
  if (process.env.NODE_ENV === 'development') {
    console.error('Erreur:', err);
  }

  // Erreurs Supabase spécifiques
  if (err.code === '23505') {
    error = new ConflictError('Cette ressource existe déjà');
  }

  if (err.code === '23503') {
    error = new ValidationError('Référence invalide à une ressource');
  }

  // Erreur par défaut
  const statusCode = error.statusCode || 500;
  const status = error.status || 'error';

  res.status(statusCode).json({
    status,
    message: error.message || 'Une erreur est survenue',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

// Gestionnaire pour les routes non trouvées
const notFoundHandler = (req, res, next) => {
  next(new NotFoundError(`Route ${req.originalUrl} non trouvée`));
};

module.exports = {
  AppError,
  ValidationError,
  AuthenticationError,
  AuthorizationError,
  NotFoundError,
  ConflictError,
  InternalError,
  errorHandler,
  notFoundHandler
};
