import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_power_manager/android_power_manager.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:friday_app/services/prayer_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Use this in foreground UI context
  static Future<void> initializeForeground() async {
    await _initializeTimeZone();
    await _initializePlugin();
    await _requestPermissionsAndSettings(); // Foreground only
    await _createNotificationChannel();
  }

  /// Use this in background isolate like Workmanager
  static Future<void> initializeBackground() async {
    await _initializeTimeZone();
    await _initializePlugin();
    await _createNotificationChannel();
  }

  static Future<void> _initializePlugin() async {
    const android = AndroidInitializationSettings('ic_stat_popup2');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: iOS);

    await _plugin.initialize(settings);
  }

  static Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();
    final localZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localZone));
    debugPrint("⏰ Local Timezone: $localZone");
  }

  static Future<void> _requestPermissionsAndSettings() async {
    if (!Platform.isAndroid) return;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await androidImpl?.requestNotificationsPermission();
    debugPrint("🔐 Notification permission granted: $granted");

    if (sdkInt >= 31) await _openExactAlarmSettings();
    await _requestIgnoreBatteryOptimizations();
    await _handleBackgroundPermissions(androidInfo.brand);
  }

  static Future<void> _createNotificationChannel() async {
    const channel = AndroidNotificationChannel(
      'prayer_channel',
      'Prayer Notifications',
      description: 'Daily prayer notifications for prayer times',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  static NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_channel',
        'Prayer Notifications',
        channelDescription: 'Daily prayer notifications for prayer times',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_stat_popup2',
        largeIcon: DrawableResourceAndroidBitmap('ic_stat_popup2'),
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _details());
  }

  static Future<void> scheduleNotification({
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
        _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('✅ Scheduled $title at $scheduledTime');
    } catch (e) {
      debugPrint('❌ Error scheduling $title: $e');
    }
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();

  static Future<void> notificationPopUp() async {
    final prayerTimes = await PrayerService().getPrayerTimes();
    final now = DateTime.now();

    for (final entry in prayerTimes.entries) {
      final name = entry.key;
      if (name == 'Sunrise') continue;

      final parsed = DateFormat.jm().parse(entry.value);
      var target = DateTime(
        now.year,
        now.month,
        now.day,
        parsed.hour,
        parsed.minute,
      );
      if (target.isBefore(now)) target = target.add(const Duration(days: 1));

      await scheduleNotification(
        id: name.hashCode,
        title: "$name Prayer",
        body: "It's time for $name prayer.",
        scheduledTime: target,
      );

      final preTime = target.subtract(const Duration(minutes: 10));
      if (preTime.isAfter(now)) {
        await scheduleNotification(
          id: name.hashCode + 100,
          title: "$name Prayer Soon",
          body: "$name prayer in 10 minutes.",
          scheduledTime: preTime,
        );
      }
    }

    await _scheduleSurahAlKahf();
  }

  static Future<void> _scheduleSurahAlKahf() async {
    final now = DateTime.now();
    DateTime nextFriday = DateTime(now.year, now.month, now.day, 9);

    // Move to next Friday if today is not Friday or it's already past 9 AM today
    if (now.weekday != DateTime.friday || now.isAfter(nextFriday)) {
      do {
        nextFriday = nextFriday.add(const Duration(days: 1));
      } while (nextFriday.weekday != DateTime.friday);
    }

    await scheduleNotification(
      id: 999,
      title: "Surah Al-Kahf",
      body: "قراءة سورة الكهف يوم الجمعة تضيء للمسلم ما بين الجمعتين",
      scheduledTime: nextFriday,
    );
  }

  // ================= Permissions & Device Settings =================

  static Future<void> _handleBackgroundPermissions(String brand) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('shownBackgroundPopup') ?? false) return;

    const brands = ['oppo', 'vivo', 'xiaomi', 'realme', 'redmi', 'bbk'];
    if (brands.any((b) => brand.toLowerCase().contains(b))) {
      _showPermissionDialog();
      await _openAutostartSettings();
    }

    await prefs.setBool('shownBackgroundPopup', true);
  }

  static void _showPermissionDialog() {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Enable Background Features"),
          content: const Text(
            "To ensure prayer notifications and location tracking work reliably:\n\n"
            "• Allow background activity\n"
            "• Enable autostart (if available)\n"
            "• Disable battery optimizations",
          ),
          actions: [
            TextButton(
              child: const Text("Open Settings"),
              onPressed: () async {
                await _openBatterySettings();
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Later"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    });
  }

  static Future<void> _requestIgnoreBatteryOptimizations() async {
    try {
      final isIgnoring =
          await AndroidPowerManager.isIgnoringBatteryOptimizations;
      if (isIgnoring == false) {
        final success =
            await AndroidPowerManager.requestIgnoreBatteryOptimizations();
        debugPrint(
          success! ? "✅ Battery optimization ignored" : "❌ Request failed",
        );
      } else {
        debugPrint("✅ Already ignoring battery optimizations.");
      }
    } catch (e) {
      debugPrint("🛑 Battery optimization request error: $e");
    }
  }

  static Future<void> _openBatterySettings() async {
    try {
      await const AndroidIntent(
        action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
      ).launch();
    } catch (e) {
      debugPrint('⚠️ Could not open battery settings: $e');
    }
  }

  static Future<void> _openAutostartSettings() async {
    const intents = [
      'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
      'com.coloros.safecenter/com.coloros.safecenter.permission.startup.StartupAppListActivity',
      'com.iqoo.secure/com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity',
      'com.huawei.systemmanager/.startupmgr.ui.StartupNormalAppListActivity',
    ];

    for (final component in intents) {
      try {
        await AndroidIntent(componentName: component).launch();
        debugPrint("🚀 Opened autostart settings");
        return;
      } catch (_) {}
    }
    debugPrint("⚠️ Failed to open any autostart settings.");
  }

  static Future<void> _openExactAlarmSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('exactAlarmAllowed') ?? false) {
      debugPrint("⏰ Exact alarm already allowed");
      return;
    }

    try {
      await const AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
      ).launch();
      await prefs.setBool('exactAlarmAllowed', true);
    } catch (e) {
      debugPrint('⚠️ Could not launch exact alarm settings: $e');
    }
  }
}
