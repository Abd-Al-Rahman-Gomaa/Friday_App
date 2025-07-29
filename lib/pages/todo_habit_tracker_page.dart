import 'package:flutter/material.dart';
import 'package:friday_app/database/habit_database.dart';
import 'package:friday_app/models/habit.dart';
import 'package:friday_app/providers/prayer_provider.dart';
import 'package:friday_app/services/prayer_service.dart';
import 'package:friday_app/utils/background_image.dart';
import 'package:friday_app/utils/my_heat_map.dart';
import 'package:friday_app/utils/prayer_todo_list.dart';
import 'package:provider/provider.dart';

class TodoHabitTrackerPage extends StatefulWidget {
  const TodoHabitTrackerPage({super.key});

  @override
  State<TodoHabitTrackerPage> createState() => _TodoHabitTrackerPageState();
}

class _TodoHabitTrackerPageState extends State<TodoHabitTrackerPage> {
  @override
  void initState() {
    PrayerService().getPrayerTimes();
    Provider.of<HabitDatabase>(context, listen: false).readHabits();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Map<DateTime, int> prepHeatMapDataset(List<Habit> habits) {
      Map<DateTime, int> dataset = {};

      for (var habit in habits) {
        for (var date in habit.completedDays) {
          final normalizeDate = DateTime(date.year, date.month, date.day);

          if (dataset.containsKey(normalizeDate)) {
            dataset[normalizeDate] = dataset[normalizeDate]! + 1;
          } else {
            dataset[normalizeDate] = 1;
          }
        }
      }
      return dataset;
    }

    final lastPrayer = Provider.of<PrayerProvider>(
      context,
      listen: true,
    ).lastPrayerName;
    final habitDatabase = Provider.of<HabitDatabase>(context);
    final String bgImage = getBackgroundImage(lastPrayer);
    final double deviceH = MediaQuery.of(context).size.height;
    final double deviceW = MediaQuery.of(context).size.width;
    final habits = habitDatabase.currentHabits;
    // final habitDB = Provider.of<HabitDatabase>(context);
    return Scaffold(
      body: SafeArea(
        child: Container(
          key: ValueKey<String>(bgImage),
          height: deviceH,
          width: deviceW,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            image: DecorationImage(
              image: AssetImage(bgImage),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Prayer Tracker",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: deviceW * 0.12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: habits.length,
                  itemBuilder: (context, index) {
                    return PrayerTodoList(habit: habits[index], index: index);
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 8,
                  ),
                  child: FutureBuilder<DateTime?>(
                    future: habitDatabase.getFirstLaunchDate(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (snapshot.hasData) {
                        final dataset = prepHeatMapDataset(habits);
                        final startDate = snapshot.data!;
                        return MyHeatMap(
                          startDate: startDate,
                          datasets: dataset,
                        );
                      } else {
                        return Container();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// AnimatedSwitcher(
//           duration: const Duration(milliseconds: 500),
//           switchInCurve: Curves.easeInOut,
//           switchOutCurve: Curves.easeInOut,
//           child: Container(
//             key: ValueKey<String>(bgImage),
//             height: deviceH,
//             width: deviceW,
//             decoration: BoxDecoration(
//               color: const Color.fromARGB(255, 255, 255, 255),
//               image: DecorationImage(
//                 image: AssetImage(bgImage),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//         ),
