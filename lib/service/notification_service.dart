import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationService extends GetxService {
  Future<void> initNotification() async {
    try {
      print('Initializing Awesome Notifications...');
      final initialized = await AwesomeNotifications().initialize(
        'resource://drawable/ic_notification',
        [
          NotificationChannel(
            channelKey: 'care_schedule_channel',
            channelName: 'Jadwal Perawatan',
            channelDescription: 'Notifikasi untuk jadwal perawatan tanaman',
            defaultColor: const Color(0xFF4CAF50),
            ledColor: Colors.white,
            importance: NotificationImportance.Max,
            defaultRingtoneType: DefaultRingtoneType.Alarm,
            enableVibration: true,
            playSound: true,
            criticalAlerts: true,
            locked: true,
            defaultPrivacy: NotificationPrivacy.Public,
            soundSource: 'resource://raw/notification_sound',
          ),
        ],
        debug: true,
      );
      print('Awesome Notifications initialized: $initialized');

      // Request notification permissions with critical alerts
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      print('Notifications allowed: $isAllowed');

      if (!isAllowed) {
        print('Requesting notification permissions...');
        final permissionGranted = await AwesomeNotifications()
            .requestPermissionToSendNotifications(permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
          NotificationPermission.FullScreenIntent,
          NotificationPermission.CriticalAlert,
          NotificationPermission.PreciseAlarms,
        ]);
        print('Permission granted: $permissionGranted');
      }

      // Listen to notification events
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod,
      );
      print('Notification listeners set up successfully');
    } catch (e, stackTrace) {
      print('Error initializing notifications: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Use this method to detect when a new notification or a schedule is created
  static Future<void> onNotificationCreatedMethod(
      ReceivedNotification receivedNotification) async {
    print('Notification created: ${receivedNotification.title}');
    print('Notification body: ${receivedNotification.body}');
    print('Notification id: ${receivedNotification.id}');
  }

  /// Use this method to detect every time that a new notification is displayed
  static Future<void> onNotificationDisplayedMethod(
      ReceivedNotification receivedNotification) async {
    print('Notification displayed: ${receivedNotification.title}');
    print('Notification body: ${receivedNotification.body}');
    print('Notification id: ${receivedNotification.id}');
  }

  /// Use this method to detect if the user dismissed a notification
  static Future<void> onDismissActionReceivedMethod(
      ReceivedAction receivedAction) async {
    print('Notification dismissed: ${receivedAction.title}');
    print('Notification id: ${receivedAction.id}');
  }

  /// Use this method to detect when the user taps on a notification or action button
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    print('Notification action received: ${receivedAction.title}');
    print('Notification id: ${receivedAction.id}');
    print('Notification payload: ${receivedAction.payload}');

    final payload = receivedAction.payload ?? {};
    if (payload['type'] == 'schedule') {
      print('Schedule notification tapped with payload: $payload');
    }
  }

  String _getEmoji(String jenisPerawatan) {
    switch (jenisPerawatan.toLowerCase()) {
      case 'penyiraman':
        return '💧';
      case 'pemupukan':
        return '🌱';
      case 'pengecekan':
        return '👀';
      case 'penyiangan':
        return '🌿';
      case 'penyemprotan':
        return '💨';
      case 'pemangkasan':
        return '✂️';
      default:
        return '🌺';
    }
  }

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      print(
          'Attempting to schedule notification for: ${scheduledDate.toString()}');
      print('Title: $title');
      print('Body: $body');

      bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
      print('Notifications allowed: $isAllowed');

      if (!isAllowed) {
        print('Requesting notification permissions...');
        isAllowed = await AwesomeNotifications()
            .requestPermissionToSendNotifications(permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.Light,
          NotificationPermission.FullScreenIntent,
          NotificationPermission.CriticalAlert,
          NotificationPermission.PreciseAlarms,
        ]);
        print('Permission granted: $isAllowed');
      }

      if (!isAllowed) {
        print('Notification permission denied');
        return;
      }

      final notificationId =
          scheduledDate.millisecondsSinceEpoch.remainder(100000);
      print('Generated notification ID: $notificationId');

      // Extract jenis perawatan from title for emoji
      final jenisPerawatan = title.split(' ')[1];
      final emoji = _getEmoji(jenisPerawatan);

      // Schedule notification for the exact time
      final mainNotificationScheduled =
          await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'care_schedule_channel',
          title: '$emoji $title',
          body: body,
          notificationLayout: NotificationLayout.BigText,
          criticalAlert: true,
          wakeUpScreen: true,
          fullScreenIntent: true,
          category: NotificationCategory.Alarm,
          displayOnForeground: true,
          displayOnBackground: true,
          backgroundColor: const Color(0xFFE8F5E9),
          color: const Color(0xFF2E7D32),
          largeIcon: 'resource://drawable/ic_notification',
          payload: {
            'type': 'schedule',
            'data': payload ?? '',
          },
        ),
        schedule: NotificationCalendar(
          year: scheduledDate.year,
          month: scheduledDate.month,
          day: scheduledDate.day,
          hour: scheduledDate.hour,
          minute: scheduledDate.minute,
          second: 0,
          millisecond: 0,
          repeats: false,
          preciseAlarm: true,
          allowWhileIdle: true,
          timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'MARK_DONE',
            label: 'Tandai Selesai',
            actionType: ActionType.Default,
          ),
          NotificationActionButton(
            key: 'SNOOZE',
            label: 'Ingatkan Nanti',
            actionType: ActionType.Default,
          ),
        ],
      );
      print('Main notification scheduled: $mainNotificationScheduled');

      // Schedule reminder 30 minutes before
      final reminderTime = scheduledDate.subtract(const Duration(minutes: 30));
      if (reminderTime.isAfter(DateTime.now())) {
        print(
            'Scheduling reminder notification for: ${reminderTime.toString()}');
        final reminderNotificationScheduled =
            await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: reminderTime.millisecondsSinceEpoch.remainder(100000),
            channelKey: 'care_schedule_channel',
            title: '⏰ Pengingat: $title',
            body: 'Jadwal perawatan akan dimulai dalam 30 menit\n$body',
            notificationLayout: NotificationLayout.BigText,
            criticalAlert: true,
            wakeUpScreen: true,
            fullScreenIntent: true,
            category: NotificationCategory.Reminder,
            displayOnForeground: true,
            displayOnBackground: true,
            backgroundColor: const Color(0xFFE8F5E9),
            color: const Color(0xFF2E7D32),
            largeIcon: 'resource://drawable/ic_notification',
            payload: {
              'type': 'reminder',
              'data': payload ?? '',
            },
          ),
          schedule: NotificationCalendar(
            year: reminderTime.year,
            month: reminderTime.month,
            day: reminderTime.day,
            hour: reminderTime.hour,
            minute: reminderTime.minute,
            second: 0,
            millisecond: 0,
            repeats: false,
            preciseAlarm: true,
            allowWhileIdle: true,
            timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(),
          ),
          actionButtons: [
            NotificationActionButton(
              key: 'SHOW_SCHEDULE',
              label: 'Lihat Jadwal',
              actionType: ActionType.Default,
            ),
          ],
        );
        print(
            'Reminder notification scheduled: $reminderNotificationScheduled');
      } else {
        print('Skipping reminder notification as it would be in the past');
      }

      print('Notification scheduling completed successfully');
    } catch (e, stackTrace) {
      print('Error scheduling notification: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await AwesomeNotifications().cancelAll();
      print('All notifications cancelled');
    } catch (e) {
      print('Error cancelling notifications: $e');
      rethrow;
    }
  }
}
