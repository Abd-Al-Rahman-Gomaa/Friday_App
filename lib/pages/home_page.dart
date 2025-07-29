import 'package:flutter/material.dart';
import 'package:friday_app/pages/prayer_times_page.dart';
import 'package:friday_app/pages/todo_habit_tracker_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

//ToDo: Add animations between tab changes using PageView or AnimatedSwitcher for smoother UX
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentPage = 0;
  // used late final : To not recreating on every build
  late final List<Widget> pages = const [
    PrayerTimesPage(),
    TodoHabitTrackerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Indexed Stack is used to preserve state of all screens
      body: SafeArea(
        child: IndexedStack(index: currentPage, children: pages),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
          child: GNav(
            iconSize: 30,
            textStyle: const TextStyle(fontSize: 18),
            backgroundColor: Colors.black,
            color: Colors.white,
            activeColor: Colors.white70,
            tabBackgroundColor: Color(0x885E548E),
            padding: EdgeInsetsGeometry.all(8),
            gap: 8,
            onTabChange: (index) {
              setState(() {
                currentPage = index;
              });
            },
            tabs: const [
              GButton(icon: Icons.home_sharp, text: 'Home'),
              GButton(icon: Icons.checklist_rtl_sharp, text: 'Tracker'),
            ],
          ),
        ),
      ),
    );
  }
}
// ! Old Bottom Navigation Bar Style
// BottomNavigationBar(
//         unselectedItemColor: const Color.fromARGB(255, 138, 127, 156),
//         selectedItemColor: const Color.fromARGB(255, 108, 98, 157),
//         iconSize: 35,
//         selectedFontSize: 0,
//         unselectedFontSize: 0,
//         currentIndex: currentPage,
//         onTap: (value) {
//           setState(() {
//             currentPage = value;
//           });
//         },
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.library_add_check_rounded),
//             label: '',
//           ),
//         ],
//       ),