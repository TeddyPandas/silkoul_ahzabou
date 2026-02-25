// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MarkazTijani';

  @override
  String get campaigns => 'Campaigns';

  @override
  String get createCampaign => 'Create Campaign';

  @override
  String get noCampaignsAvailable => 'No public campaigns available.';

  @override
  String get noDescription => 'No description';

  @override
  String get joinCampaign => 'Join Campaign';

  @override
  String get takeMoreNumbers => 'Take additional numbers';

  @override
  String get subscriptionSuccess => 'Subscription successful!';

  @override
  String get tasksAddedSuccess => 'Tasks added successfully!';

  @override
  String get community => 'Community';

  @override
  String get noUsersFound => 'No members found in the community.';

  @override
  String get user => 'User';

  @override
  String get level => 'Level';

  @override
  String get points => 'Points';

  @override
  String get profile => 'Profile';

  @override
  String get displayName => 'Display Name';

  @override
  String get email => 'Email';

  @override
  String get logout => 'Logout';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully!';

  @override
  String profileUpdateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String get userNotAuthenticated => 'User not authenticated.';

  @override
  String get loginRequired => 'Please log in to view your profile.';

  @override
  String get myTasks => 'My Tasks';

  @override
  String get theSilsila => 'The Silsila';

  @override
  String get findWazifa => 'Find a Wazifa';

  @override
  String get courseCalendar => 'Course Calendar';

  @override
  String get teachings => 'Teachings';

  @override
  String get quizzes => 'Quizzes';

  @override
  String get home => 'Home';

  @override
  String get error => 'Error';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get validate => 'Validate';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get loading => 'Loading...';

  @override
  String get retry => 'Retry';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get close => 'Close';

  @override
  String get search => 'Search';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get openTasbih => 'Open Electronic Tasbih';

  @override
  String get chooseTasbihTask => 'Choose a task for Tasbih';

  @override
  String get task => 'Task';

  @override
  String get viewAll => 'View all';

  @override
  String get welcome => 'Welcome to Ahzab';

  @override
  String get joinFirstCampaign => 'Join your first campaign!';

  @override
  String get weekly => 'Weekly';

  @override
  String get oneTime => 'One-time';

  @override
  String get recommendedCampaigns => 'Recommended Campaigns';

  @override
  String get discovered => 'Discover';

  @override
  String by(String author) {
    return 'By $author';
  }

  @override
  String get unknownAuthor => 'Unknown';

  @override
  String get noCampaigns => 'No campaigns';
}
