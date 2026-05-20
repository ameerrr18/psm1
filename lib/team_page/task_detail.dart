import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskDetailPage extends StatelessWidget {
  final String taskId;
  final String workspaceId;

  const TaskDetailPage({
    super.key,
    required this.taskId,
    required this.workspaceId,
  });

  final Color primaryNavy = const Color(0xFF1A4789);
  final Color bgBlue = const Color(0xFFF8FAFC); // Sweeter, cleaner modern background hue

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('tasks')
          .doc(taskId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        var task = snapshot.data!.data() as Map<String, dynamic>;
        String priority = task['priority'] ?? 'MEDIUM';

        // Match the structural 'DONE' state from your workspace checklist logic
        bool isCompleted = task['status'] == 'DONE' || task['status'] == 'completed';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority Tracker Row
                _buildPriorityBadge(priority),
                const SizedBox(height: 16),

                // Task Title Text block
                Text(
                  task['taskName'] ?? "Unnamed Task",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Premium Metadata Grid Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: bgBlue,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildDetailItem(Icons.person_search_rounded, "ASSIGNED TO", task['assignedName'] ?? "Unassigned"),
                          _buildDetailItem(Icons.grid_view_rounded, "TASK ID", task['taskId'] ?? taskId),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Colors.grey.shade200, height: 1),
                      ),
                      Row(
                        children: [
                          _buildDetailItem(Icons.calendar_month_rounded, "DUE DATE",
                              task['endDate'] != null && task['endDate'].toString().contains('T')
                                  ? task['endDate'].toString().split('T')[0]
                                  : task['endDate'] ?? 'No Date'
                          ),
                          _buildDetailItem(Icons.hourglass_top_rounded, "EFFORT VALUE", "${task['effort'] ?? '0'} Hrs"),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Text(
                  "DESCRIPTION",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    task['description'] ?? "No description provided for this task.",
                    style: TextStyle(fontSize: 15, color: Colors.blueGrey[800], height: 1.6, fontWeight: FontWeight.w400),
                  ),
                ),

                const SizedBox(height: 32),
                // Task Live Completion Progress Overview Card
                _buildStatusSection(isCompleted),
                const SizedBox(height: 40),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomAction(context, isCompleted),
        );
      },
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color labelColor;
    Color containerColor;

    switch (priority.toUpperCase()) {
      case 'CRITICAL':
      case 'HIGH':
        labelColor = const Color(0xFFDC2626);
        containerColor = const Color(0xFFFEE2E2);
        break;
      case 'MEDIUM':
        labelColor = const Color(0xFFD97706);
        containerColor = const Color(0xFFFEF3C7);
        break;
      default:
        labelColor = const Color(0xFF4B5563);
        containerColor = const Color(0xFFF3F4F6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: labelColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: primaryNavy.withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusSection(bool isCompleted) {
    final Color stateAccentColor = isCompleted ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stateAccentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: stateAccentColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: stateAccentColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "PROGRESS STATUS",
                  style: TextStyle(fontSize: 10, color: stateAccentColor.withOpacity(0.8), fontWeight: FontWeight.bold, letterSpacing: 0.5)
              ),
              const SizedBox(height: 2),
              Text(
                isCompleted ? "Task Completed Successfully" : "In Progress Tracking",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryNavy),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, -4),
            )
          ]
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted ? Colors.grey.shade200 : primaryNavy,
          foregroundColor: isCompleted ? Colors.black87 : Colors.white,
          minimumSize: const Size(double.infinity, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => _toggleTaskStatus(!isCompleted),
        child: Text(
          isCompleted ? "REOPEN TASK SUITE" : "MARK AS DONE",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
        ),
      ),
    );
  }

  // --- DATABASE TRANSACTION LOGIC ---

  Future<void> _toggleTaskStatus(bool complete) async {
    // Toggles using the exact parameters used in the home feed tracker
    await FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .collection('tasks')
        .doc(taskId)
        .update({
      'status': complete ? 'DONE' : 'PENDING',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

}