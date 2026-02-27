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
  String get weekly => 'Hebdomadaire';

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
  String get noCampaigns => 'Aucune campagne';

  @override
  String get continueAsGuest => 'Continuer en tant qu\'invité';

  @override
  String get guestModeMessage => 'Vous explorez en mode invité. Connectez-vous pour accéder à toutes les fonctionnalités.';

  @override
  String get signInToAccess => 'Se connecter';
}
