import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetailTaskPage extends StatelessWidget {
  final Map<String, dynamic> task;

  const DetailTaskPage({super.key, required this.task});

  final Color primaryNavy = const Color(0xFF1A4789);
  final Color accentBlue = const Color(0xFF4FC3F7);
  final Color bgLight = const Color(0xFFF8FAFC);

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL': return const Color(0xFFFF5252);
      case 'HIGH': return primaryNavy;
      case 'MEDIUM': return accentBlue;
      case 'LOW': return Colors.green;
      default: return Colors.grey;
    }
  }

  // Updated to match your "Move to History" logic
  Future<void> _moveToHistory(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(task['taskId'])
          .update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task moved to History")),
        );
      }
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDone = task['status'] == "DONE";
    DateTime date = DateTime.parse(task['taskDate']);
    String formattedDate = DateFormat('MMMM dd, yyyy').format(date);

    return Scaffold(
      backgroundColor: bgLight,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: primaryNavy, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                onPressed: () => _showDeleteConfirmation(context),
              ),
              const SizedBox(width: 10),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
              title: Text(
                "Task Details",
                style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(isDone),
                      Text(
                        "${task['effort']} Hours",
                        style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    task['taskName'] ?? "Unnamed Task",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryNavy,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- INFO CARDS ---
                  Row(
                    children: [
                      _buildDetailCard(
                        Icons.calendar_month_rounded,
                        "Due Date",
                        formattedDate,
                        Colors.orange,
                      ),
                      const SizedBox(width: 15),
                      _buildDetailCard(
                        Icons.flag_rounded,
                        "Priority",
                        task['priority'] ?? "Medium",
                        _getPriorityColor(task['priority'] ?? "Medium"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- DESCRIPTION SECTION ---
                  Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
                      ],
                    ),
                    child: Text(
                      (task['description'] == null || task['description'].isEmpty)
                          ? "No description provided for this task."
                          : task['description'],
                      style: TextStyle(fontSize: 16, height: 1.8, color: Colors.blueGrey[800]),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- AI ANALYSIS ACTION ---
                  _buildAIButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isDone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDone ? Colors.green[50] : primaryNavy.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: isDone ? Colors.green : primaryNavy),
          const SizedBox(width: 8),
          Text(
            isDone ? "COMPLETED" : "IN PROGRESS",
            style: TextStyle(
              color: isDone ? Colors.green[700] : primaryNavy,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildAIButton() {
    return Container(
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryNavy, const Color(0xFF2A5298)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: primaryNavy.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {}, // Add AI Logic here
          borderRadius: BorderRadius.circular(25),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  "Analyze Risk with Planova AI",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Delete Task?"),
        content: const Text("This task will be moved to your Task History."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _moveToHistory(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}