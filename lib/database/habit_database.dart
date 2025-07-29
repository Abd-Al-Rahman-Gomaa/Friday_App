import 'package:flutter/material.dart';
import 'package:friday_app/models/app_settings.dart';
import 'package:friday_app/models/habit.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class HabitDatabase extends ChangeNotifier {
  static late Isar isar;
  //* Initialize - Database
  static Future<void> initialize() async {
    final dir = await getApplicationCacheDirectory();
    isar = await Isar.open([
      HabitSchema,
      AppSettingsSchema,
    ], directory: dir.path);
  }

  //* Save first date of app startup (for heatmap)
  Future<void> saveFirstLaunchDate() async {
    final existingSettings = await isar.appSettings.where().findFirst();
    if (existingSettings == null) {
      final settings = AppSettings()..firstLaunchDate = DateTime.now();
      await isar.writeTxn(() => isar.appSettings.put(settings));
    }
  }

  //* Get first date of app startup (for heatmap)
  Future<DateTime?> getFirstLaunchDate() async {
    final settings = await isar.appSettings.where().findFirst();
    return settings?.firstLaunchDate;
  }

  //* List of habits
  final List<Habit> currentHabits = [];

  // Always insert 5 blank habits if empty
  Future<void> insertFiveHabitsIfNeeded() async {
    final existing = await isar.habits.count();
    if (existing == 0) {
      await isar.writeTxn(() async {
        for (int i = 0; i < 5; i++) {
          await isar.habits.put(Habit());
        }
      });
    }
    await readHabits();
  }

  Future<void> readHabits() async {
    //* fetch all habits from db
    final fetchedHabits = await isar.habits.where().findAll();

    //*give to current habits
    currentHabits.clear();
    currentHabits.addAll(fetchedHabits);
    //* update ui
    notifyListeners();
  }

  //* Update - chech habit on and off
  Future<void> updateHabitCompletion(int id, bool isCompleted) async {
    //* find specific habit
    final habit = await isar.habits.get(id);

    //* update completion status
    if (habit != null) {
      await isar.writeTxn(() async {
        //* if habit completed: add the current date to the completedDays list
        final today = DateTime.now();
        final todayOnly = DateTime(today.year, today.month, today.day);
        if (isCompleted && !habit.completedDays.contains(todayOnly)) {
          habit.completedDays.add(todayOnly);
        }
        //* if habit is not completed: remove the current date from the list
        else {
          habit.completedDays.removeWhere(
            (date) =>
                date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day,
          );
        }
        //* Save the updated habits to the data base
        await isar.habits.put(habit);
      });
      await readHabits();
      notifyListeners();
    }
  }
}
