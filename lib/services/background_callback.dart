import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:friday_app/services/notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("🛠 Running background task: $task");

    try {
      await NotificationService.initializeBackground();
      await NotificationService.notificationPopUp();
      debugPrint("✅ Task $task completed.");
      return true;
    } catch (e, stack) {
      debugPrint("❌ Task $task failed: $e");
      debugPrint("📚 Stack Trace: $stack");
      return false;
    }
  });
}
