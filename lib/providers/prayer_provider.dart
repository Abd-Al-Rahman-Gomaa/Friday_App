import 'package:flutter/material.dart';

class PrayerProvider with ChangeNotifier {
  String _lastPrayerName = '';

  String get lastPrayerName => _lastPrayerName;

  void setLastPrayer(String name) {
    _lastPrayerName = name;
    notifyListeners();
  }
}
