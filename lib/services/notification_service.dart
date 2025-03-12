// lib/services/notification_service.dart

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance =
      NotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the notification service
  Future<void> initialize() async {
    // Initialize time zones
    tz_data.initializeTimeZones();
    String timeZoneName = 'UTC';
    try {
      timeZoneName = await FlutterTimezone.getLocalTimezone();
      debugPrint('Local timezone: $timeZoneName');
    } catch (e) {
      debugPrint('Could not get the local timezone: $e');
    }
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onSelectNotification,
    );

    // Request notification permissions
    // await requestNotificationPermissions();

    // Create notification channel
    await _createNotificationChannel();
  }

  /// Request notification permissions (Android 13+)
  // Future<void> requestNotificationPermissions() async {
  //   // Check if the app is running on Android
  //   if (Platform.isAndroid) {
  //     debugPrint('Requesting notification permissions for Android.');

  //     // Use the permission_handler package to request permissions
  //     PermissionStatus status = await Permission.notification.status;

  //     if (status.isDenied || status.isPermanentlyDenied) {
  //       // Request the permission
  //       status = await Permission.notification.request();
  //     }

  //     if (status.isGranted) {
  //       debugPrint('Notification permissions granted.');
  //     } else {
  //       debugPrint('Notification permissions denied.');
  //     }
  //   } else {
  //     debugPrint('Notification permissions are not required on this platform.');
  //   }
  // }

  /// Show a dialog prompting the user to grant notification permissions
  // void _showPermissionDeniedDialog() {
  //   // Since this is a service class, you might need to use a navigator key
  //   // or another method to access the BuildContext.
  //   debugPrint('Please enable notification permissions in settings.');
  // }

  /// Create a notification channel
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'medication_channel_id',
      'Medication Reminders',
      description:
          'Channel for medication reminder notifications', // description
      importance: Importance.max,
    );

    // Create the notification channel
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('Notification channel created: ${channel.id}');
  }

  /// Show an immediate notification (one-time) on Android
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medication_channel_id', // must match the channel ID
      'Medication Reminders',
      channelDescription: 'Channel for medication reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    // Immediately show the notification
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
    );

    debugPrint('Immediate notification shown with ID: $id');
  }

  /// Handle notification tap
  void onSelectNotification(NotificationResponse notificationResponse) async {
    String? payload = notificationResponse.payload;
    debugPrint('Notification tapped with payload: $payload');
  }

  /// Schedule notifications based on repeat days
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    required List<String> repeatDays,
    required String compartmentId,
    required String alarmId,
    required Future<void> Function() onTrigger, // Callback for custom actions
  }) async {
    for (String day in repeatDays) {
      int weekday = _dayStringToInt(day);
      debugPrint('Scheduling for day: $day (weekday: $weekday) at $time');

      // Use full-screen intent (Android only) to show an alarm-style screen
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'medication_channel_id', // Must match the channel ID
        'Medication Reminders', // Must match the channel name
        channelDescription: 'Channel for medication reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        // Enable full-screen:
        fullScreenIntent: true,
        // Category set to alarm to hint Android it's a high-priority alarm
        category: AndroidNotificationCategory.alarm,
      );

      final NotificationDetails notificationDetails =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      // Schedule the notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        _generateNotificationId(alarmId, weekday, time),
        title,
        body,
        _nextInstanceOfWeekdayTime(weekday, time),
        notificationDetails,
        androidScheduleMode:
            AndroidScheduleMode.inexactAllowWhileIdle, // to allow background
        payload: alarmId, // Pass alarmId as payload for reference
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      debugPrint(
          'Notification scheduled for weekday $weekday at $time with ID ${_generateNotificationId(alarmId, weekday, time)}');

      // Trigger pill dispensing when the alarm fires
      _triggerAtScheduledTime(
        weekday,
        time,
        onTrigger,
      );
    }
  }

  /// Trigger custom actions (e.g., pill dispensing) at the scheduled time
  void _triggerAtScheduledTime(
    int weekday,
    TimeOfDay time,
    Future<void> Function() onTrigger,
  ) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = _nextInstanceOfWeekdayTime(weekday, time);
    debugPrint('now: $now');
    debugPrint('Scheduled date: $scheduledDate');

    Duration durationUntilTrigger = scheduledDate.difference(now);
    debugPrint('Duration until trigger: $durationUntilTrigger');

    if (durationUntilTrigger.isNegative) {
      debugPrint('Scheduled time is in the past. Skipping trigger.');
      return;
    }

    Future.delayed(durationUntilTrigger, () async {
      NotificationService.instance.showImmediateNotification(
        id: 9999, // Unique ID for this type of notification
        title: 'Time for your medications',
        body: 'Medications are being dispensed now.',
      );

      // Play the alarm sound
      FlutterRingtonePlayer().play(
        android: AndroidSounds.alarm,
        ios: IosSounds.glass, // iOS sound
        looping: true, // Alarm sound will loop until stopped
        volume: 1.0, // Maximum volume
        asAlarm: true, // Indicate this is an alarm sound
      );

      // Trigger the custom action (e.g., pill dispensing)
      await onTrigger();

      debugPrint('Alarm triggered for weekday $weekday at $time');

      // Automatically stop the alarm sound after 30 seconds
      Future.delayed(const Duration(seconds: 30), () {
        FlutterRingtonePlayer().stop();
        debugPrint('Alarm sound stopped automatically after 30 seconds.');
      });
    });

    debugPrint(
        'Scheduled trigger in $durationUntilTrigger for weekday $weekday at $time');
  }

  /// Cancel all notifications associated with an alarmId
  Future<void> cancelNotification({
    required String alarmId,
    required List<String> repeatDays,
    required TimeOfDay time,
  }) async {
    for (String day in repeatDays) {
      int weekday = _dayStringToInt(day);
      int notificationId = _generateNotificationId(alarmId, weekday, time);
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      debugPrint('Cancelled notification with ID: $notificationId');
    }
  }

  /// Helper method to convert day string to integer
  int _dayStringToInt(String day) {
    switch (day.toLowerCase()) {
      case 'mon':
        return DateTime.monday;
      case 'tue':
        return DateTime.tuesday;
      case 'wed':
        return DateTime.wednesday;
      case 'thu':
        return DateTime.thursday;
      case 'fri':
        return DateTime.friday;
      case 'sat':
        return DateTime.saturday;
      case 'sun':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  /// Generate a unique notification ID based on alarmId, weekday, and time
  int _generateNotificationId(String alarmId, int weekday, TimeOfDay time) {
    // Example: hashCode of alarmId concatenated with weekday and time
    String idStr = '$alarmId-$weekday-${time.hour}-${time.minute}';
    return idStr.hashCode;
  }

  /// Calculate the next instance of the specified weekday and time
  tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, TimeOfDay time) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Calculate the next instance of the specified time
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Retrieve the Android SDK version
  Future<int> _getAndroidSdkInt() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt;
  }
}
