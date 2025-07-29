import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';

@pragma('vm:entry-point') // Needed if used in release mode
void callbackDispatcher() {
  //Workmanager().executeTask => This callback is triggered when your background task (like "dailyPrayerTask") is fired.
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Background task running: $task at ${DateTime.now()}");
    await NotificationService.initialize(); // re-initialize inside background
    await NotificationService.notificationPopUp(); // your notification
    return Future.value(true);
  });
}
