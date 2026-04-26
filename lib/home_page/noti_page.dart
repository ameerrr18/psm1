import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../task_page/detailtask_page.dart';

class NotiPage extends StatelessWidget {
  const NotiPage({super.key});

  final Color primaryNavy = const Color(0xFF1A4789);
  final Color lightBg = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Reminders",
          style: TextStyle(color: primaryNavy, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // We listen to active tasks that are NOT deleted and NOT done
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('userId', isEqualTo: currentUserId)
            .where('isDeleted', isEqualTo: false)
            .where('status', isNotEqualTo: 'DONE')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Filter tasks locally for 3-day or 1-day warnings
          final now = DateTime.now();
          final upcomingTasks = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['endDate'] == null) return false;

            final dueDate = DateTime.parse(data['endDate']);
            final daysRemaining = dueDate.difference(now).inDays;

            // Only include if exactly 1 or 3 days remain
            return daysRemaining == 1 || daysRemaining == 3;
          }).toList();

          if (upcomingTasks.isEmpty) return _buildEmptyState();

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              _buildSectionHeader("DUE SOON"),
              ...upcomingTasks.map((doc) => _buildReminderCard(context, doc)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String taskName = data['taskName'] ?? 'Unnamed Task';
    final String taskId = data['taskId'] ?? doc.id;
    final DateTime dueDate = DateTime.parse(data['endDate']);
    final int daysLeft = dueDate.difference(DateTime.now()).inDays;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DetailTaskPage(taskId: taskId)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: daysLeft == 1 ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: daysLeft == 1 ? Colors.red[50] : Colors.orange[50],
              child: Icon(
                Icons.alarm,
                color: daysLeft == 1 ? Colors.red : Colors.orange,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    daysLeft == 1 ? "Due Tomorrow!" : "Due in 3 Days",
                    style: TextStyle(
                      color: daysLeft == 1 ? Colors.red : Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    taskName,
                    style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 15, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text(
            "No notifications yet",
            style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    var now = DateTime.now();
    var date = timestamp.toDate();
    var diff = now.difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return DateFormat('MMM d').format(date);
  }
}