import 'package:flutter/material.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav> {
  bool isHubOpen = false;
  final Color primaryNavy = const Color(0xFF1A4789);

  void toggleHub() {
    setState(() {
      isHubOpen = !isHubOpen;
    });
  }

  void _openPage(int index) {
    setState(() {
      isHubOpen = false;
    });

    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [

          /// 🔥 FIXED TAP BLOCKER
          if (isHubOpen)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200, // only cover hub area, not whole screen
              child: GestureDetector(
                onTap: toggleHub,
                child: Container(color: Colors.transparent),
              ),
            ),

          /// HUB CLOUD MENU
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            bottom: isHubOpen ? 115 : 90,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isHubOpen ? 1 : 0,
              child: IgnorePointer(
                ignoring: !isHubOpen,
                child: _buildHubCloud(),
              ),
            ),
          ),

          /// MAIN NAV BAR
          Container(
            height: 85,
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.grid_view_rounded, "HOME", 0),
                _buildCenterHubButton(),
                _navItem(Icons.person_outline, "PROFILE", 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubCloud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _hubOption(Icons.check_circle_outline, "MY TASKS", () => _openPage(1)),
          _hubOption(Icons.group_outlined, "TEAM", () => _openPage(2)),
          _hubOption(Icons.description_outlined, "LIBRARY", () => _openPage(3)),
          _hubOption(Icons.calendar_month_outlined, "CALENDAR", () => _openPage(4)),
        ],
      ),
    );
  }

  Widget _hubOption(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryNavy,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: TextStyle(
              color: primaryNavy,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenterHubButton() {
    return GestureDetector(
      onTap: toggleHub,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -25),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: primaryNavy,
                shape: BoxShape.circle,
              ),
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: isHubOpen ? 0.125 : 0,
                child: const Icon(Icons.grid_on_rounded, color: Colors.white),
              ),
            ),
          ),
          const Text(
            "HUB",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = widget.currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (isHubOpen) {
          setState(() {
            isHubOpen = false;
          });
        }

        widget.onTap(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? primaryNavy : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryNavy : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}