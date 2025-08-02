import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'package:friday_app/database/habit_database.dart';
import 'package:friday_app/providers/prayer_provider.dart';
import 'package:friday_app/services/notification_service.dart';
import 'package:friday_app/pages/splash_screen.dart';
import 'package:friday_app/utils/app_theme.dart';
import 'services/background_callback.dart';

@pragma('vm:entry-point')
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeApp();
  runApp(const MyApp());
}

Future<void> initializeApp() async {
  try {
    await NotificationService.initializeForeground(); // For foreground usage
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      "dailyPrayerTask",
      "dailyPrayerTask",
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(minutes: 2),
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  } catch (e) {
    debugPrint('InitializeApp Error: $e');
  }

  await HabitDatabase.initialize();
  await HabitDatabase().saveFirstLaunchDate();
  await HabitDatabase().insertFiveHabitsIfNeeded();

  await NotificationService.cancelAll();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitDatabase()),
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Friday',
        theme: appTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
