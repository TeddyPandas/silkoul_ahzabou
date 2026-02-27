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
  /// **'Hebdomadaire'**
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
  /// **'Aucune campagne'**
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
