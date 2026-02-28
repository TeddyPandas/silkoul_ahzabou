import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'MarkazSeyidTijani'**
  String get appTitle;

  /// No description provided for @campaigns.
  ///
  /// In fr, this message translates to:
  /// **'Campagnes'**
  String get campaigns;

  /// No description provided for @createCampaign.
  ///
  /// In fr, this message translates to:
  /// **'Créer une campagne'**
  String get createCampaign;

  /// No description provided for @noCampaignsAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune campagne publique disponible.'**
  String get noCampaignsAvailable;

  /// No description provided for @noDescription.
  ///
  /// In fr, this message translates to:
  /// **'Aucune description'**
  String get noDescription;

  /// No description provided for @joinCampaign.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre la campagne'**
  String get joinCampaign;

  /// No description provided for @takeMoreNumbers.
  ///
  /// In fr, this message translates to:
  /// **'Prendre un nombre supplémentaire'**
  String get takeMoreNumbers;

  /// No description provided for @subscriptionSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement réussi !'**
  String get subscriptionSuccess;

  /// No description provided for @tasksAddedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Tâches ajoutées avec succès !'**
  String get tasksAddedSuccess;

  /// No description provided for @community.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get community;

  /// No description provided for @noUsersFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun membre trouvé dans la communauté.'**
  String get noUsersFound;

  /// No description provided for @user.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get user;

  /// No description provided for @level.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get level;

  /// No description provided for @points.
  ///
  /// In fr, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @userStats.
  ///
  /// In fr, this message translates to:
  /// **'Niveau : {level}, Points : {points}'**
  String userStats(Object level, Object points);

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @displayName.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'affichage'**
  String get displayName;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour avec succès !'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la mise à jour : {error}'**
  String profileUpdateFailed(String error);

  /// No description provided for @userNotAuthenticated.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur non authentifié.'**
  String get userNotAuthenticated;

  /// No description provided for @loginRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vous connecter pour voir votre profil.'**
  String get loginRequired;

  /// No description provided for @myTasks.
  ///
  /// In fr, this message translates to:
  /// **'Mes tâches'**
  String get myTasks;

  /// No description provided for @theSilsila.
  ///
  /// In fr, this message translates to:
  /// **'La Silsila'**
  String get theSilsila;

  /// No description provided for @findWazifa.
  ///
  /// In fr, this message translates to:
  /// **'Trouver une Wazifa'**
  String get findWazifa;

  /// No description provided for @courseCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier des Cours'**
  String get courseCalendar;

  /// No description provided for @teachings.
  ///
  /// In fr, this message translates to:
  /// **'Enseignements'**
  String get teachings;

  /// No description provided for @quizzes.
  ///
  /// In fr, this message translates to:
  /// **'Quiz'**
  String get quizzes;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @errorWithMessage.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {message}'**
  String errorWithMessage(String message);

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @changeLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Changer de langue'**
  String get changeLanguage;

  /// No description provided for @openTasbih.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir le Tasbih Électronique'**
  String get openTasbih;

  /// No description provided for @chooseTasbihTask.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une tâche pour le Tasbih'**
  String get chooseTasbihTask;

  /// No description provided for @task.
  ///
  /// In fr, this message translates to:
  /// **'Tâche'**
  String get task;

  /// No description provided for @viewAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get viewAll;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Ahzab'**
  String get welcome;

  /// No description provided for @joinFirstCampaign.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez votre première campagne !'**
  String get joinFirstCampaign;

  /// No description provided for @weekly.
  ///
  /// In fr, this message translates to:
  /// **'Chaque semaine'**
  String get weekly;

  /// No description provided for @oneTime.
  ///
  /// In fr, this message translates to:
  /// **'Ponctuelle'**
  String get oneTime;

  /// No description provided for @recommendedCampaigns.
  ///
  /// In fr, this message translates to:
  /// **'Campagnes Recommandées'**
  String get recommendedCampaigns;

  /// No description provided for @discovered.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get discovered;

  /// No description provided for @by.
  ///
  /// In fr, this message translates to:
  /// **'Par {author}'**
  String by(String author);

  /// No description provided for @unknownAuthor.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get unknownAuthor;

  /// No description provided for @noCampaigns.
  ///
  /// In fr, this message translates to:
  /// **'Aucune campagne disponible.'**
  String get noCampaigns;

  /// No description provided for @continueAsGuest.
  ///
  /// In fr, this message translates to:
  /// **'Continuer en tant qu\'invité'**
  String get continueAsGuest;

  /// No description provided for @guestModeMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous explorez en mode invité. Connectez-vous pour accéder à toutes les fonctionnalités.'**
  String get guestModeMessage;

  /// No description provided for @signInToAccess.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signInToAccess;

  /// No description provided for @spiritualCompanion.
  ///
  /// In fr, this message translates to:
  /// **'Votre compagnon spirituel'**
  String get spiritualCompanion;

  /// No description provided for @contactUs.
  ///
  /// In fr, this message translates to:
  /// **'Nous contacter'**
  String get contactUs;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @infoSection.
  ///
  /// In fr, this message translates to:
  /// **'Section d\'information'**
  String get infoSection;

  /// No description provided for @clickForDetails.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez pour voir plus de détails.'**
  String get clickForDetails;

  /// No description provided for @zikrCampaign.
  ///
  /// In fr, this message translates to:
  /// **'Campagne Zikr'**
  String get zikrCampaign;

  /// No description provided for @featured.
  ///
  /// In fr, this message translates to:
  /// **'À la une'**
  String get featured;

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get all;

  /// No description provided for @recentArticles.
  ///
  /// In fr, this message translates to:
  /// **'Articles récents'**
  String get recentArticles;

  /// No description provided for @articlesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} articles'**
  String articlesCount(Object count);

  /// No description provided for @loadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get loadError;

  /// No description provided for @noArticlesFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun article trouvé'**
  String get noArticlesFound;

  /// No description provided for @viewAllArticles.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les articles'**
  String get viewAllArticles;

  /// No description provided for @searchArticle.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un article...'**
  String get searchArticle;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Recherchez en français ou en arabe'**
  String get searchHint;

  /// No description provided for @searchExample.
  ///
  /// In fr, this message translates to:
  /// **'Exemple : tariqa, ورد, dhikr...'**
  String get searchExample;

  /// No description provided for @noResultsFor.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat pour \"{query}\"'**
  String noResultsFor(Object query);

  /// No description provided for @loginToLike.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour aimer les articles'**
  String get loginToLike;

  /// No description provided for @textCopied.
  ///
  /// In fr, this message translates to:
  /// **'Texte copié ! Vous pouvez le coller pour partager.'**
  String get textCopied;

  /// No description provided for @verified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get verified;

  /// No description provided for @views.
  ///
  /// In fr, this message translates to:
  /// **'Vues'**
  String get views;

  /// No description provided for @likes.
  ///
  /// In fr, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @minutes.
  ///
  /// In fr, this message translates to:
  /// **'minutes'**
  String get minutes;

  /// No description provided for @source.
  ///
  /// In fr, this message translates to:
  /// **'Source : {source}'**
  String source(Object source);

  /// No description provided for @relatedArticles.
  ///
  /// In fr, this message translates to:
  /// **'Articles similaires'**
  String get relatedArticles;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @guidesAndSpeakers.
  ///
  /// In fr, this message translates to:
  /// **'Guides & Conférenciers'**
  String get guidesAndSpeakers;

  /// No description provided for @recentVideos.
  ///
  /// In fr, this message translates to:
  /// **'Vidéos récentes'**
  String get recentVideos;

  /// No description provided for @allVideos.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les vidéos'**
  String get allVideos;

  /// No description provided for @newRelease.
  ///
  /// In fr, this message translates to:
  /// **'Nouveauté'**
  String get newRelease;

  /// No description provided for @watchNow.
  ///
  /// In fr, this message translates to:
  /// **'Regarder maintenant'**
  String get watchNow;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout voir'**
  String get seeAll;

  /// No description provided for @noVideosAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune vidéo disponible.'**
  String get noVideosAvailable;

  /// No description provided for @errorOccurred.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue : {error}'**
  String errorOccurred(Object error);

  /// No description provided for @target.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get target;

  /// No description provided for @noTarget.
  ///
  /// In fr, this message translates to:
  /// **'Aucun objectif défini'**
  String get noTarget;

  /// No description provided for @subscribers.
  ///
  /// In fr, this message translates to:
  /// **'Inscrits'**
  String get subscribers;

  /// No description provided for @completed.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get completed;

  /// No description provided for @joining.
  ///
  /// In fr, this message translates to:
  /// **'Inscription...'**
  String get joining;

  /// No description provided for @unsubscribing.
  ///
  /// In fr, this message translates to:
  /// **'Désinscription...'**
  String get unsubscribing;

  /// No description provided for @joinSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Inscription à la campagne réussie'**
  String get joinSuccess;

  /// No description provided for @unsubscribedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Désinscription réussie'**
  String get unsubscribedSuccess;

  /// No description provided for @alreadyCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Cette campagne est déjà terminée'**
  String get alreadyCompleted;

  /// No description provided for @myContributions.
  ///
  /// In fr, this message translates to:
  /// **'Mes Contributions'**
  String get myContributions;

  /// No description provided for @campaignStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques de la campagne'**
  String get campaignStats;

  /// No description provided for @participants.
  ///
  /// In fr, this message translates to:
  /// **'Participants'**
  String get participants;

  /// No description provided for @globalProgress.
  ///
  /// In fr, this message translates to:
  /// **'Progression Globale'**
  String get globalProgress;

  /// No description provided for @read.
  ///
  /// In fr, this message translates to:
  /// **'Lu'**
  String get read;

  /// No description provided for @taken.
  ///
  /// In fr, this message translates to:
  /// **'Pris'**
  String get taken;

  /// No description provided for @free.
  ///
  /// In fr, this message translates to:
  /// **'Libre'**
  String get free;

  /// No description provided for @terminate.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get terminate;

  /// No description provided for @viewGlobalMap.
  ///
  /// In fr, this message translates to:
  /// **'Voir la carte globale'**
  String get viewGlobalMap;

  /// No description provided for @myJuz.
  ///
  /// In fr, this message translates to:
  /// **'Mes Juz (Appuyez pour marquer comme lu)'**
  String get myJuz;

  /// No description provided for @takeMoreJuz.
  ///
  /// In fr, this message translates to:
  /// **'Prendre d\'autres Juz'**
  String get takeMoreJuz;

  /// No description provided for @selectYourJuz.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez vos Juz (Max 3)'**
  String get selectYourJuz;

  /// No description provided for @campaignPrivate.
  ///
  /// In fr, this message translates to:
  /// **'Cette campagne est privée.'**
  String get campaignPrivate;

  /// No description provided for @enterAccessCode.
  ///
  /// In fr, this message translates to:
  /// **'Saisir le code d\'accès'**
  String get enterAccessCode;

  /// No description provided for @validating.
  ///
  /// In fr, this message translates to:
  /// **'Validation...'**
  String get validating;

  /// No description provided for @wazifaGatherings.
  ///
  /// In fr, this message translates to:
  /// **'Lieux de Wazifa'**
  String get wazifaGatherings;

  /// No description provided for @addGathering.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un lieu'**
  String get addGathering;

  /// No description provided for @filterByRhythm.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer par rythme'**
  String get filterByRhythm;

  /// No description provided for @daily.
  ///
  /// In fr, this message translates to:
  /// **'Chaque jour'**
  String get daily;

  /// No description provided for @monthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get monthly;

  /// No description provided for @other.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get other;

  /// No description provided for @gatheringDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du lieu'**
  String get gatheringDetails;

  /// No description provided for @getDirections.
  ///
  /// In fr, this message translates to:
  /// **'Y Aller'**
  String get getDirections;

  /// No description provided for @organizer.
  ///
  /// In fr, this message translates to:
  /// **'Organisateur'**
  String get organizer;

  /// No description provided for @time.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get time;

  /// No description provided for @rhythm.
  ///
  /// In fr, this message translates to:
  /// **'Rythme'**
  String get rhythm;

  /// No description provided for @location.
  ///
  /// In fr, this message translates to:
  /// **'Localisation'**
  String get location;

  /// No description provided for @successAddGathering.
  ///
  /// In fr, this message translates to:
  /// **'Lieu ajouté avec succès'**
  String get successAddGathering;

  /// No description provided for @errorAddGathering.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'ajout du lieu'**
  String get errorAddGathering;

  /// No description provided for @gatheringNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom du lieu'**
  String get gatheringNameHint;

  /// No description provided for @descriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnelle)'**
  String get descriptionHint;

  /// No description provided for @selectRhythm.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner le rythme'**
  String get selectRhythm;

  /// No description provided for @startTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure de début'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure de fin'**
  String get endTime;

  /// No description provided for @pickOnMap.
  ///
  /// In fr, this message translates to:
  /// **'Choisir sur carte'**
  String get pickOnMap;

  /// No description provided for @useCurrentLocation.
  ///
  /// In fr, this message translates to:
  /// **'Ma Position'**
  String get useCurrentLocation;

  /// No description provided for @gatheringNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom requis'**
  String get gatheringNameRequired;

  /// No description provided for @searchTeachings.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un enseignement...'**
  String get searchTeachings;

  /// No description provided for @teachingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre de l\'enseignement'**
  String get teachingTitle;

  /// No description provided for @podcasts.
  ///
  /// In fr, this message translates to:
  /// **'Podcasts (Séries)'**
  String get podcasts;

  /// No description provided for @videos.
  ///
  /// In fr, this message translates to:
  /// **'Vidéos'**
  String get videos;

  /// No description provided for @articles.
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get articles;

  /// No description provided for @recentTeachings.
  ///
  /// In fr, this message translates to:
  /// **'Enseignements récents'**
  String get recentTeachings;

  /// No description provided for @noTeachingsFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun enseignement trouvé.'**
  String get noTeachingsFound;

  /// No description provided for @startQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer le quiz'**
  String get startQuiz;

  /// No description provided for @quizResults.
  ///
  /// In fr, this message translates to:
  /// **'Résultats du quiz'**
  String get quizResults;

  /// No description provided for @score.
  ///
  /// In fr, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @questions.
  ///
  /// In fr, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @correct.
  ///
  /// In fr, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @incorrect.
  ///
  /// In fr, this message translates to:
  /// **'Incorrect'**
  String get incorrect;

  /// No description provided for @playAgain.
  ///
  /// In fr, this message translates to:
  /// **'Rejouer'**
  String get playAgain;

  /// No description provided for @backToHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToHome;

  /// No description provided for @leaderboard.
  ///
  /// In fr, this message translates to:
  /// **'Classement'**
  String get leaderboard;

  /// No description provided for @rank.
  ///
  /// In fr, this message translates to:
  /// **'Rang'**
  String get rank;

  /// No description provided for @player.
  ///
  /// In fr, this message translates to:
  /// **'Joueur'**
  String get player;

  /// No description provided for @loadingQuizzes.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des quiz...'**
  String get loadingQuizzes;

  /// No description provided for @noQuizzesFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun quiz disponible pour le moment.'**
  String get noQuizzesFound;

  /// No description provided for @silsila.
  ///
  /// In fr, this message translates to:
  /// **'Silsila (Chaîne)'**
  String get silsila;

  /// No description provided for @addConnection.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une connexion'**
  String get addConnection;

  /// No description provided for @defineMuqaddam.
  ///
  /// In fr, this message translates to:
  /// **'Commencez par définir votre Muqaddam.'**
  String get defineMuqaddam;

  /// No description provided for @createChain.
  ///
  /// In fr, this message translates to:
  /// **'Créer ma Chaîne'**
  String get createChain;

  /// No description provided for @recognizedCheikh.
  ///
  /// In fr, this message translates to:
  /// **'Cheikh Reconnu'**
  String get recognizedCheikh;

  /// No description provided for @addMaster.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter son Maître (Étendre)'**
  String get addMaster;

  /// No description provided for @nodeDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Nœud supprimé.'**
  String get nodeDeleted;

  /// No description provided for @connectionAdded.
  ///
  /// In fr, this message translates to:
  /// **'Connexion ajoutée !'**
  String get connectionAdded;

  /// No description provided for @intermediateInserted.
  ///
  /// In fr, this message translates to:
  /// **'Intermédiaire inséré !'**
  String get intermediateInserted;

  /// No description provided for @silsilaError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur dans Silsila'**
  String get silsilaError;

  /// No description provided for @upcoming.
  ///
  /// In fr, this message translates to:
  /// **'À venir'**
  String get upcoming;

  /// No description provided for @public.
  ///
  /// In fr, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @private.
  ///
  /// In fr, this message translates to:
  /// **'Privé'**
  String get private;

  /// No description provided for @ongoing.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get ongoing;

  /// No description provided for @chooseLocation.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la position'**
  String get chooseLocation;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Service de localisation désactivé'**
  String get locationServiceDisabled;

  /// No description provided for @permissionDenied.
  ///
  /// In fr, this message translates to:
  /// **'Permission refusée'**
  String get permissionDenied;

  /// No description provided for @permissionDeniedForever.
  ///
  /// In fr, this message translates to:
  /// **'Permission refusée définitivement'**
  String get permissionDeniedForever;

  /// No description provided for @moveMapInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Bougez la carte pour placer le repère sur le lieu exact'**
  String get moveMapInstruction;

  /// No description provided for @authFailed.
  ///
  /// In fr, this message translates to:
  /// **'Authentification échouée. Veuillez réessayer.'**
  String get authFailed;

  /// No description provided for @authInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Authentification en cours... Vous serez redirigé(e) automatiquement.'**
  String get authInProgress;

  /// No description provided for @zikrPractice.
  ///
  /// In fr, this message translates to:
  /// **'Pratique collective du Zikr'**
  String get zikrPractice;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'votre.email@exemple.com'**
  String get emailHint;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre email'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get emailInvalid;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre mot de passe'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères'**
  String get passwordTooShort;

  /// No description provided for @featureComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalité à venir'**
  String get featureComingSoon;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get login;

  /// No description provided for @orLabel.
  ///
  /// In fr, this message translates to:
  /// **'OU'**
  String get orLabel;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @noAccountYet.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccountYet;

  /// No description provided for @signup.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signup;

  /// No description provided for @signupSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Compte créé avec succès ! Bienvenue.'**
  String get signupSuccess;

  /// No description provided for @signupVerifyEmail.
  ///
  /// In fr, this message translates to:
  /// **'Inscription réussie. Veuillez vérifier vos emails.'**
  String get signupVerifyEmail;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @joinCommunity.
  ///
  /// In fr, this message translates to:
  /// **'Rejoignez la communauté'**
  String get joinCommunity;

  /// No description provided for @createAccountToStart.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre compte pour commencer'**
  String get createAccountToStart;

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get fullName;

  /// No description provided for @fullNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Mohamed Ali'**
  String get fullNameHint;

  /// No description provided for @fullNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre nom'**
  String get fullNameRequired;

  /// No description provided for @fullNameTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le nom doit contenir au moins 3 caractères'**
  String get fullNameTooShort;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez confirmer votre mot de passe'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordsDoNotMatch;

  /// No description provided for @termsAndPrivacy.
  ///
  /// In fr, this message translates to:
  /// **'En créant un compte, vous acceptez nos Conditions d\'utilisation et notre Politique de confidentialité'**
  String get termsAndPrivacy;

  /// No description provided for @errOpenTelegram.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir le lien Telegram'**
  String get errOpenTelegram;

  /// No description provided for @noCoursesDay.
  ///
  /// In fr, this message translates to:
  /// **'Aucun cours ce jour-là'**
  String get noCoursesDay;

  /// No description provided for @joinTelegramChannel.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre le canal Telegram'**
  String get joinTelegramChannel;

  /// No description provided for @noLinkAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun lien disponible'**
  String get noLinkAvailable;

  /// No description provided for @adminSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get adminSettings;

  /// No description provided for @genInfo.
  ///
  /// In fr, this message translates to:
  /// **'INFORMATIONS GÉNÉRALES'**
  String get genInfo;

  /// No description provided for @sysLimits.
  ///
  /// In fr, this message translates to:
  /// **'LIMITES SYSTÈME (LECTURE SEULE)'**
  String get sysLimits;

  /// No description provided for @toolsAdmin.
  ///
  /// In fr, this message translates to:
  /// **'OUTILS & ADMINISTRATION'**
  String get toolsAdmin;

  /// No description provided for @appNameInfo.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'application'**
  String get appNameInfo;

  /// No description provided for @versionInfo.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get versionInfo;

  /// No description provided for @buildNumberInfo.
  ///
  /// In fr, this message translates to:
  /// **'Build Number'**
  String get buildNumberInfo;

  /// No description provided for @maxTasksCampaign.
  ///
  /// In fr, this message translates to:
  /// **'Max Tâches / Campagne'**
  String get maxTasksCampaign;

  /// No description provided for @maxCampaignDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée Max Campagne'**
  String get maxCampaignDuration;

  /// No description provided for @days.
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get days;

  /// No description provided for @maxDescLength.
  ///
  /// In fr, this message translates to:
  /// **'Longueur Max Description'**
  String get maxDescLength;

  /// No description provided for @chars.
  ///
  /// In fr, this message translates to:
  /// **'caractères'**
  String get chars;

  /// No description provided for @testNotif.
  ///
  /// In fr, this message translates to:
  /// **'Tester Notification'**
  String get testNotif;

  /// No description provided for @featureDisabledDebug.
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalité désactivée pour debug'**
  String get featureDisabledDebug;

  /// No description provided for @testDisabledTemp.
  ///
  /// In fr, this message translates to:
  /// **'Test désactivé temporairement'**
  String get testDisabledTemp;

  /// No description provided for @testBtn.
  ///
  /// In fr, this message translates to:
  /// **'Tester'**
  String get testBtn;

  /// No description provided for @maintMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode Maintenance'**
  String get maintMode;

  /// No description provided for @preventAccessUsersSim.
  ///
  /// In fr, this message translates to:
  /// **'Empêcher l\'accès aux utilisateurs (Simulation)'**
  String get preventAccessUsersSim;

  /// No description provided for @maintModeUpdatedSim.
  ///
  /// In fr, this message translates to:
  /// **'Mode maintenance mis à jour (Simulation)'**
  String get maintModeUpdatedSim;

  /// No description provided for @confirmLogoutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation de déconnexion'**
  String get confirmLogoutTitle;

  /// No description provided for @confirmLogoutMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir vous déconnecter ?'**
  String get confirmLogoutMessage;

  /// No description provided for @logoutBtn.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get logoutBtn;

  /// No description provided for @manageCourses.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des Cours'**
  String get manageCourses;

  /// No description provided for @newTab.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get newTab;

  /// No description provided for @listTab.
  ///
  /// In fr, this message translates to:
  /// **'Liste'**
  String get listTab;

  /// No description provided for @courseCreatedNotifSent.
  ///
  /// In fr, this message translates to:
  /// **'Cours créé + notification Telegram envoyée'**
  String get courseCreatedNotifSent;

  /// No description provided for @editReschedule.
  ///
  /// In fr, this message translates to:
  /// **'Modifier / Reprogrammer'**
  String get editReschedule;

  /// No description provided for @courseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre du cours'**
  String get courseTitle;

  /// No description provided for @required.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get required;

  /// No description provided for @teacher.
  ///
  /// In fr, this message translates to:
  /// **'Professeur'**
  String get teacher;

  /// No description provided for @telegramLink.
  ///
  /// In fr, this message translates to:
  /// **'Lien Telegram'**
  String get telegramLink;

  /// No description provided for @newDate.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle date'**
  String get newDate;

  /// No description provided for @newTime.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle heure'**
  String get newTime;

  /// No description provided for @recurrence.
  ///
  /// In fr, this message translates to:
  /// **'Récurrence'**
  String get recurrence;

  /// No description provided for @once.
  ///
  /// In fr, this message translates to:
  /// **'Unique'**
  String get once;

  /// No description provided for @durationMin.
  ///
  /// In fr, this message translates to:
  /// **'Durée (min)'**
  String get durationMin;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @saveBtn.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get saveBtn;

  /// No description provided for @courseRescheduledNotifSent.
  ///
  /// In fr, this message translates to:
  /// **'Cours reprogrammé + notification Telegram envoyée'**
  String get courseRescheduledNotifSent;

  /// No description provided for @cancelCourseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ce cours'**
  String get cancelCourseTitle;

  /// No description provided for @confirmCancelCourse.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous annuler le cours \"{title}\" ?'**
  String confirmCancelCourse(Object title);

  /// No description provided for @cancelNotifTelegramInfo.
  ///
  /// In fr, this message translates to:
  /// **'Une notification d\'annulation sera envoyée sur le canal Telegram.'**
  String get cancelNotifTelegramInfo;

  /// No description provided for @noKeepBtn.
  ///
  /// In fr, this message translates to:
  /// **'Non, garder'**
  String get noKeepBtn;

  /// No description provided for @yesCancelBtn.
  ///
  /// In fr, this message translates to:
  /// **'Oui, annuler le cours'**
  String get yesCancelBtn;

  /// No description provided for @courseCanceledNotifSent.
  ///
  /// In fr, this message translates to:
  /// **'Cours annulé + notification Telegram envoyée'**
  String get courseCanceledNotifSent;

  /// No description provided for @deleteCourseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce cours'**
  String get deleteCourseTitle;

  /// No description provided for @confirmDeleteCourseSilent.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous supprimer \"{title}\" sans notifier le canal ?'**
  String confirmDeleteCourseSilent(Object title);

  /// No description provided for @noBtn.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get noBtn;

  /// No description provided for @deleteBtn.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteBtn;

  /// No description provided for @courseDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Cours supprimé'**
  String get courseDeleted;

  /// No description provided for @teacherOptional.
  ///
  /// In fr, this message translates to:
  /// **'Nom du professeur (optionnel)'**
  String get teacherOptional;

  /// No description provided for @telegramLinkChannel.
  ///
  /// In fr, this message translates to:
  /// **'Lien Telegram (Canal)'**
  String get telegramLinkChannel;

  /// No description provided for @startDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de début'**
  String get startDate;

  /// No description provided for @descOptional.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnelle)'**
  String get descOptional;

  /// No description provided for @createAndNotifyTelegram.
  ///
  /// In fr, this message translates to:
  /// **'Créer le cours + Notifier Telegram'**
  String get createAndNotifyTelegram;

  /// No description provided for @noCoursesCreated.
  ///
  /// In fr, this message translates to:
  /// **'Aucun cours n\'a été créé.'**
  String get noCoursesCreated;

  /// No description provided for @editBtn.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editBtn;

  /// No description provided for @deleteTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer (sans notification)'**
  String get deleteTooltip;

  /// No description provided for @accessDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès Refusé'**
  String get accessDenied;

  /// No description provided for @noAdminRights.
  ///
  /// In fr, this message translates to:
  /// **'Votre compte n\'a pas les droits d\'administrateur.'**
  String get noAdminRights;

  /// No description provided for @logoutNav.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logoutNav;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Chaque semaine'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceDaily.
  ///
  /// In fr, this message translates to:
  /// **'Chaque jour'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceOnce.
  ///
  /// In fr, this message translates to:
  /// **'Unique'**
  String get recurrenceOnce;

  /// No description provided for @adminTitle.
  ///
  /// In fr, this message translates to:
  /// **'ADMIN'**
  String get adminTitle;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboard;

  /// No description provided for @contentSection.
  ///
  /// In fr, this message translates to:
  /// **'CONTENU'**
  String get contentSection;

  /// No description provided for @authors.
  ///
  /// In fr, this message translates to:
  /// **'Auteurs'**
  String get authors;

  /// No description provided for @importYouTube.
  ///
  /// In fr, this message translates to:
  /// **'Import YouTube'**
  String get importYouTube;

  /// No description provided for @silsilas.
  ///
  /// In fr, this message translates to:
  /// **'Silsilas'**
  String get silsilas;

  /// No description provided for @courses.
  ///
  /// In fr, this message translates to:
  /// **'Cours'**
  String get courses;

  /// No description provided for @islamicQuiz.
  ///
  /// In fr, this message translates to:
  /// **'Quizz Islamique'**
  String get islamicQuiz;

  /// No description provided for @communitySection.
  ///
  /// In fr, this message translates to:
  /// **'COMMUNAUTÉ'**
  String get communitySection;

  /// No description provided for @wazifaLoc.
  ///
  /// In fr, this message translates to:
  /// **'Localisation Wazifa'**
  String get wazifaLoc;

  /// No description provided for @users.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get users;

  /// No description provided for @systemSection.
  ///
  /// In fr, this message translates to:
  /// **'SYSTÈME'**
  String get systemSection;

  /// No description provided for @noResultsFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat trouvé'**
  String get noResultsFound;

  /// No description provided for @noCampaignsFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune campagne trouvée'**
  String get noCampaignsFound;

  /// No description provided for @low.
  ///
  /// In fr, this message translates to:
  /// **'Lent'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In fr, this message translates to:
  /// **'Moyen'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In fr, this message translates to:
  /// **'Rapide'**
  String get high;

  /// No description provided for @learning.
  ///
  /// In fr, this message translates to:
  /// **'Apprentissage'**
  String get learning;

  /// No description provided for @testKnowledge.
  ///
  /// In fr, this message translates to:
  /// **'Testez vos connaissances'**
  String get testKnowledge;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer'**
  String get start;

  /// No description provided for @quizAlreadyCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Quiz déjà complété'**
  String get quizAlreadyCompleted;

  /// No description provided for @review.
  ///
  /// In fr, this message translates to:
  /// **'Réviser'**
  String get review;

  /// No description provided for @practice.
  ///
  /// In fr, this message translates to:
  /// **'Pratiquer'**
  String get practice;

  /// No description provided for @practiceMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode pratique'**
  String get practiceMode;

  /// No description provided for @reward.
  ///
  /// In fr, this message translates to:
  /// **'Récompense'**
  String get reward;

  /// No description provided for @quizReviewed.
  ///
  /// In fr, this message translates to:
  /// **'Quiz révisé'**
  String get quizReviewed;

  /// No description provided for @congratulations.
  ///
  /// In fr, this message translates to:
  /// **'Félicitations'**
  String get congratulations;

  /// No description provided for @gameOver.
  ///
  /// In fr, this message translates to:
  /// **'Fin de partie'**
  String get gameOver;

  /// No description provided for @youObtained.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez obtenu'**
  String get youObtained;

  /// No description provided for @unknown.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get unknown;

  /// No description provided for @campaignDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails de la campagne'**
  String get campaignDetails;

  /// No description provided for @enterCampaignAccessCode.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le code d\'accès de la campagne'**
  String get enterCampaignAccessCode;

  /// No description provided for @secretCode.
  ///
  /// In fr, this message translates to:
  /// **'Code secret'**
  String get secretCode;

  /// No description provided for @join.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre'**
  String get join;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
