import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';

class MyHeatMap extends StatelessWidget {
  final Map<DateTime, int> datasets;
  final DateTime startDate;
  const MyHeatMap({super.key, required this.startDate, required this.datasets});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: HeatMap(
        startDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
        endDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
        datasets: datasets,
        colorMode: ColorMode.color,
        defaultColor: const Color.fromARGB(134, 102, 96, 129),
        textColor: Colors.white,
        showColorTip: false,
        showText: true,
        scrollable: true,
        size: 30,
        fontSize: 15,
        colorsets: {
          1: const Color.fromARGB(255, 175, 171, 182),
          2: Colors.deepPurple.shade100,
          3: Colors.deepPurple.shade300,
          4: Colors.deepPurple.shade600,
          5: Colors.deepPurple.shade900,
        },
      ),
    );
  }
}
