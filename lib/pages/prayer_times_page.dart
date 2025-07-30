import 'dart:math';
import 'package:flutter/material.dart';
import 'package:friday_app/pages/Image_viewer_page.dart';
import 'package:friday_app/providers/prayer_provider.dart';
import 'package:friday_app/services/notification_service.dart';
import 'package:friday_app/services/prayer_service.dart';
import 'package:friday_app/utils/prayer_times.dart';
import 'package:intl/intl.dart'; // Provides DateFormat (e.g.: 4:20 Am).
import 'dart:async';
import 'package:provider/provider.dart'; // Needed for Timer class to periodically update the current time.

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<PrayerTimesPage> {
  List<String> quotes = [
    '" If you tell the truth, you don\'t have to remember anything "',
    '" It is better to be hated for what you are than to be loved for what you are not "',
    '" Life isn\'t about finding yourself. Life is about creating yourself "',
    '" The truth of the matter is that you always know the right thing to do. The hard part is doing it "',
    '" Love all, trust a few, do wrong to none "',
    '" Fears are nothing more than a state of mind "',
    '" Be who you are and say what you feel because those who mind don\'t matter and those who matter don\'t mind "',
  ];
  double _opacity = 0;
  Offset _offset = const Offset(0, 0.2);
  DateTime now = DateTime.now();
  Timer? timer;
  Map<String, String>? prayerTimes;
  bool loading = true;
  String? error;
  String? dailyQuote;
  DateTime? quoteDate;
  final random = Random();

  @override
  void initState() {
    super.initState();
    NotificationService.notificationPopUp();
    if (quoteDate == null ||
        quoteDate != DateTime(now.year, now.month, now.day)) {
      final newQuote = quotes[random.nextInt(quotes.length)];
      quoteDate = DateTime(now.year, now.month, now.day);
      dailyQuote = newQuote;
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _opacity = 1;
        _offset = Offset.zero;
      });
    });
    timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        now = DateTime.now();
      });
    });
    // *mounted : This avoids errors if the widget is disposed before the location finishes.
    PrayerService()
        .getPrayerTimes()
        .then((times) {
          if (!mounted) return;
          setState(() {
            prayerTimes = times;
            loading = false;
          });
        })
        .catchError((e) {
          setState(() {
            error = e.toString();
            loading = false;
          });
        });
  }

  @override
  void dispose() {
    timer?.cancel(); // Avoid memory leaks when widget destroyed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    now = DateTime.now(); // ensure it's up to date per rebuild
    String timeUntilNextPrayer = '';
    String nowPrayerImage = 'assets/images/default.png';
    List<String> images = [
      'assets/images/1.png', // Fajr/Isha
      'assets/images/2.png', // Sunrise
      'assets/images/3.png', // Dhuhr/Asr
      'assets/images/4.png', // Maghrib
    ];
    if (prayerTimes != null) {
      DateTime? nextPrayerTime;
      String? nextPrayerName;
      DateTime? lastPrayerTime;
      String? lastPrayerName;

      prayerTimes!.forEach((name, timeStr) {
        try {
          final parsed = DateFormat.jm().parse(timeStr);
          final todayTime = DateTime(
            now.year,
            now.month,
            now.day,
            parsed.hour,
            parsed.minute,
          );

          if (todayTime.isBefore(now)) {
            if (lastPrayerTime == null || todayTime.isAfter(lastPrayerTime!)) {
              lastPrayerTime = todayTime;
              lastPrayerName = name;
            }
          } else {
            if (nextPrayerTime == null || todayTime.isBefore(nextPrayerTime!)) {
              nextPrayerTime = todayTime;
              nextPrayerName = name;
            }
          }
        } catch (e) {
          debugPrint('Error parsing $name: $e');
        }
      });

      if (lastPrayerName != null) {
        switch (lastPrayerName) {
          case 'Sunrise':
            nowPrayerImage = images[0];
            break;
          case 'Dhuhr':
          case 'Asr':
            nowPrayerImage = images[1];
            break;
          case 'Maghrib':
            nowPrayerImage = images[2];
            break;
          case 'Fajr':
          case 'Isha':
            nowPrayerImage = images[3];
            break;
        }
      } else {
        nowPrayerImage = images[3];
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<PrayerProvider>(
          context,
          listen: false,
        ).setLastPrayer(lastPrayerName ?? 'Fajr');
      });

      if (nextPrayerTime != null && nextPrayerName != null) {
        final diff = nextPrayerTime!.difference(now);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        if (hours == 0) {
          timeUntilNextPrayer = '$nextPrayerName in $minutes min';
        } else if (hours == 1) {
          timeUntilNextPrayer =
              '$nextPrayerName in $hours hour and $minutes min';
        } else {
          timeUntilNextPrayer =
              '$nextPrayerName in $hours hours and $minutes min';
        }
      } else {
        timeUntilNextPrayer = dailyQuote ?? '';
      }
    }

    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(backgroundColor: Colors.black),
        ),
      );
    }

    if (error != null) {
      return Scaffold(body: Center(child: Text("Error: $error")));
    }

    final String formattedTime = DateFormat.jm().format(now);
    final String formattedDate = DateFormat.yMMMMEEEEd().format(now);
    final double deviceH = MediaQuery.of(context).size.height;
    final double deviceW = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Container(
          height: deviceH,
          width: deviceW,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(nowPrayerImage),
              colorFilter: ColorFilter.mode(
                // ignore: deprecated_member_use
                Colors.black.withOpacity(0.3), // Try 0.1 to 0.3
                BlendMode.darken,
              ),
              fit: BoxFit.cover,
            ),
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // const SizedBox(height: 0),
                Text(
                  'Prayer Times',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 10),
                Text(
                  formattedTime,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  offset: _offset,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 600),
                    opacity: _opacity,
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(20),
                      width: deviceW * 0.97,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(134, 102, 96, 129),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          PrayerTimes(
                            prayerTime: 'Fajr',
                            clock: prayerTimes?['Fajr'] ?? '--:--',
                            icon: Icons.nightlight_round,
                          ),
                          const SizedBox(height: 40),
                          PrayerTimes(
                            prayerTime: 'Sunrise',
                            clock: prayerTimes?['Sunrise'] ?? '--:--',
                            icon: Icons.wb_twilight,
                          ),
                          const SizedBox(height: 40),
                          PrayerTimes(
                            prayerTime: 'Dhuhr',
                            clock: prayerTimes?['Dhuhr'] ?? '--:--',
                            icon: Icons.wb_sunny,
                          ),
                          const SizedBox(height: 40),
                          PrayerTimes(
                            prayerTime: 'Asr',
                            clock: prayerTimes?['Asr'] ?? '--:--',
                            icon: Icons.wb_sunny_outlined,
                          ),
                          const SizedBox(height: 40),
                          PrayerTimes(
                            prayerTime: 'Maghrib',
                            clock: prayerTimes?['Maghrib'] ?? '--:--',
                            icon: Icons.sunny_snowing,
                          ),
                          const SizedBox(height: 40),
                          PrayerTimes(
                            prayerTime: 'Isha',
                            clock: prayerTimes?['Isha'] ?? '--:--',
                            icon: Icons.nightlight,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    timeUntilNextPrayer,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: const Color(0x885E548E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ImageViewerPage(
                              title: 'Morning Azkar',
                              imagePath: 'assets/images/morning-azkar.jpg',
                            ),
                          ),
                        );
                      },
                      child: const Text('Morning Azkar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: const Color(0x885E548E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ImageViewerPage(
                              title: 'Evening Azkar',
                              imagePath: 'assets/images/evening-azkar.jpg',
                            ),
                          ),
                        );
                      },
                      child: const Text('Evening Azkar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        backgroundColor: const Color(0x885E548E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ImageViewerPage(
                              title: 'Surah Mulk',
                              imagePath: 'assets/images/surah-mulk.jpg',
                            ),
                          ),
                        );
                      },
                      child: const Text('Surah Mulk'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
