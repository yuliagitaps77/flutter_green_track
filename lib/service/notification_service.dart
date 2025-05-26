import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_green_track/widgets/permission_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NotificationService extends GetxService {
  static const String PERMISSION_ASKED_KEY = 'notification_permission_asked';
  final RxBool permissionGranted = false.obs;

  Future<void> checkAndRequestPermission() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAskedBefore = prefs.getBool(PERMISSION_ASKED_KEY) ?? false;

    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    permissionGranted.value = isAllowed;

    if (!isAllowed && !hasAskedBefore) {
      await prefs.setBool(PERMISSION_ASKED_KEY, true);
      Get.dialog(
        NotificationPermissionDialog(
          onPermissionGranted: () {
            permissionGranted.value = true;
          },
        ),
        barrierDismissible: false,
      );
    }
  }

  Future<void> initNotification() async {
    try {
      print('Initializing Awesome Notifications...');

      // Check if notifications are already initialized
      final isInitialized =
          await AwesomeNotifications().isNotificationAllowed();
      print('Notifications already initialized: $isInitialized');

      final initialized = await AwesomeNotifications().initialize(
        null, // Removing icon here as it might cause issues in release mode
        [
          NotificationChannel(
            channelKey: 'care_schedule_channel',
            channelName: 'Jadwal Perawatan',
            channelDescription: 'Notifikasi untuk jadwal perawatan tanaman',
            defaultColor: const Color(0xFF4CAF50),
            ledColor: Colors.white,
            importance: NotificationImportance.High,
            defaultRingtoneType: DefaultRingtoneType.Notification,
            enableVibration: true,
            playSound: true,
            criticalAlerts: true,
            onlyAlertOnce: false,
            defaultPrivacy: NotificationPrivacy.Public,
            locked: true,
          ),
        ],
        debug: false, // Set to false for release mode
      );
      print('Awesome Notifications initialization result: $initialized');

      // Explicitly request permissions after initialization
      final isAllowed = await AwesomeNotifications()
          .requestPermissionToSendNotifications(permissions: [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light,
        NotificationPermission.PreciseAlarms,
      ]);
      print('Notification permissions granted: $isAllowed');

      if (!isAllowed) {
        print('Notification permissions were denied');
        return;
      }

      // Set up listeners
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
      // Rethrow in release mode to ensure we catch all issues
      if (!kDebugMode) rethrow;
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

      // Verify permissions before scheduling
      final isAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (!isAllowed) {
        print('Notification permissions not granted, requesting...');
        final granted =
            await AwesomeNotifications().requestPermissionToSendNotifications();
        if (!granted) {
          print('Notification permission request denied');
          return;
        }
      }

      final notificationId =
          scheduledDate.millisecondsSinceEpoch.remainder(100000);
      final emoji = _getEmoji(title.split(' ')[1]);

      // Schedule main notification
      final mainScheduleResult =
          await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: 'care_schedule_channel',
          title: '$emoji $title',
          body: body,
          notificationLayout: NotificationLayout.Default,
          criticalAlert: true,
          wakeUpScreen: true,
          category: NotificationCategory.Reminder,
          displayOnForeground: true,
          displayOnBackground: true,
          payload: {'type': 'schedule', 'data': payload ?? ''},
        ),
        schedule: NotificationCalendar.fromDate(
          date: scheduledDate,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );

      print('Main notification schedule result: $mainScheduleResult');

      // Schedule reminder (30 minutes before)
      final reminderTime = scheduledDate.subtract(const Duration(minutes: 30));
      if (reminderTime.isAfter(DateTime.now())) {
        final reminderScheduleResult =
            await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: reminderTime.millisecondsSinceEpoch.remainder(100000),
            channelKey: 'care_schedule_channel',
            title: '⏰ Pengingat: $title',
            body: 'Jadwal perawatan akan dimulai dalam 30 menit\n$body',
            notificationLayout: NotificationLayout.Default,
            category: NotificationCategory.Reminder,
            displayOnForeground: true,
            displayOnBackground: true,
            payload: {'type': 'reminder', 'data': payload ?? ''},
          ),
          schedule: NotificationCalendar.fromDate(
            date: reminderTime,
            allowWhileIdle: true,
            preciseAlarm: true,
          ),
        );
        print('Reminder notification schedule result: $reminderScheduleResult');
      }

      // Verify scheduled notifications
      final pendingNotifications =
          await AwesomeNotifications().listScheduledNotifications();
      print('Current pending notifications: ${pendingNotifications.length}');
      for (var notification in pendingNotifications) {
        print(
            'Scheduled notification: ${notification.content?.title} at ${notification.schedule?.toMap()}');
      }
    } catch (e, stackTrace) {
      print('Error scheduling notification: $e');
      print('Stack trace: $stackTrace');
      if (!kDebugMode) rethrow;
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
