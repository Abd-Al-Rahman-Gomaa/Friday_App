import 'package:flutter/material.dart';

class PrayerTimes extends StatelessWidget {
  final String clock;
  final String prayerTime;
  final IconData icon;
  const PrayerTimes({
    super.key,
    required this.clock,
    required this.icon,
    required this.prayerTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 34),
            SizedBox(width: 5),
            Text(
              prayerTime,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 22,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        Text(
          clock,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 22),
        ),
      ],
    );
  }
}
