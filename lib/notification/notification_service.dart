import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🚀 Added
import 'dart:async';

// 🛑 GLOBAL TOP-LEVEL BACKGROUND HANDLER
// This function executes in its own isolate when the app is completely closed/killed!
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("📩 Handling a background cloud message: ${message.messageId}");
  // The system automatically shows a notification if the message contains a 'notification' payload,
  // or you can manually trigger your local plugin here if you pass pure 'data' payloads.
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance; // 🚀 Added

  static final StreamController<String?> selectNotificationStream = StreamController<String?>.broadcast();

  static Future<void> init() async {
    tz_data.initializeTimeZones();

    // Safe timezone resolution mapping configuration
    try {
      // 1. Fetch the value dynamically
      final dynamic timezoneData = await FlutterTimezone.getLocalTimezone();

      String timeZoneName;

      // 2. Safely check if it's already a String or an object
      if (timezoneData is String) {
        timeZoneName = timezoneData;
      } else {
        // If it's a TimezoneInfo object, calling .toString() or accessing the native runtime value resolves it
        timeZoneName = timezoneData.toString();
      }

      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint("🌎 System Timezone resolved cleanly to: $timeZoneName");
    } catch (e) {
      debugPrint("Could not settle local timezone natively, defaulting to UTC: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initializationSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          selectNotificationStream.add(response.payload);
        }
      },
    );

    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }

    // 🚀 ==================== START FIREBASE MESSAGING CONFIG ====================

    // 1. Setup the background message listener
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request iOS/Android Cloud Notification Permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('🔔 User cloud notification permission status: ${settings.authorizationStatus}');

    // 3. Foreground Listener: If the user is actively inside the app, keep it silent or trigger local alert
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('✉️ Got a message whilst in the foreground!');
      if (message.notification != null) {
        // Display a local alert overlay so they see it while playing with the app
        _showInstantNotification(
          title: message.notification!.title ?? "Task Update",
          body: message.notification!.body ?? "",
          payload: message.data['taskId'] ?? "",
        );
      }
    });

    // 4. Background Click Listener: App was suspended in RAM, user tapped notification card
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔗 Notification clicked while app in background RAM!');
      String? taskId = message.data['taskId'];
      if (taskId != null) {
        selectNotificationStream.add(taskId);
      }
    });

    // 5. Get the Device Token (Save this to Firestore 'users' collection to target this specific device)
    String? fcmToken = await _firebaseMessaging.getToken();
    debugPrint("📱 Device FCM Registration Token: $fcmToken");

    // 🚀 ==================== END FIREBASE MESSAGING CONFIG ====================
  }

  // Helper method to display instant alert banners when app is actively open
  static Future<void> _showInstantNotification({required String title, required String body, required String payload}) async {
    const androidDetails = AndroidNotificationDetails(
      'planova_cloud_alerts',
      'Cloud Updates Channel',
      importance: Importance.max,
      priority: Priority.high,
    );
    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payload,
    );
  }

  static Future<void> checkForLaunchNotification() async {
    // 1. Check local engine boot launch parameters
    final NotificationAppLaunchDetails? launchDetails = await _notificationsPlugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final String? payload = launchDetails.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        selectNotificationStream.add(payload);
        return;
      }
    }

    // 🚀 2. Check cloud engine cold boot launch parameters (App was completely terminated)
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      String? taskId = initialMessage.data['taskId'];
      if (taskId != null) {
        selectNotificationStream.add(taskId);
      }
    }
  }

  static int _getHashId(String stringId) => stringId.hashCode.remainder(100000).abs();

  static Future<void> scheduleTaskReminders({
    required String stringTaskId,
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    final now = DateTime.now();
    final int baseId = _getHashId(stringTaskId);

    DateTime correctedDueDate = dueDate;
    if (dueDate.hour == 0 && dueDate.minute == 0 && dueDate.second == 0) {
      correctedDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day, 23, 59, 59);
    }

    final reminderConfigs = [
      {'label': '2 days left', 'duration': const Duration(days: 2), 'offsetId': 200000},
      {'label': '1 day left', 'duration': const Duration(days: 1), 'offsetId': 100000},
      {'label': '1 hour left', 'duration': const Duration(hours: 1), 'offsetId': 0},
      {'label': '40 minutes left', 'duration': const Duration(minutes: 40), 'offsetId': 400000},
    ];

    final location = tz.local;

    for (var config in reminderConfigs) {
      final reminderTime = correctedDueDate.subtract(config['duration'] as Duration);

      if (reminderTime.isAfter(now)) {
        final int uniqueId = baseId + (config['offsetId'] as int);

        await _notificationsPlugin.zonedSchedule(
          uniqueId,
          'Task Reminder: $taskTitle',
          'Your task is due in ${config['label']}. Don\'t forget to complete it!',
          tz.TZDateTime.from(reminderTime, location),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'planova_task_reminders',
              'Task Reminders Channel',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: stringTaskId,
        );
        debugPrint("✅ SUCCESS: Scheduled [${config['label']}] for $taskTitle at: $reminderTime");
      }
    }
  }

  static Future<void> cancelTaskReminders(String stringTaskId) async {
    final int baseId = _getHashId(stringTaskId);
    await _notificationsPlugin.cancel(baseId + 200000);
    await _notificationsPlugin.cancel(baseId + 100000);
    await _notificationsPlugin.cancel(baseId + 0);
    await _notificationsPlugin.cancel(baseId + 400000);
  }
}