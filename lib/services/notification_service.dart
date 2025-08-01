import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Scheduling and Showing local Notification.
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io'; // Check the platform(iOS/Android).
import 'package:friday_app/services/prayer_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Used to persist small values
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:android_intent_plus/android_intent.dart'; // Opens Android system settings.

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  //* Initialize
  static Future<void> initialize() async {
    tz.initializeTimeZones();

    // STEP 2: Set the device’s timezone (example: Africa/Cairo) (Dynamic)
    final String localZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localZone));
    debugPrint("Local Timezone : $localZone");
    //     tzData.initializeTimeZones(); // Initializes time zones
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_stat_popup2');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await notificationsPlugin.initialize(settings);

    //  Ask for permission on Android 13+ (API 33+)
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      final androidImplementation = notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await androidImplementation
          ?.requestNotificationsPermission();
      debugPrint("🔐 Notification permission granted: $granted");

      // Android 12+ exact alarm permission
      if (sdkInt >= 31) {
        await openExactAlarmSettings();
      }
      // Background PopUp
      await _backgroundPermissions(androidInfo.brand);
    }

    //  Add this for Android 8+ (Oreo)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'prayer_channel', // Must match the one used in details
      'Prayer Notifications',
      description: 'Daily prayer notifications for prayer times',
      importance: Importance.max,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  //* Notification Details Setup
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_channel',
        'Prayer Notifications',
        icon: 'ic_stat_popup2',
        largeIcon: DrawableResourceAndroidBitmap('ic_stat_popup2'),
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  //* Show Notifications
  static Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      await notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationService().notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint('Notification Scheduled Successfully');
    } catch (e) {
      debugPrint('Erro Scheduling Notification : $e');
    }
  }

  //* Cancel Notification before scheduling new ones
  Future<void> cancelAllNotification() async {
    await notificationsPlugin.cancelAll();
  }

  static Future<void> notificationPopUp() async {
    final popUp = await PrayerService().getPrayerTimes();
    // Schedule notifications
    DateTime nextFriday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      9,
      0,
    ); // 9:00 AM
    while (nextFriday.weekday != DateTime.friday) {
      nextFriday = nextFriday.add(const Duration(days: 1));
    }
    // If Friday is today but the time has passed, schedule for next week
    if (nextFriday.isBefore(DateTime.now())) {
      nextFriday = nextFriday.add(const Duration(days: 7));
    }

    for (final entry in popUp.entries) {
      final now = DateTime.now();
      final name = entry.key;
      final timeString = entry.value;
      final parsedTime = DateFormat.jm().parse(timeString);
      final nowDate = DateTime.now();
      final dateTime = DateTime(
        nowDate.year,
        nowDate.month,
        nowDate.day,
        parsedTime.hour,
        parsedTime.minute,
      );
      DateTime finalDateTime = dateTime.isBefore(now)
          ? dateTime.add(const Duration(days: 1))
          : dateTime;
      debugPrint("🔔 Scheduling $name at $finalDateTime");
      if (finalDateTime.isAfter(now) && name != 'Sunrise') {
        // a. At the time of prayer
        NotificationService.schedulePrayerNotification(
          id: name.hashCode,
          title: "$name Prayer",
          body: "It's time for $name prayer.",
          scheduledTime: finalDateTime,
        );
        // b. 10 minutes before prayer
        final preNotification = finalDateTime.subtract(
          const Duration(minutes: 10),
        );
        if (preNotification.isAfter(now) && name != 'Sunrise') {
          NotificationService.schedulePrayerNotification(
            id: name.hashCode + 100,
            title: "$name Prayer Soon",
            body: "$name prayer in 10 minutes.",
            scheduledTime: preNotification,
          );
        }
        debugPrint("⏰ Scheduled $name at $finalDateTime");
      } else {
        debugPrint("⚠️ Skipped $name — $finalDateTime is in the past");
      }
    }
    if (nextFriday.isAfter(DateTime.now())) {
      NotificationService.schedulePrayerNotification(
        id: 999,
        title: "Surah Al-Kahf",
        body: "قراءة سورة الكهف يوم الجمعة تضيء للمسلم ما بين الجمعتين",
        scheduledTime: nextFriday,
      );
    }
  }

  // 🔋 Handle Battery and Background Permissions Popup
  static Future<void> _backgroundPermissions(String brand) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('shownBackgroundPopup') ?? false;
    if (shown) return;

    final lowerBrand = brand.toLowerCase();
    if (lowerBrand.contains("oppo") ||
        lowerBrand.contains("vivo") ||
        lowerBrand.contains("xiaomi") ||
        lowerBrand.contains("realme")) {
      _showPermissionDialog();
    }

    await prefs.setBool('shownBackgroundPopup', true);
  }

  static void _showPermissionDialog() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enable Background Features"),
        content: const Text(
          "To ensure prayer notifications and location tracking work reliably:\n\n"
          "• Allow background activity\n"
          "• Enable autostart (if available)\n"
          "• Disable battery optimizations",
        ),
        actions: [
          TextButton(
            onPressed: () {
              _openBatterySettings();
              Navigator.of(context).pop();
            },
            child: const Text("Open Settings"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Later"),
          ),
        ],
      ),
    );
  }

  static Future<void> _openBatterySettings() async {
    final intent = AndroidIntent(
      action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
    );
    try {
      await intent.launch();
    } catch (e) {
      debugPrint('Could not open battery settings: $e');
    }
  }
}

Future<void> openExactAlarmSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final hasOpenedSettings = prefs.getBool('exactAlarmAllowed') ?? false;

  if (hasOpenedSettings) {
    debugPrint("Exact alarm already allowed, skipping settings");
    return;
  }

  final intent = AndroidIntent(
    action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
  );

  try {
    await intent.launch();
    await prefs.setBool('exactAlarmAllowed', true);
  } catch (e) {
    debugPrint('Could not launch settings: $e');
  }
}
