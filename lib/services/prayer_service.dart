import 'dart:async';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PrayerService {
  Future<Map<String, String>> getPrayerTimes() async {
    // 1. Ask for location permission
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error("Location permission not granted.");
      }
    }
    // ignore: unused_local_variable
    late LocationSettings locationSettings; //?ignore unused

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 10),
        // Set foreground notification config to keep the app alive
        //when going to the background
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText:
              "App will continue to receive your location even when you aren't using it",
          notificationTitle: "Running in Background",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    }

    // 2. Get current location
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    tz.initializeTimeZones();
    // STEP 2: Set the device’s timezone (example: Africa/Cairo)
    final localZone = await FlutterTimezone.getLocalTimezone();
    final location = tz.getLocation(localZone);

    final now = tz.TZDateTime.now(location);

    // Use UTC date to get just Y/M/D
    final dateForCalculation = DateTime(now.year, now.month, now.day);
    // 3. Define coordinates and params
    final coordinates = Coordinates(position.latitude, position.longitude);
    final params = CalculationMethod.egyptian();
    params.madhab = Madhab.shafi;
    // 4. Calculate times
    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      calculationParameters: params,
      date: dateForCalculation,
    );
    // final localOffset = Duration(hours: 3); hard-coded
    // 5. Format times
    final timeFormat = DateFormat.jm();
    final prayerDateTimes = {
      "Fajr": tz.TZDateTime.from(prayerTimes.fajr!, location),
      "Sunrise": tz.TZDateTime.from(prayerTimes.sunrise!, location),
      "Dhuhr": tz.TZDateTime.from(prayerTimes.dhuhr!, location),
      "Asr": tz.TZDateTime.from(prayerTimes.asr!, location),
      "Maghrib": tz.TZDateTime.from(prayerTimes.maghrib!, location),
      "Isha": tz.TZDateTime.from(prayerTimes.isha!, location),
    };
    return prayerDateTimes.map(
      (name, dateTime) => MapEntry(name, timeFormat.format(dateTime)),
    );
  }
}

// Helper class to format time
class TimeFormatting {
  String format(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
