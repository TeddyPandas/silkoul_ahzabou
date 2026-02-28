// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MarkazSeyidTijani';

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
  String userStats(Object level, Object points) {
    return 'Level: $level, Points: $points';
  }

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
  String get noCampaigns => 'No campaigns available.';

  @override
  String get continueAsGuest => 'Continue as guest';

  @override
  String get guestModeMessage => 'You\'re browsing as a guest. Sign in to access all features.';

  @override
  String get signInToAccess => 'Sign in';

  @override
  String get spiritualCompanion => 'Your spiritual companion';

  @override
  String get contactUs => 'Contact us';

  @override
  String get version => 'Version';

  @override
  String get infoSection => 'Information Section';

  @override
  String get clickForDetails => 'Click to see more details.';

  @override
  String get zikrCampaign => 'Zikr Campaign';

  @override
  String get featured => 'Featured';

  @override
  String get categories => 'Categories';

  @override
  String get all => 'All';

  @override
  String get recentArticles => 'Recent Articles';

  @override
  String articlesCount(Object count) {
    return '$count articles';
  }

  @override
  String get loadError => 'Load Error';

  @override
  String get noArticlesFound => 'No articles found';

  @override
  String get viewAllArticles => 'View all articles';

  @override
  String get searchArticle => 'Search for an article...';

  @override
  String get searchHint => 'Search in French or Arabic';

  @override
  String get searchExample => 'Example: tariqa, ورد, dhikr...';

  @override
  String noResultsFor(Object query) {
    return 'No results for \"$query\"';
  }

  @override
  String get loginToLike => 'Sign in to like articles';

  @override
  String get textCopied => 'Text copied! You can paste it to share.';

  @override
  String get verified => 'Verified';

  @override
  String get views => 'Views';

  @override
  String get likes => 'Likes';

  @override
  String get minutes => 'minutes';

  @override
  String source(Object source) {
    return 'Source: $source';
  }

  @override
  String get relatedArticles => 'Related Articles';

  @override
  String get share => 'Share';

  @override
  String get guidesAndSpeakers => 'Guides & Speakers';

  @override
  String get recentVideos => 'Recent Videos';

  @override
  String get allVideos => 'All Videos';

  @override
  String get newRelease => 'New Release';

  @override
  String get watchNow => 'Watch Now';

  @override
  String get seeAll => 'See All';

  @override
  String get noVideosAvailable => 'No videos available.';

  @override
  String errorOccurred(Object error) {
    return 'An error occurred: $error';
  }

  @override
  String get target => 'Target';

  @override
  String get noTarget => 'No target defined';

  @override
  String get subscribers => 'Subscribers';

  @override
  String get completed => 'Completed';

  @override
  String get joining => 'Joining...';

  @override
  String get unsubscribing => 'Unsubscribing...';

  @override
  String get joinSuccess => 'Successfully joined the campaign';

  @override
  String get unsubscribedSuccess => 'Successfully unsubscribed';

  @override
  String get alreadyCompleted => 'This campaign is already completed';

  @override
  String get myContributions => 'My Contributions';

  @override
  String get campaignStats => 'Campaign Statistics';

  @override
  String get participants => 'Participants';

  @override
  String get globalProgress => 'Global Progress';

  @override
  String get read => 'Read';

  @override
  String get taken => 'Taken';

  @override
  String get free => 'Free';

  @override
  String get terminate => 'Terminate';

  @override
  String get viewGlobalMap => 'View global map';

  @override
  String get myJuz => 'My Juz (Tap to mark as read)';

  @override
  String get takeMoreJuz => 'Take more Juz';

  @override
  String get selectYourJuz => 'Select your Juz (Max 3)';

  @override
  String get campaignPrivate => 'This campaign is private.';

  @override
  String get enterAccessCode => 'Enter access code';

  @override
  String get validating => 'Validating...';

  @override
  String get wazifaGatherings => 'Wazifa Gatherings';

  @override
  String get addGathering => 'Add Gathering';

  @override
  String get filterByRhythm => 'Filter by rhythm';

  @override
  String get daily => 'Daily';

  @override
  String get monthly => 'Monthly';

  @override
  String get other => 'Other';

  @override
  String get gatheringDetails => 'Gathering Details';

  @override
  String get getDirections => 'Get Directions';

  @override
  String get organizer => 'Organizer';

  @override
  String get time => 'Time';

  @override
  String get rhythm => 'Rhythm';

  @override
  String get location => 'Location';

  @override
  String get successAddGathering => 'Gathering added successfully';

  @override
  String get errorAddGathering => 'Error adding gathering';

  @override
  String get gatheringNameHint => 'Gathering name';

  @override
  String get descriptionHint => 'Description (optional)';

  @override
  String get selectRhythm => 'Select rhythm';

  @override
  String get startTime => 'Start time';

  @override
  String get endTime => 'End time';

  @override
  String get pickOnMap => 'Pick on map';

  @override
  String get useCurrentLocation => 'Use current location';

  @override
  String get gatheringNameRequired => 'Please enter a name';

  @override
  String get searchTeachings => 'Search for a teaching...';

  @override
  String get teachingTitle => 'Teaching Title';

  @override
  String get podcasts => 'Podcasts (Series)';

  @override
  String get videos => 'Videos';

  @override
  String get articles => 'Articles';

  @override
  String get recentTeachings => 'Recent Teachings';

  @override
  String get noTeachingsFound => 'No teachings found.';

  @override
  String get startQuiz => 'Start Quiz';

  @override
  String get quizResults => 'Quiz Results';

  @override
  String get score => 'Score';

  @override
  String get questions => 'Questions';

  @override
  String get correct => 'Correct';

  @override
  String get incorrect => 'Incorrect';

  @override
  String get playAgain => 'Play Again';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get rank => 'Rank';

  @override
  String get player => 'Player';

  @override
  String get loadingQuizzes => 'Loading quizzes...';

  @override
  String get noQuizzesFound => 'No quizzes available yet.';

  @override
  String get silsila => 'Silsila (Chain)';

  @override
  String get addConnection => 'Add Connection';

  @override
  String get defineMuqaddam => 'Start by defining your Muqaddam.';

  @override
  String get createChain => 'Create my Chain';

  @override
  String get recognizedCheikh => 'Recognized Cheikh';

  @override
  String get addMaster => 'Add Master (Extend chain)';

  @override
  String get nodeDeleted => 'Node deleted.';

  @override
  String get connectionAdded => 'Connection added!';

  @override
  String get intermediateInserted => 'Intermediate inserted successfully!';

  @override
  String get silsilaError => 'Error in Silsila';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get public => 'Public';

  @override
  String get private => 'Private';

  @override
  String get ongoing => 'Ongoing';

  @override
  String get chooseLocation => 'Choose Location';

  @override
  String get locationServiceDisabled => 'Location service disabled';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get permissionDeniedForever => 'Permission denied permanently';

  @override
  String get moveMapInstruction => 'Move the map to place the marker on the exact location';

  @override
  String get authFailed => 'Authentication failed. Please try again.';

  @override
  String get authInProgress => 'Authentication in progress... You will be redirected automatically.';

  @override
  String get zikrPractice => 'Collective Zikr Practice';

  @override
  String get emailHint => 'your.email@example.com';

  @override
  String get emailRequired => 'Please enter your email';

  @override
  String get emailInvalid => 'Invalid email';

  @override
  String get password => 'Password';

  @override
  String get passwordRequired => 'Please enter your password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get featureComingSoon => 'Feature coming soon';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get login => 'Login';

  @override
  String get orLabel => 'OR';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get noAccountYet => 'Don\'t have an account yet?';

  @override
  String get signup => 'Sign up';

  @override
  String get signupSuccess => 'Account created successfully! Welcome.';

  @override
  String get signupVerifyEmail => 'Registration successful. Please check your emails.';

  @override
  String get createAccount => 'Create an account';

  @override
  String get joinCommunity => 'Join the community';

  @override
  String get createAccountToStart => 'Create your account to start';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'Mohamed Ali';

  @override
  String get fullNameRequired => 'Please enter your name';

  @override
  String get fullNameTooShort => 'Name must be at least 3 characters';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordRequired => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get termsAndPrivacy => 'By creating an account, you agree to our Terms of Use and Privacy Policy';

  @override
  String get errOpenTelegram => 'Cannot open Telegram link';

  @override
  String get noCoursesDay => 'No courses for this day';

  @override
  String get joinTelegramChannel => 'Join Telegram Channel';

  @override
  String get noLinkAvailable => 'No link available';

  @override
  String get adminSettings => 'Settings';

  @override
  String get genInfo => 'GENERAL INFORMATION';

  @override
  String get sysLimits => 'SYSTEM LIMITS (READ ONLY)';

  @override
  String get toolsAdmin => 'TOOLS & ADMINISTRATION';

  @override
  String get appNameInfo => 'Application Name';

  @override
  String get versionInfo => 'Version';

  @override
  String get buildNumberInfo => 'Build Number';

  @override
  String get maxTasksCampaign => 'Max Tasks / Campaign';

  @override
  String get maxCampaignDuration => 'Max Campaign Duration';

  @override
  String get days => 'days';

  @override
  String get maxDescLength => 'Max Description Length';

  @override
  String get chars => 'characters';

  @override
  String get testNotif => 'Test Notification';

  @override
  String get featureDisabledDebug => 'Feature disabled for debug';

  @override
  String get testDisabledTemp => 'Test disabled temporarily';

  @override
  String get testBtn => 'Test';

  @override
  String get maintMode => 'Maintenance Mode';

  @override
  String get preventAccessUsersSim => 'Prevent user access (Simulation)';

  @override
  String get maintModeUpdatedSim => 'Maintenance mode updated (Simulation)';

  @override
  String get confirmLogoutTitle => 'Logout Confirmation';

  @override
  String get confirmLogoutMessage => 'Are you sure you want to log out?';

  @override
  String get logoutBtn => 'Log Out';

  @override
  String get manageCourses => 'Course Management';

  @override
  String get newTab => 'New';

  @override
  String get listTab => 'List';

  @override
  String get courseCreatedNotifSent => 'Course created + Telegram notification sent';

  @override
  String get editReschedule => 'Edit / Reschedule';

  @override
  String get courseTitle => 'Course Title';

  @override
  String get required => 'Required';

  @override
  String get teacher => 'Teacher';

  @override
  String get telegramLink => 'Telegram Link';

  @override
  String get newDate => 'New Date';

  @override
  String get newTime => 'New Time';

  @override
  String get recurrence => 'Recurrence';

  @override
  String get once => 'Once';

  @override
  String get durationMin => 'Duration (min)';

  @override
  String get description => 'Description';

  @override
  String get saveBtn => 'Save';

  @override
  String get courseRescheduledNotifSent => 'Course rescheduled + Telegram notification sent';

  @override
  String get cancelCourseTitle => 'Cancel this course';

  @override
  String confirmCancelCourse(Object title) {
    return 'Do you want to cancel the course \"$title\"?';
  }

  @override
  String get cancelNotifTelegramInfo => 'An cancellation notification will be sent to the Telegram channel.';

  @override
  String get noKeepBtn => 'No, keep';

  @override
  String get yesCancelBtn => 'Yes, cancel the course';

  @override
  String get courseCanceledNotifSent => 'Course canceled + Telegram notification sent';

  @override
  String get deleteCourseTitle => 'Delete this course';

  @override
  String confirmDeleteCourseSilent(Object title) {
    return 'Do you want to delete \"$title\" without notifying the channel?';
  }

  @override
  String get noBtn => 'No';

  @override
  String get deleteBtn => 'Delete';

  @override
  String get courseDeleted => 'Course deleted';

  @override
  String get teacherOptional => 'Teacher name (optional)';

  @override
  String get telegramLinkChannel => 'Telegram Link (Channel)';

  @override
  String get startDate => 'Start Date';

  @override
  String get descOptional => 'Description (optional)';

  @override
  String get createAndNotifyTelegram => 'Create course + Notify Telegram';

  @override
  String get noCoursesCreated => 'No courses have been created.';

  @override
  String get editBtn => 'Edit';

  @override
  String get deleteTooltip => 'Delete (no notification)';

  @override
  String get accessDenied => 'Access Denied';

  @override
  String get noAdminRights => 'Your account does not have administrator rights.';

  @override
  String get logoutNav => 'Logout';

  @override
  String get recurrenceWeekly => 'Every week';

  @override
  String get recurrenceDaily => 'Every day';

  @override
  String get recurrenceOnce => 'Once';

  @override
  String get adminTitle => 'ADMIN';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get contentSection => 'CONTENT';

  @override
  String get authors => 'Authors';

  @override
  String get importYouTube => 'Import YouTube';

  @override
  String get silsilas => 'Silsilas';

  @override
  String get courses => 'Courses';

  @override
  String get islamicQuiz => 'Islamic Quiz';

  @override
  String get communitySection => 'COMMUNITY';

  @override
  String get wazifaLoc => 'Wazifa Location';

  @override
  String get users => 'Users';

  @override
  String get systemSection => 'SYSTEM';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get noCampaignsFound => 'No campaigns found';

  @override
  String get low => 'Slow';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'Fast';

  @override
  String get learning => 'Learning';

  @override
  String get testKnowledge => 'Test your knowledge';

  @override
  String get start => 'Start';

  @override
  String get quizAlreadyCompleted => 'Quiz already completed';

  @override
  String get review => 'Review';

  @override
  String get practice => 'Practice';

  @override
  String get practiceMode => 'Practice mode';

  @override
  String get reward => 'Reward';

  @override
  String get quizReviewed => 'Quiz reviewed';

  @override
  String get congratulations => 'Congratulations';

  @override
  String get gameOver => 'Game over';

  @override
  String get youObtained => 'You obtained';

  @override
  String get unknown => 'Unknown';

  @override
  String get campaignDetails => 'Campaign Details';

  @override
  String get enterCampaignAccessCode => 'Enter the campaign access code';

  @override
  String get secretCode => 'Secret code';

  @override
  String get join => 'Join';
}
