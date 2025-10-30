class AppConstants {
  // Informations de l'application
  static const String appName = 'Silkoul Ahzabou Tidiani';
  static const String appVersion = '1.0.0';
  
  // Configuration des points et niveaux
  static const int pointsPerTaskCompletion = 10;
  static const int pointsPerCampaignCompletion = 100;
  static const int pointsPerDailyGoalMet = 5;
  
  // Limites
  static const int maxTasksPerCampaign = 20;
  static const int maxCampaignDurationDays = 365;
  static const int minCampaignDurationDays = 1;
  static const int maxCampaignNameLength = 100;
  static const int maxDescriptionLength = 500;
  
  // Notifications
  static const String notificationChannelId = 'silkoul_notifications';
  static const String notificationChannelName = 'Silkoul Notifications';
  static const String notificationChannelDescription = 
      'Notifications pour les campagnes et rappels de Zikr';
  
  // Catégories de campagnes
  static const List<String> campaignCategories = [
    'Istighfar',
    'Salawat',
    'Dhikr',
    'Tahlil',
    'Tasbih',
    'Takbir',
    'Dua',
    'Autre',
  ];
  
  // Messages
  static const String welcomeMessage = 
      'Bienvenue dans Silkoul Ahzabou Tidiani';
  static const String campaignCreatedMessage = 
      'Campagne créée avec succès';
  static const String subscriptionSuccessMessage = 
      'Abonnement réussi à la campagne';
  static const String taskCompletedMessage = 
      'MashAllah! Tâche complétée';
  static const String levelUpMessage = 
      'Félicitations! Vous avez atteint le niveau';
      
  // Erreurs
  static const String networkErrorMessage = 
      'Erreur de connexion. Veuillez vérifier votre connexion internet.';
  static const String genericErrorMessage = 
      'Une erreur s\'est produite. Veuillez réessayer.';
  static const String authErrorMessage = 
      'Erreur d\'authentification. Veuillez vous reconnecter.';
      
  // Formats de date
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  
  // Durées
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Tailles
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double iconSize = 24.0;
  static const double avatarSize = 80.0;
  
  // Padding & Margin
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Prayer times API (optionnel pour Phase 2)
  static const String prayerTimesApiBaseUrl = 'https://api.aladhan.com/v1';
}
