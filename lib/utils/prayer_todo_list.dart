import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:friday_app/models/habit.dart';
import 'package:friday_app/database/habit_database.dart';

class PrayerTodoList extends StatelessWidget {
  final Habit habit;
  final int index;
  const PrayerTodoList({super.key, required this.habit, required this.index});

  @override
  Widget build(BuildContext context) {
    final double deviceW = MediaQuery.of(context).size.width;

    // Fixed prayer names by index
    const prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final name = prayerNames[index];

    // Today’s date (normalized)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final isCompleted = habit.completedDays.any(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    );

    return GestureDetector(
      onTap: () async {
        // Toggle the checkbox when container tapped
        await Provider.of<HabitDatabase>(
          context,
          listen: false,
        ).updateHabitCompletion(habit.id, !isCompleted);
      },
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        width: deviceW * 0.85,
        decoration: BoxDecoration(
          color: const Color.fromARGB(134, 102, 96, 129),
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(color: Colors.black12, offset: Offset(3, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: Text(name, style: Theme.of(context).textTheme.bodySmall),
            ),
            Checkbox(
              value: isCompleted,
              onChanged: (value) async {
                await Provider.of<HabitDatabase>(
                  context,
                  listen: false,
                ).updateHabitCompletion(habit.id, value ?? false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
