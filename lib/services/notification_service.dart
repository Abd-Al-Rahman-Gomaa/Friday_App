import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:android_power_manager/android_power_manager.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:friday_app/services/prayer_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ------------------- INIT -------------------
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    final String zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone));
    debugPrint("⏰ Timezone set to $zone");

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

    await _plugin.initialize(settings);

    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }

    await _createNotificationChannel();
  }

  // ------------------- PERMISSION HELPERS -------------------
  static Future<void> _requestAndroidPermissions() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final granted = await androidPlugin?.requestNotificationsPermission();
    debugPrint("🔐 Notification permission granted: $granted");

    if (sdkInt >= 31) {
      await _openExactAlarmSettings();
    }

    await _requestIgnoreBatteryOptimizations();

    // Do NOT show UI here; move _backgroundPermissionsUI to the UI layer
  }

  static Future<void> _requestIgnoreBatteryOptimizations() async {
    try {
      final isIgnoring =
          await AndroidPowerManager.isIgnoringBatteryOptimizations;
      if (isIgnoring != true) {
        final success =
            await AndroidPowerManager.requestIgnoreBatteryOptimizations();
        debugPrint(
          success!
              ? "✅ Battery optimization ignored"
              : "❌ Failed to ignore battery optimization",
        );
      }
    } catch (e) {
      debugPrint("🛑 Battery optimization error: $e");
    }
  }

  static Future<void> _openExactAlarmSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('exactAlarmAllowed') == true) return;

    final intent = AndroidIntent(
      action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
    );
    try {
      await intent.launch();
      await prefs.setBool('exactAlarmAllowed', true);
    } catch (e) {
      debugPrint("⚠️ Could not launch exact alarm settings: $e");
    }
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'prayer_channel',
      'Prayer Notifications',
      description: 'Daily prayer notifications for prayer times',
      importance: Importance.max,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(channel);
  }

  // ------------------- BACKGROUND UI - CALLED FROM MAIN -------------------
  static Future<void> showAutostartAndBatteryDialogFromUI(
    BuildContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('shownBackgroundPopup') == true) return;

    final brand = (await DeviceInfoPlugin().androidInfo).brand.toLowerCase();
    if (brand.contains('oppo') ||
        brand.contains('vivo') ||
        brand.contains('xiaomi') ||
        brand.contains('realme') ||
        brand.contains('redmi') ||
        brand.contains('bbk')) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Enable Background Features"),
          content: const Text(
            "To ensure prayer notifications work reliably:\n\n"
            "• Allow background activity\n"
            "• Enable autostart (if available)\n"
            "• Disable battery optimizations",
          ),
          actions: [
            TextButton(
              onPressed: () {
                openBatterySettings();
                openAutostartSettings();
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

    await prefs.setBool('shownBackgroundPopup', true);
  }

  static Future<void> openBatterySettings() async {
    final intent = AndroidIntent(
      action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
    );
    try {
      await intent.launch();
    } catch (e) {
      debugPrint("⚠️ Could not open battery settings: $e");
    }
  }

  static Future<void> openAutostartSettings() async {
    final intents = [
      'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
      'com.coloros.safecenter/com.coloros.safecenter.permission.startup.StartupAppListActivity',
      'com.iqoo.secure/com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity',
      'com.huawei.systemmanager/.startupmgr.ui.StartupNormalAppListActivity',
    ];

    for (final path in intents) {
      try {
        await AndroidIntent(componentName: path).launch();
        return;
      } catch (_) {}
    }
    debugPrint("⚠️ Could not open any autostart settings");
  }

  // ------------------- NOTIFICATIONS -------------------
  NotificationDetails _notificationDetails() => const NotificationDetails(
    android: AndroidNotificationDetails(
      'prayer_channel',
      'Prayer Notifications',
      icon: 'ic_stat_popup2',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  static Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationService()._notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint("✅ Scheduled notification: $title @ $scheduledTime");
    } catch (e) {
      debugPrint("❌ Scheduling failed: $e");
    }
  }

  Future<void> cancelAll() async => await _plugin.cancelAll();

  static Future<void> notificationPopUp() async {
    final popUp = await PrayerService().getPrayerTimes();
    final now = DateTime.now();

    for (final entry in popUp.entries) {
      final name = entry.key;
      if (name == 'Sunrise') continue;

      final time = DateFormat.jm().parse(entry.value);
      final scheduled = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
      finalDateTime(
        name,
        scheduled.isBefore(now) ? scheduled.add(Duration(days: 1)) : scheduled,
      );
    }

    final DateTime nextFriday = _nextFriday();
    await schedulePrayerNotification(
      id: 999,
      title: "Surah Al-Kahf",
      body: "قراءة سورة الكهف يوم الجمعة تضيء للمسلم ما بين الجمعتين",
      scheduledTime: nextFriday,
    );
  }

  static Future<void> finalDateTime(String name, DateTime dateTime) async {
    await schedulePrayerNotification(
      id: name.hashCode,
      title: "$name Prayer",
      body: "It's time for $name prayer.",
      scheduledTime: dateTime,
    );
    await schedulePrayerNotification(
      id: name.hashCode + 100,
      title: "$name Prayer Soon",
      body: "$name prayer in 10 minutes.",
      scheduledTime: dateTime.subtract(const Duration(minutes: 10)),
    );
  }

  static DateTime _nextFriday() {
    DateTime now = DateTime.now();
    while (now.weekday != DateTime.friday) {
      now = now.add(const Duration(days: 1));
    }
    return now.hour >= 9
        ? now.add(const Duration(days: 7)).copyWith(hour: 9)
        : now.copyWith(hour: 9);
  }
}
