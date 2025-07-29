import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:friday_app/database/habit_database.dart';
import 'package:friday_app/providers/prayer_provider.dart';
import 'package:friday_app/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart'
    as tz; // loads timezone data (city names, offsets, etc).
import 'package:timezone/timezone.dart'
    as tz; // Allows you to use methods like getLocation() & setLocalLocation() to set time zones.
import 'package:friday_app/services/notification_service.dart';
import 'package:friday_app/pages/splash_screen.dart';
import 'package:workmanager/workmanager.dart'; // For background tasks, make your code run even if it's closed or in the background.
import 'services/background_callback.dart';

@pragma(
  'vm:entry-point',
) // Tells Flutter not to remove the following function during tree shaking (code optimization).
void main() async {
  await initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => HabitDatabase()),
        ChangeNotifierProvider(create: (context) => PrayerProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friday',
      theme: appTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensures Flutter engine is ready, needed before using plugins like Workmanager or timezone.
  try {
    await HabitDatabase.initialize();
    await HabitDatabase().saveFirstLaunchDate();
    await HabitDatabase().insertFiveHabitsIfNeeded();
    // STEP 1: Load all timezone data
    tz.initializeTimeZones();
    // STEP 2: Set the device’s timezone (example: Africa/Cairo) (WorldWide now)
    final String localZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localZone));
    debugPrint("Local Timezone : $localZone");
    await NotificationService.initialize(); // * very Important
    await openExactAlarmSettings();
    await NotificationService().cancelAllNotification();

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    // Register daily task at midnight
    await Workmanager().registerPeriodicTask(
      "dailyPrayerTask",
      "dailyPrayerTask",
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(
        hours: 0,
        minutes: 1, // ? the difference if this is 2 or 5 ?
      ), // Run soon after launch
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  } catch (e) {
    debugPrint('InitializeApp Error : $e');
  }
}
