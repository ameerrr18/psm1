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

class _CustomBottomNavState extends State<CustomBottomNav> with SingleTickerProviderStateMixin {
  bool isHubOpen = false;
  final Color primaryNavy = const Color(0xFF1A4789);

  // FIXED: Initialized directly or handled via nullable to prevent LateInitializationError
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggleHub() {
    setState(() {
      isHubOpen = !isHubOpen;
      if (isHubOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _openPage(int index) {
    toggleHub();
    widget.onTap(index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.bottomCenter,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Background Dimmer when Hub is open
          if (isHubOpen)
            GestureDetector(
              onTap: toggleHub,
              child: Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                color: Colors.transparent,
              ),
            ),

          // --- HUB CLOUD MENU ---
          Positioned(
            bottom: 115,
            child: ScaleTransition(
              scale: _expandAnimation,
              child: FadeTransition(
                opacity: _animationController,
                child: _buildHubCloud(),
              ),
            ),
          ),

          // --- MAIN NAV BAR ---
          Container(
            height: 80,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _hubOption(Icons.check_circle_outline, "MY TASKS", 1),
          _hubOption(Icons.group_outlined, "TEAM", 2),
          _hubOption(Icons.description_outlined, "LIBRARY", 3),
          _hubOption(Icons.calendar_month_outlined, "CALENDAR", 4),
        ],
      ),
    );
  }

  Widget _hubOption(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => _openPage(index),
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: primaryNavy, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
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
            offset: const Offset(0, -20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryNavy,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: primaryNavy.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))],
              ),
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 300),
                turns: isHubOpen ? 0.125 : 0, // Tilts icon slightly when open
                child: const Icon(Icons.grid_on_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
          const Text("HUB", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = widget.currentIndex == index;
    return InkWell(
      onTap: () => widget.onTap(index),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? primaryNavy : Colors.grey, size: 26),
            Text(
              label,
              style: TextStyle(color: isSelected ? primaryNavy : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}