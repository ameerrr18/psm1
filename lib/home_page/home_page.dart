import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Colors based on your design requirements
  final Color primaryNavy = const Color(0xFF1A4789);
  final Color secondaryTeal = const Color(0xFF8DE1E1);
  final Color lightBg = const Color(0xFFF8FAFC);

  // Controller for the smooth sliding cards
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    // viewportFraction 0.85 allows the next and previous cards to peek in
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose(); // Important: Free up memory
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          // 120 padding to ensure content clears your floating bottom nav bar
          padding: const EdgeInsets.only(bottom: 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user?.displayName ?? "Alex"),
              const SizedBox(height: 10),
              _buildSlidingCards(),
              const SizedBox(height: 25),
              _buildOptimizeButton(),
              const SizedBox(height: 30),
              _buildPriorityFocusSection(),
              const SizedBox(height: 30),
              _buildStudyVaultSection(),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Header Section ---
  Widget _buildHeader(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "WELCOME BACK",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1),
              ),
              Text(
                "Good Morning, $name",
                style: TextStyle(
                    color: primaryNavy,
                    fontSize: 24,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ],
            ),
            child: Icon(Icons.bolt, color: primaryNavy, size: 24),
          )
        ],
      ),
    );
  }

  // --- 2. Smooth Sliding Cards with Scaling ---
  Widget _buildSlidingCards() {
    return SizedBox(
      height: 230, // Tall enough for the scaled-up center card
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          // Math to calculate scaling based on scroll position
          // Center card is scale 1.0, side cards are scale 0.9
          double scale = (1 - ((_currentPage - index).abs() * 0.12)).clamp(0.88, 1.0);

          return Center(
            child: Transform.scale(
              scale: scale,
              child: _buildCardContent(index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent(int index) {
    final List<Map<String, dynamic>> cardData = [
      {
        "color": primaryNavy,
        "title": "ACADEMIC PROGRESS",
        "val": "20%",
        "sub": "1 OF 5 TASKS",
        "progress": true,
        "isWhite": false
      },
      {
        "color": secondaryTeal,
        "title": "UPCOMING",
        "val": "4 Deadlines",
        "sub": "Approaching soon in 2026",
        "progress": false,
        "isWhite": false
      },
      {
        "color": Colors.white,
        "title": "ASSIGNED TO ME",
        "val": "4 Items",
        "sub": "In your private backlog",
        "progress": false,
        "isWhite": true
      },
    ];

    final data = cardData[index];
    bool isWhite = data['isWhite'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 15),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: data['color'],
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isWhite ? 0.05 : 0.15),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data['title'],
              style: TextStyle(
                  color: isWhite ? Colors.grey : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(data['val'],
              style: TextStyle(
                  color: isWhite ? primaryNavy : Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900)),
          Text(data['sub'],
              style: TextStyle(
                  color: isWhite ? Colors.grey : Colors.white70,
                  fontSize: 13)),
          if (data['progress']) ...[
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                  value: 0.2,
                  backgroundColor: Colors.white24,
                  color: secondaryTeal,
                  minHeight: 6),
            ),
          ]
        ],
      ),
    );
  }

  // --- 3. Optimize Intelligence Button ---
  Widget _buildOptimizeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: secondaryTeal.withOpacity(0.4),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: secondaryTeal, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology_outlined, color: primaryNavy),
            const SizedBox(width: 12),
            Text("Optimize Intelligence",
                style: TextStyle(
                    color: primaryNavy,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // --- 4. Priority Focus ---
  Widget _buildPriorityFocusSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Priority Focus",
              style: TextStyle(
                  color: primaryNavy, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _priorityItem("DB Optimization: B-Tree...", "MAR 23, 2026", "CRITICAL"),
          _priorityItem("FYP Prototype Alpha V1", "APR 10, 2026", "CRITICAL"),
        ],
      ),
    );
  }

  Widget _priorityItem(String title, String date, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
          ]),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: primaryNavy,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 5),
                Text(date,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(status,
                style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // --- 5. Study Vault Section ---
  Widget _buildStudyVaultSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Study Vault",
              style: TextStyle(
                  color: primaryNavy, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            children: [
              _vaultItem("Mobile_Dev", "PDF"),
              const SizedBox(width: 15),
              _vaultItem("PostgreSQL_P", "PDF"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vaultItem(String name, String type) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.description_outlined, color: primaryNavy, size: 30),
            const SizedBox(height: 15),
            Text(name,
                style: TextStyle(
                    color: primaryNavy,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            Text(type, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}