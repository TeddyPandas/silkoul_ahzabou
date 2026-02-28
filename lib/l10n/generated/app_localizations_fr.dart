// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MarkazSeyidTijani';

  @override
  String get campaigns => 'Campagnes';

  @override
  String get createCampaign => 'Créer une campagne';

  @override
  String get noCampaignsAvailable => 'Aucune campagne publique disponible.';

  @override
  String get noDescription => 'Aucune description';

  @override
  String get joinCampaign => 'Rejoindre la campagne';

  @override
  String get takeMoreNumbers => 'Prendre un nombre supplémentaire';

  @override
  String get subscriptionSuccess => 'Abonnement réussi !';

  @override
  String get tasksAddedSuccess => 'Tâches ajoutées avec succès !';

  @override
  String get community => 'Communauté';

  @override
  String get noUsersFound => 'Aucun membre trouvé dans la communauté.';

  @override
  String get user => 'Utilisateur';

  @override
  String get level => 'Niveau';

  @override
  String get points => 'Points';

  @override
  String userStats(Object level, Object points) {
    return 'Niveau : $level, Points : $points';
  }

  @override
  String get profile => 'Profil';

  @override
  String get displayName => 'Nom d\'affichage';

  @override
  String get email => 'Email';

  @override
  String get logout => 'Déconnexion';

  @override
  String get profileUpdatedSuccess => 'Profil mis à jour avec succès !';

  @override
  String profileUpdateFailed(String error) {
    return 'Échec de la mise à jour : $error';
  }

  @override
  String get userNotAuthenticated => 'Utilisateur non authentifié.';

  @override
  String get loginRequired => 'Veuillez vous connecter pour voir votre profil.';

  @override
  String get myTasks => 'Mes tâches';

  @override
  String get theSilsila => 'La Silsila';

  @override
  String get findWazifa => 'Trouver une Wazifa';

  @override
  String get courseCalendar => 'Calendrier des Cours';

  @override
  String get teachings => 'Enseignements';

  @override
  String get quizzes => 'Quiz';

  @override
  String get home => 'Accueil';

  @override
  String get error => 'Erreur';

  @override
  String errorWithMessage(String message) {
    return 'Erreur : $message';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get validate => 'Valider';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get loading => 'Chargement...';

  @override
  String get retry => 'Réessayer';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get close => 'Fermer';

  @override
  String get search => 'Rechercher';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get changeLanguage => 'Changer de langue';

  @override
  String get openTasbih => 'Ouvrir le Tasbih Électronique';

  @override
  String get chooseTasbihTask => 'Choisir une tâche pour le Tasbih';

  @override
  String get task => 'Tâche';

  @override
  String get viewAll => 'Voir tout';

  @override
  String get welcome => 'Bienvenue sur Ahzab';

  @override
  String get joinFirstCampaign => 'Rejoignez votre première campagne !';

  @override
  String get weekly => 'Chaque semaine';

  @override
  String get oneTime => 'Ponctuelle';

  @override
  String get recommendedCampaigns => 'Campagnes Recommandées';

  @override
  String get discovered => 'Découvrir';

  @override
  String by(String author) {
    return 'Par $author';
  }

  @override
  String get unknownAuthor => 'Inconnu';

  @override
  String get noCampaigns => 'Aucune campagne disponible.';

  @override
  String get continueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String get guestModeMessage => 'Vous explorez en mode invité. Connectez-vous pour accéder à toutes les fonctionnalités.';

  @override
  String get signInToAccess => 'Se connecter';

  @override
  String get spiritualCompanion => 'Votre compagnon spirituel';

  @override
  String get contactUs => 'Nous contacter';

  @override
  String get version => 'Version';

  @override
  String get infoSection => 'Section d\'information';

  @override
  String get clickForDetails => 'Cliquez pour voir plus de détails.';

  @override
  String get zikrCampaign => 'Campagne Zikr';

  @override
  String get featured => 'À la une';

  @override
  String get categories => 'Catégories';

  @override
  String get all => 'Tous';

  @override
  String get recentArticles => 'Articles récents';

  @override
  String articlesCount(Object count) {
    return '$count articles';
  }

  @override
  String get loadError => 'Erreur de chargement';

  @override
  String get noArticlesFound => 'Aucun article trouvé';

  @override
  String get viewAllArticles => 'Voir tous les articles';

  @override
  String get searchArticle => 'Rechercher un article...';

  @override
  String get searchHint => 'Recherchez en français ou en arabe';

  @override
  String get searchExample => 'Exemple : tariqa, ورد, dhikr...';

  @override
  String noResultsFor(Object query) {
    return 'Aucun résultat pour \"$query\"';
  }

  @override
  String get loginToLike => 'Connectez-vous pour aimer les articles';

  @override
  String get textCopied => 'Texte copié ! Vous pouvez le coller pour partager.';

  @override
  String get verified => 'Vérifié';

  @override
  String get views => 'Vues';

  @override
  String get likes => 'Likes';

  @override
  String get minutes => 'minutes';

  @override
  String source(Object source) {
    return 'Source : $source';
  }

  @override
  String get relatedArticles => 'Articles similaires';

  @override
  String get share => 'Partager';

  @override
  String get guidesAndSpeakers => 'Guides & Conférenciers';

  @override
  String get recentVideos => 'Vidéos récentes';

  @override
  String get allVideos => 'Toutes les vidéos';

  @override
  String get newRelease => 'Nouveauté';

  @override
  String get watchNow => 'Regarder maintenant';

  @override
  String get seeAll => 'Tout voir';

  @override
  String get noVideosAvailable => 'Aucune vidéo disponible.';

  @override
  String errorOccurred(Object error) {
    return 'Une erreur est survenue : $error';
  }

  @override
  String get target => 'Objectif';

  @override
  String get noTarget => 'Aucun objectif défini';

  @override
  String get subscribers => 'Inscrits';

  @override
  String get completed => 'Terminé';

  @override
  String get joining => 'Inscription...';

  @override
  String get unsubscribing => 'Désinscription...';

  @override
  String get joinSuccess => 'Inscription à la campagne réussie';

  @override
  String get unsubscribedSuccess => 'Désinscription réussie';

  @override
  String get alreadyCompleted => 'Cette campagne est déjà terminée';

  @override
  String get myContributions => 'Mes Contributions';

  @override
  String get campaignStats => 'Statistiques de la campagne';

  @override
  String get participants => 'Participants';

  @override
  String get globalProgress => 'Progression Globale';

  @override
  String get read => 'Lu';

  @override
  String get taken => 'Pris';

  @override
  String get free => 'Libre';

  @override
  String get terminate => 'Terminer';

  @override
  String get viewGlobalMap => 'Voir la carte globale';

  @override
  String get myJuz => 'Mes Juz (Appuyez pour marquer comme lu)';

  @override
  String get takeMoreJuz => 'Prendre d\'autres Juz';

  @override
  String get selectYourJuz => 'Sélectionnez vos Juz (Max 3)';

  @override
  String get campaignPrivate => 'Cette campagne est privée.';

  @override
  String get enterAccessCode => 'Saisir le code d\'accès';

  @override
  String get validating => 'Validation...';

  @override
  String get wazifaGatherings => 'Lieux de Wazifa';

  @override
  String get addGathering => 'Ajouter un lieu';

  @override
  String get filterByRhythm => 'Filtrer par rythme';

  @override
  String get daily => 'Chaque jour';

  @override
  String get monthly => 'Mensuel';

  @override
  String get other => 'Autre';

  @override
  String get gatheringDetails => 'Détails du lieu';

  @override
  String get getDirections => 'Y Aller';

  @override
  String get organizer => 'Organisateur';

  @override
  String get time => 'Heure';

  @override
  String get rhythm => 'Rythme';

  @override
  String get location => 'Localisation';

  @override
  String get successAddGathering => 'Lieu ajouté avec succès';

  @override
  String get errorAddGathering => 'Erreur lors de l\'ajout du lieu';

  @override
  String get gatheringNameHint => 'Nom du lieu';

  @override
  String get descriptionHint => 'Description (optionnelle)';

  @override
  String get selectRhythm => 'Sélectionner le rythme';

  @override
  String get startTime => 'Heure de début';

  @override
  String get endTime => 'Heure de fin';

  @override
  String get pickOnMap => 'Choisir sur carte';

  @override
  String get useCurrentLocation => 'Ma Position';

  @override
  String get gatheringNameRequired => 'Nom requis';

  @override
  String get searchTeachings => 'Rechercher un enseignement...';

  @override
  String get teachingTitle => 'Titre de l\'enseignement';

  @override
  String get podcasts => 'Podcasts (Séries)';

  @override
  String get videos => 'Vidéos';

  @override
  String get articles => 'Articles';

  @override
  String get recentTeachings => 'Enseignements récents';

  @override
  String get noTeachingsFound => 'Aucun enseignement trouvé.';

  @override
  String get startQuiz => 'Démarrer le quiz';

  @override
  String get quizResults => 'Résultats du quiz';

  @override
  String get score => 'Score';

  @override
  String get questions => 'Questions';

  @override
  String get correct => 'Correct';

  @override
  String get incorrect => 'Incorrect';

  @override
  String get playAgain => 'Rejouer';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get leaderboard => 'Classement';

  @override
  String get rank => 'Rang';

  @override
  String get player => 'Joueur';

  @override
  String get loadingQuizzes => 'Chargement des quiz...';

  @override
  String get noQuizzesFound => 'Aucun quiz disponible pour le moment.';

  @override
  String get silsila => 'Silsila (Chaîne)';

  @override
  String get addConnection => 'Ajouter une connexion';

  @override
  String get defineMuqaddam => 'Commencez par définir votre Muqaddam.';

  @override
  String get createChain => 'Créer ma Chaîne';

  @override
  String get recognizedCheikh => 'Cheikh Reconnu';

  @override
  String get addMaster => 'Ajouter son Maître (Étendre)';

  @override
  String get nodeDeleted => 'Nœud supprimé.';

  @override
  String get connectionAdded => 'Connexion ajoutée !';

  @override
  String get intermediateInserted => 'Intermédiaire inséré !';

  @override
  String get silsilaError => 'Erreur dans Silsila';

  @override
  String get upcoming => 'À venir';

  @override
  String get public => 'Public';

  @override
  String get private => 'Privé';

  @override
  String get ongoing => 'En cours';

  @override
  String get chooseLocation => 'Choisir la position';

  @override
  String get locationServiceDisabled => 'Service de localisation désactivé';

  @override
  String get permissionDenied => 'Permission refusée';

  @override
  String get permissionDeniedForever => 'Permission refusée définitivement';

  @override
  String get moveMapInstruction => 'Bougez la carte pour placer le repère sur le lieu exact';

  @override
  String get authFailed => 'Authentification échouée. Veuillez réessayer.';

  @override
  String get authInProgress => 'Authentification en cours... Vous serez redirigé(e) automatiquement.';

  @override
  String get zikrPractice => 'Pratique collective du Zikr';

  @override
  String get emailHint => 'votre.email@exemple.com';

  @override
  String get emailRequired => 'Veuillez entrer votre email';

  @override
  String get emailInvalid => 'Email invalide';

  @override
  String get password => 'Mot de passe';

  @override
  String get passwordRequired => 'Veuillez entrer votre mot de passe';

  @override
  String get passwordTooShort => 'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get featureComingSoon => 'Fonctionnalité à venir';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get login => 'Se connecter';

  @override
  String get orLabel => 'OU';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get noAccountYet => 'Pas encore de compte ?';

  @override
  String get signup => 'S\'inscrire';

  @override
  String get signupSuccess => 'Compte créé avec succès ! Bienvenue.';

  @override
  String get signupVerifyEmail => 'Inscription réussie. Veuillez vérifier vos emails.';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get joinCommunity => 'Rejoignez la communauté';

  @override
  String get createAccountToStart => 'Créez votre compte pour commencer';

  @override
  String get fullName => 'Nom complet';

  @override
  String get fullNameHint => 'Mohamed Ali';

  @override
  String get fullNameRequired => 'Veuillez entrer votre nom';

  @override
  String get fullNameTooShort => 'Le nom doit contenir au moins 3 caractères';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get confirmPasswordRequired => 'Veuillez confirmer votre mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get termsAndPrivacy => 'En créant un compte, vous acceptez nos Conditions d\'utilisation et notre Politique de confidentialité';

  @override
  String get errOpenTelegram => 'Impossible d\'ouvrir le lien Telegram';

  @override
  String get noCoursesDay => 'Aucun cours ce jour-là';

  @override
  String get joinTelegramChannel => 'Rejoindre le canal Telegram';

  @override
  String get noLinkAvailable => 'Aucun lien disponible';

  @override
  String get adminSettings => 'Paramètres';

  @override
  String get genInfo => 'INFORMATIONS GÉNÉRALES';

  @override
  String get sysLimits => 'LIMITES SYSTÈME (LECTURE SEULE)';

  @override
  String get toolsAdmin => 'OUTILS & ADMINISTRATION';

  @override
  String get appNameInfo => 'Nom de l\'application';

  @override
  String get versionInfo => 'Version';

  @override
  String get buildNumberInfo => 'Build Number';

  @override
  String get maxTasksCampaign => 'Max Tâches / Campagne';

  @override
  String get maxCampaignDuration => 'Durée Max Campagne';

  @override
  String get days => 'jours';

  @override
  String get maxDescLength => 'Longueur Max Description';

  @override
  String get chars => 'caractères';

  @override
  String get testNotif => 'Tester Notification';

  @override
  String get featureDisabledDebug => 'Fonctionnalité désactivée pour debug';

  @override
  String get testDisabledTemp => 'Test désactivé temporairement';

  @override
  String get testBtn => 'Tester';

  @override
  String get maintMode => 'Mode Maintenance';

  @override
  String get preventAccessUsersSim => 'Empêcher l\'accès aux utilisateurs (Simulation)';

  @override
  String get maintModeUpdatedSim => 'Mode maintenance mis à jour (Simulation)';

  @override
  String get confirmLogoutTitle => 'Confirmation de déconnexion';

  @override
  String get confirmLogoutMessage => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get logoutBtn => 'Déconnecter';

  @override
  String get manageCourses => 'Gestion des Cours';

  @override
  String get newTab => 'Nouveau';

  @override
  String get listTab => 'Liste';

  @override
  String get courseCreatedNotifSent => 'Cours créé + notification Telegram envoyée';

  @override
  String get editReschedule => 'Modifier / Reprogrammer';

  @override
  String get courseTitle => 'Titre du cours';

  @override
  String get required => 'Requis';

  @override
  String get teacher => 'Professeur';

  @override
  String get telegramLink => 'Lien Telegram';

  @override
  String get newDate => 'Nouvelle date';

  @override
  String get newTime => 'Nouvelle heure';

  @override
  String get recurrence => 'Récurrence';

  @override
  String get once => 'Unique';

  @override
  String get durationMin => 'Durée (min)';

  @override
  String get description => 'Description';

  @override
  String get saveBtn => 'Enregistrer';

  @override
  String get courseRescheduledNotifSent => 'Cours reprogrammé + notification Telegram envoyée';

  @override
  String get cancelCourseTitle => 'Annuler ce cours';

  @override
  String confirmCancelCourse(Object title) {
    return 'Voulez-vous annuler le cours \"$title\" ?';
  }

  @override
  String get cancelNotifTelegramInfo => 'Une notification d\'annulation sera envoyée sur le canal Telegram.';

  @override
  String get noKeepBtn => 'Non, garder';

  @override
  String get yesCancelBtn => 'Oui, annuler le cours';

  @override
  String get courseCanceledNotifSent => 'Cours annulé + notification Telegram envoyée';

  @override
  String get deleteCourseTitle => 'Supprimer ce cours';

  @override
  String confirmDeleteCourseSilent(Object title) {
    return 'Voulez-vous supprimer \"$title\" sans notifier le canal ?';
  }

  @override
  String get noBtn => 'Non';

  @override
  String get deleteBtn => 'Supprimer';

  @override
  String get courseDeleted => 'Cours supprimé';

  @override
  String get teacherOptional => 'Nom du professeur (optionnel)';

  @override
  String get telegramLinkChannel => 'Lien Telegram (Canal)';

  @override
  String get startDate => 'Date de début';

  @override
  String get descOptional => 'Description (optionnelle)';

  @override
  String get createAndNotifyTelegram => 'Créer le cours + Notifier Telegram';

  @override
  String get noCoursesCreated => 'Aucun cours n\'a été créé.';

  @override
  String get editBtn => 'Modifier';

  @override
  String get deleteTooltip => 'Supprimer (sans notification)';

  @override
  String get accessDenied => 'Accès Refusé';

  @override
  String get noAdminRights => 'Votre compte n\'a pas les droits d\'administrateur.';

  @override
  String get logoutNav => 'Se déconnecter';

  @override
  String get recurrenceWeekly => 'Chaque semaine';

  @override
  String get recurrenceDaily => 'Chaque jour';

  @override
  String get recurrenceOnce => 'Unique';

  @override
  String get adminTitle => 'ADMIN';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get contentSection => 'CONTENU';

  @override
  String get authors => 'Auteurs';

  @override
  String get importYouTube => 'Import YouTube';

  @override
  String get silsilas => 'Silsilas';

  @override
  String get courses => 'Cours';

  @override
  String get islamicQuiz => 'Quizz Islamique';

  @override
  String get communitySection => 'COMMUNAUTÉ';

  @override
  String get wazifaLoc => 'Localisation Wazifa';

  @override
  String get users => 'Utilisateurs';

  @override
  String get systemSection => 'SYSTÈME';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get noCampaignsFound => 'Aucune campagne trouvée';

  @override
  String get low => 'Lent';

  @override
  String get medium => 'Moyen';

  @override
  String get high => 'Rapide';

  @override
  String get learning => 'Apprentissage';

  @override
  String get testKnowledge => 'Testez vos connaissances';

  @override
  String get start => 'Démarrer';

  @override
  String get quizAlreadyCompleted => 'Quiz déjà complété';

  @override
  String get review => 'Réviser';

  @override
  String get practice => 'Pratiquer';

  @override
  String get practiceMode => 'Mode pratique';

  @override
  String get reward => 'Récompense';

  @override
  String get quizReviewed => 'Quiz révisé';

  @override
  String get congratulations => 'Félicitations';

  @override
  String get gameOver => 'Fin de partie';

  @override
  String get youObtained => 'Vous avez obtenu';

  @override
  String get unknown => 'Inconnu';

  @override
  String get campaignDetails => 'Détails de la campagne';

  @override
  String get enterCampaignAccessCode => 'Entrez le code d\'accès de la campagne';

  @override
  String get secretCode => 'Code secret';

  @override
  String get join => 'Rejoindre';
}
