String getBackgroundImage(String? lastPrayerName) {
  List<String> images = [
    'assets/images/1.png', // Fajr/Isha
    'assets/images/2.png', // Sunrise
    'assets/images/3.png', // Dhuhr/Asr
    'assets/images/4.png', // Maghrib
  ];

  switch (lastPrayerName) {
    case 'Sunrise':
      return images[0];
    case 'Dhuhr':
    case 'Asr':
      return images[1];
    case 'Maghrib':
      return images[2];
    case 'Fajr':
    case 'Isha':
      return images[3];
    default:
      return 'assets/images/3.png';
  }
}
