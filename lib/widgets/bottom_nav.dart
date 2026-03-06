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

class _CustomBottomNavState extends State<CustomBottomNav>
    with SingleTickerProviderStateMixin {
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

          /// TAP BLOCKER (prevents nav bar from stealing taps)
          if (isHubOpen)
            Positioned.fill(
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
                _navItem(Icons.person_outline, "PROFILE", 2),
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

          /// MY TASK
          _hubOption(Icons.check_circle_outline, "MY TASKS", () {
            _openPage(1);
          }),

          /// TEAM
          _hubOption(Icons.group_outlined, "TEAM", () {
            toggleHub();
          }),

          /// LIBRARY
          _hubOption(Icons.description_outlined, "LIBRARY", () {
            toggleHub();
          }),
        ],
      ),
    );
  }

  Widget _hubOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
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
                turns: isHubOpen ? 0.125 : 0,
                child: const Icon(
                  Icons.grid_on_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
          const Text(
            "HUB",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
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
            color: isSelected ? primaryNavy : Colors.grey.withOpacity(0.5),
          ),
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