import 'package:flutter/material.dart';
import '../task_page/task_page.dart';
import 'home_page/home_page.dart';
import 'widgets/bottom_nav.dart';
import 'profile_page/profile_page.dart';
import 'team_page/team_page.dart';
import 'library_page/library_page.dart';
import 'calendar_page/calendar_page.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;
  final List<int> _history = [0];

  final List<Widget> _pages = [
    const HomePage(),
    const TaskPage(),
    const TeamPage(),
    const LibraryPage(),
    const CalendarPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    // 🛑 PROTECTION (VERY IMPORTANT)
    if (index < 0 || index >= _pages.length) return;

    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;

      // ✅ safer history handling
      _history.remove(index);
      _history.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _history.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_history.length > 1) {
          setState(() {
            _history.removeLast();

            // 🛑 SAFE INDEX FIX
            int lastIndex = _history.last;
            _selectedIndex =
            (lastIndex >= 0 && lastIndex < _pages.length) ? lastIndex : 0;
          });
        }
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          // 🛑 CRITICAL FIX (prevents crash)
          index: (_selectedIndex >= 0 && _selectedIndex < _pages.length)
              ? _selectedIndex
              : 0,
          children: _pages,
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}