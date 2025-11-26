import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../utils/auth_helper.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combined initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    // Initialize plugin
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android 8+
    await _createNotificationChannel();

    // Request permissions for Android 13+
    await _requestPermissions();

    _isInitialized = true;

    if (kDebugMode) {
      print('✅ Local Notifications initialized successfully');
    }
  }

  /// Create notification channel with sound and vibration
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'vms_channel', // id
      'VMS Notifications', // name
      description: 'Notifications for Visit Management System',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidImplementation?.createNotificationChannel(channel);

    if (kDebugMode) {
      print('📢 Notification channel created with sound & vibration');
    }
  }

  /// Request notification permissions (Android 13+)
  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      await androidImplementation?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();

      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('🔔 Notification tapped: ${response.payload}');
    }
    // Handle navigation based on payload
  }

  /// Show a simple notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final userIdentity = await _getLoggedInUserIdentity();
    final personalizedTitle = _decorateTitleWithUser(title, userIdentity.name);
    final personalizedBody = _decorateBodyWithUser(body, userIdentity);
    final AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'vms_channel', // Channel ID (must match channel created in initialize)
      'VMS Notifications', // Channel name
      channelDescription: 'Notifications for Visit Management System',
      importance: Importance.max, // Changed from high to max
      priority: Priority.max, // Changed from high to max
      showWhen: true,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      color: const Color.fromARGB(255, 25, 118, 210),
      ledColor: const Color.fromARGB(255, 25, 118, 210),
      ledOnMs: 1000,
      ledOffMs: 500,
      icon: '@mipmap/launcher_icon',
      channelShowBadge: true,
      onlyAlertOnce: false,
      autoCancel: true,
      ongoing: false,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'VMS',
      ),
      ticker: title,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      personalizedTitle,
      personalizedBody,
      notificationDetails,
      payload: payload,
    );

    if (kDebugMode) {
      print('📬 Notification sent:');
      print('   ID: $id');
      print('   Title: $title');
      print('   Body: $body');
    }
  }

  /// Show greeting notification for the logged-in user
  Future<void> showUserGreetingNotification() async {
    final user = await _getLoggedInUserIdentity();
    final emailText = user.email != null ? ' (${user.email})' : '';

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'Hello ${user.name}! 👋',
      body:
          'Hi ${user.name}$emailText, your VMS app is working perfectly! Notification system is active.',
      payload: 'user_greeting',
    );
  }

  /// Show visit notification
  Future<void> showVisitNotification({
    required String title,
    required String message,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
      payload: 'visit',
    );
  }

  /// Show lead notification
  Future<void> showLeadNotification({
    required String title,
    required String message,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
      payload: 'lead',
    );
  }

  /// Show reminder notification
  Future<void> showReminderNotification({
    required String title,
    required String message,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: message,
      payload: 'reminder',
    );
  }

  /// Cancel a notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Schedule a notification at a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    // Create notification channel for scheduled notifications
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'vms_scheduled_channel',
      'VMS Scheduled Notifications',
      description: 'Scheduled notifications for VMS',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidImplementation?.createNotificationChannel(channel);

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'vms_scheduled_channel',
          'VMS Scheduled Notifications',
          channelDescription: 'Scheduled notifications for VMS',
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          enableLights: true,
          icon: '@mipmap/launcher_icon',
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Convert DateTime to TZDateTime (local timezone)
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    // Schedule the notification
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    if (kDebugMode) {
      print('⏰ Notification scheduled for: $scheduledTime (ID: $id)');
      print('   Title: $title');
      print('   Body: $body');
    }
  }

  /// Schedule daily check-in reminder at 10:00 PM
  Future<void> scheduleDailyCheckInReminder() async {
    // Cancel existing reminder if any
    await cancelNotification(1001);

    // Get current date
    final now = DateTime.now();

    // Set scheduled time to 10:00 PM today
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      12, // Hour
      52, // Minute
    );

    // If current time is past 10:00 PM, schedule for tomorrow
    final targetTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await scheduleNotification(
      id: 1001, // Fixed ID for check-in reminder
      title: '⏰ Check-In Reminder',
      body:
          'Aapka working start hone vala hai! Jaldi se check-in karein, nahi to half day lagega.',
      scheduledTime: targetTime,
      payload: 'checkin_reminder',
    );

    if (kDebugMode) {
      print('📅 Daily check-in reminder scheduled for: $targetTime');
    }
  }

  /// Cancel daily check-in reminder
  Future<void> cancelDailyCheckInReminder() async {
    await cancelNotification(1001);
    if (kDebugMode) {
      print('❌ Daily check-in reminder cancelled');
    }
  }
}

class _UserIdentity {
  _UserIdentity({required this.name, this.email});

  final String name;
  final String? email;
}

Future<_UserIdentity> _getLoggedInUserIdentity() async {
  final user = await AuthHelper.getAuthenticatedUser();
  final rawName = user?['name']?.toString().trim() ?? '';
  final rawEmail = user?['email']?.toString().trim();

  return _UserIdentity(
    name: rawName.isNotEmpty ? rawName : 'User',
    email: rawEmail?.isNotEmpty == true ? rawEmail : null,
  );
}

String _decorateTitleWithUser(String title, String userName) {
  if (title.toLowerCase().contains(userName.toLowerCase())) {
    return title;
  }
  return '$title • $userName';
}

String _decorateBodyWithUser(String body, _UserIdentity user) {
  final lowerBody = body.toLowerCase();
  if (lowerBody.contains(user.name.toLowerCase())) {
    return body;
  }

  final userLine = user.email != null
      ? '${user.name} (${user.email})'
      : user.name;

  return '$body\n👤 $userLine';
}
