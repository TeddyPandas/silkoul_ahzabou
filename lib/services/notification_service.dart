import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/campaign.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initialize() async {
    debugPrint('🔔 [NotificationService] Initializing...');
    tz_data.initializeTimeZones();

    // Android initialization settings
    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const fln.InitializationSettings initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse response) async {
        debugPrint('🔔 [NotificationService] Notification tapped: ${response.payload}');
      },
    );

    debugPrint('🔔 [NotificationService] Requesting permissions...');
    // Request permission for Android 13+
    final bool? granted = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    debugPrint('🔔 [NotificationService] Permission status: $granted');
  }

  // ... (scheduleCampaignEndNotification omitted for brevity in search, will effectively be kept by start/end line usage if I target correctly, but wait, replace_file_content replaces the whole block.
  // I should target specific methods or use multi_replace if I want to be safe.
  // Actually, I can just replace showInstantNotification and initialize separately or just rewrite the whole file with logs if small enough.
  // It's small. Rewriting/replacing huge chunks is fine.)

  // Let's replace showInstantNotification first.

  Future<void> scheduleCampaignEndNotification(Campaign campaign) async {
    // Avoid scheduling if campaign is finished or end date is passed
    if (campaign.isFinished || campaign.endDate.isBefore(DateTime.now())) {
      return;
    }

    // Schedule 1 day before end date
    final scheduledDate = campaign.endDate.subtract(const Duration(days: 1));

    // If "1 day before" is already in the past, don't schedule
    if (scheduledDate.isBefore(DateTime.now())) {
      return;
    }

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        campaign.id.hashCode, // Unique ID based on campaign ID
        'La campagne se termine bientôt !',
        'La campagne "${campaign.name}" se termine dans 24 heures. N\'oubliez pas de terminer vos tâches !',
        tz.TZDateTime.from(scheduledDate, tz.local),
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'campaign_end_channel',
            'Fin de Campagne',
            channelDescription: 'Notifications pour la fin des campagnes',
            importance: fln.Importance.high,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: fln.DateTimeComponents.dateAndTime,
      );
      debugPrint('🔔 [NotificationService] Scheduled notification for ${campaign.name} at $scheduledDate');
    } catch (e) {
      debugPrint('❌ [NotificationService] Error scheduling notification: $e');
    }
  }

  Future<void> showInstantNotification() async {
    debugPrint('🔔 [NotificationService] showInstantNotification called');
    try {
      await flutterLocalNotificationsPlugin.show(
        888, // Special ID for test notification
        'Test Notification',
        'Ceci est une notification de test pour vérifier que tout fonctionne !',
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'campaign_end_channel',
            'Fin de Campagne',
            channelDescription: 'Notifications pour la fin des campagnes',
            importance: fln.Importance.high,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
      );
      debugPrint('🔔 [NotificationService] Notification shown successfully');
    } catch (e) {
      debugPrint('❌ [NotificationService] Error showing notification: $e');
    }
  }

  Future<void> cancelNotification(String campaignId) async {
    await flutterLocalNotificationsPlugin.cancel(campaignId.hashCode);
  }
}
