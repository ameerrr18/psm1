import 'package:flutter/material.dart';
import 'home_page/home_page.dart'; // Ensure path is correct
import 'widgets/bottom_nav.dart';

// Dummy Hub Page
class HubPage extends StatelessWidget {
  const HubPage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Hub / More Page")));
}

// Dummy Profile Page
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Profile Page")));
}

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  // List of pages to display
  final List<Widget> _pages = [
    const HomePage(),
    const HubPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use IndexedStack to keep scroll positions alive when switching tabs
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _pages,
          ),

          // Persistent Floating Nav Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomBottomNav(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}