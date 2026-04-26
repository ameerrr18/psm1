import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'noti_page.dart';
import '../ai_page/ai_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Theme Colors
  final Color primaryNavy = const Color(0xFF1A4789);
  final Color secondaryTeal = const Color(0xFF8DE1E1);
  final Color lightBg = const Color(0xFFF8FAFC);
  final Color card3 = const Color(0xFF475569);

  int _weekOffset = 0;

  late PageController _pageController;
  double _currentPage = 1;
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82, initialPage: 1);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: lightBg,
      // This allows the background to extend behind the floating bar
      extendBody: true,
      body: SafeArea(
        // We use bottom: false so the content can scroll behind the nav bar area
        bottom: false,
        child: SingleChildScrollView(
          // Remove the large bottom padding here
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(user?.displayName ?? "Alex"),
              const SizedBox(height: 15),
              _buildSlidingCards(),
              const SizedBox(height: 25),
              _buildOptimizeButton(context),
              const SizedBox(height: 30),
              _buildPriorityFocusSection(),
              const SizedBox(height: 30),
              _buildStudyVaultSection(),
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Header Section ---
  Widget _buildHeader(String name) {
    // Logic to determine if there are unread notifications
    bool hasNotification = true; // Set this based on your data logic

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
                "${_getGreeting()}, $name",
                style: TextStyle(
                    color: primaryNavy,
                    fontSize: 22,
                    fontWeight: FontWeight.w900),
              ),
            ],
          ),
          // Notification Bell Container
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotiPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08), // High contrast shadow
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_outlined, color: primaryNavy, size: 26),
                  if (hasNotification)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- 2. Horizontal Calendar ---
  Widget _buildHorizontalCalendar({bool isInsideCard = false}) {
    DateTime viewedDate = DateTime.now().add(Duration(days: _weekOffset));

    return Container(
      margin: isInsideCard ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with High-Contrast Typography
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => setState(() => _weekOffset -= 7),
                child: Icon(Icons.chevron_left, size: 20, color: primaryNavy.withOpacity(0.5)),
              ),
              Text(
                DateFormat('MMMM yyyy').format(viewedDate).toUpperCase(),
                style: TextStyle(
                    fontWeight: FontWeight.w900, // Extra bold for contrast
                    fontSize: 13,
                    letterSpacing: 1.2,
                    color: primaryNavy
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _weekOffset += 7),
                child: Icon(Icons.chevron_right, size: 20, color: primaryNavy.withOpacity(0.5)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Day Labels (Higher weight for visibility)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["S", "M", "T", "W", "T", "F", "S"]
                .map((d) => Expanded(
              child: Center(
                child: Text(d, style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 10),
          _buildWeekRow(_weekOffset, isInsideCard),
          const SizedBox(height: 12),
          _buildWeekRow(_weekOffset + 7, isInsideCard),
        ],
      ),
    );
  }

  Widget _buildWeekRow(int startDay, bool isInsideCard) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        DateTime now = DateTime.now();
        DateTime sunday = now.subtract(Duration(days: now.weekday % 7));
        DateTime date = sunday.add(Duration(days: startDay + index));
        String formattedDate = DateFormat('yyyy-MM-dd').format(date);
        bool isToday = date.day == now.day && date.month == now.month && date.year == now.year;

        return Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .where('userId', isEqualTo: currentUserId)
                .where('isDeleted', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int taskCount = 0;
              if (snapshot.hasData) {
                taskCount = snapshot.data!.docs.where((doc) {
                  String taskDate = doc['endDate']?.toString().split('T')[0] ?? "";
                  return taskDate == formattedDate;
                }).length;
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26, // Smaller diameter for cards
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday ? primaryNavy : Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: isToday ? Colors.white : Colors.black87,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 10, // Smaller font to fit 2 weeks
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      taskCount > 2 ? 2 : taskCount, // Cap at 2 dots for cards
                          (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.5),
                        child: Container(
                          width: 5,
                          height: 2,
                          decoration: BoxDecoration(
                            color: i == 0 ? Colors.purple : secondaryTeal,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        );
      }),
    );
  }

  Widget _indicator(Color color) {
    return Container(
        width: 6,
        height: 2,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))
    );
  }

  // --- 3. Dynamic Sliding Cards (Linked to Firestore) ---
  Widget _buildSlidingCards() {
    return StreamBuilder<QuerySnapshot>(
      // Logic to fetch tasks based on userId and active status
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .where('isDeleted', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        // Calculate tasks data for the Progress Card
        int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
        int completed = snapshot.hasData
            ? snapshot.data!.docs.where((d) => d['status'] == "DONE").length
            : 0;
        double progressValue = (total > 0) ? (completed / total) : 0.0;

        return SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: 3,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              double relativeOffset = (_currentPage - index).abs();

              // Subtle scaling: 1.0 for active, 0.9 for background
              double scale = (1.03 - (relativeOffset * 0.1)).clamp(0.85, 1.2);

              return Transform.scale(
                scale: scale,
                child: Padding(
                  // REDUCED padding (from 10 to 4) makes the cards sit closer together
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: _buildCardByIndex(index, progressValue, completed, total, total - completed),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCardByIndex(int index, double progress, int done, int total, int pending) {
    switch (index) {
      case 0:
        return _buildInfoCard("UPCOMING", "$pending Deadlines", "Requires Immediate attention", secondaryTeal, false);
      case 1:
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08), // Slightly deeper shadow for contrast
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: _buildHorizontalCalendar(isInsideCard: true),
        );
      case 2:
        return _buildProgressCard(progress, done, total);
      default:
        return const SizedBox();
    }
  }

  Widget _buildProgressCard(double progress, int completed, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: primaryNavy,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ACADEMIC PROGRESS", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900)),
          Text("$completed OF $total TASKS COMPLETED", style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              color: secondaryTeal,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String val, String sub, Color color, bool isWhite) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(35),
        border: isWhite ? Border.all(color: Colors.grey.shade200) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: isWhite ? Colors.white : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(val, style: TextStyle(color: isWhite ? Colors.white : Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
          Text(sub, style: TextStyle(color: isWhite ? Colors.grey : Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  // --- 4. AI Button ---
  Widget _buildOptimizeButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AIPage())),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [secondaryTeal.withOpacity(0.4), secondaryTeal.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: secondaryTeal, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: primaryNavy, size: 20),
              const SizedBox(width: 12),
              Text("Optimize Intelligence", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  // --- 5. Priority Focus (CRITICAL ONLY) ---
  Widget _buildPriorityFocusSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Priority Focus", style: TextStyle(color: primaryNavy, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tasks')
                .where('userId', isEqualTo: currentUserId)
                .where('priority', isEqualTo: 'CRITICAL')
                .where('status', isEqualTo: 'PENDING')
                .limit(2)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _priorityItem("All tasks clear", "Great job!", "Done");
              }
              return Column(
                children: snapshot.data!.docs.map((doc) {
                  return _priorityItem(doc['taskName'], "DUE: ${doc['endDate'].toString().split('T')[0]}", "CRITICAL");
                }).toList(),
              );
            },
          ),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 5),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: status == "CRITICAL" ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: status == "CRITICAL" ? Colors.red : Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // --- 6. Study Vault (Live Subject Folders) ---
  Widget _buildStudyVaultSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Subject Vault", style: TextStyle(color: primaryNavy, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('folders')
                .where('userId', isEqualTo: currentUserId)
                .where('status', isEqualTo: 'active')
                .limit(2)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("No folders created yet.", style: TextStyle(color: Colors.grey, fontSize: 12));
              }
              return Row(
                children: snapshot.data!.docs.map((doc) {
                  return _vaultItem(doc['folderName'], "FOLDER");
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _vaultItem(String name, String type) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.folder_zip, color: primaryNavy, size: 28),
            const SizedBox(height: 15),
            Text(name, style: TextStyle(color: primaryNavy, fontWeight: FontWeight.w900, fontSize: 12, overflow: TextOverflow.ellipsis)),
            Text(type, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}