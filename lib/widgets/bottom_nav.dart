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
  bool isHubOpen = false; // Tracks if the "cloud" menu is visible
  final Color primaryNavy = const Color(0xFF1A4789);

  void toggleHub() {
    setState(() {
      isHubOpen = !isHubOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // --- 1. The Cloud Menu Overlay ---
        if (isHubOpen) _buildHubCloud(),

        // --- 2. The Main Bottom Nav Bar ---
        Container(
          height: 85,
          margin: const EdgeInsets.all(20),
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
              _navItem(Icons.person_outline, "PROFILE", 2),
            ],
          ),
        ),
      ],
    );
  }

  // The "Cloud" that pops up with 3 options
  Widget _buildHubCloud() {
    return Positioned(
      bottom: 110, // Sits above the nav bar
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        width: MediaQuery.of(context).size.width * 0.85,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
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
            _hubOption(Icons.check_circle_outline, "MY TASKS", () {
              toggleHub();
              // Add navigation to Task Page here
            }),
            _hubOption(Icons.group_outlined, "TEAM", () {
              toggleHub();
              // Add navigation to Team Page here
            }),
            _hubOption(Icons.description_outlined, "LIBRARY", () {
              toggleHub();
              // Add navigation to Library Page here
            }),
          ],
        ),
      ),
    );
  }

  Widget _hubOption(IconData icon, String label, VoidCallback action) {
    return GestureDetector(
      onTap: action,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryNavy,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: primaryNavy,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterHubButton() {
    return GestureDetector(
      onTap: toggleHub, // Toggle the cloud instead of direct navigation
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: primaryNavy,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryNavy.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: isHubOpen ? 0.125 : 0, // Tilts the icon slightly when open
                child: const Icon(Icons.grid_on_rounded, color: Colors.white, size: 30),
              ),
            ),
          ),
          const Text("HUB",
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = widget.currentIndex == index;
    return GestureDetector(
      onTap: () {
        if (isHubOpen) setState(() => isHubOpen = false);
        widget.onTap(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isSelected ? primaryNavy : Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryNavy : Colors.grey.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}