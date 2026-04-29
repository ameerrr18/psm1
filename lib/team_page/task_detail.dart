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
  final Color bgBlue = const Color(0xFFF4F7FA);

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
        bool isCompleted = task['status'] == 'completed';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.black87),
                onPressed: () => _showEditTaskSheet(context, task),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _priorityBadge(priority),
                const SizedBox(height: 12),
                Text(
                  task['taskName'] ?? "Unnamed Task",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                  ),
                ),
                const SizedBox(height: 30),

                // Details Grid
                Row(
                  children: [
                    _detailItem(Icons.person_outline, "ASSIGNED TO", task['assigneeName'] ?? "Unassigned"),
                    _detailItem(Icons.work_outline, "WORKSPACE", "Mobile App"),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    _detailItem(Icons.calendar_today_outlined, "DUE DATE", task['endDate'] ?? "No Date"),
                    _detailItem(Icons.timer_outlined, "EFFORT", "${task['effort'] ?? '0'} Hrs"),
                  ],
                ),

                const SizedBox(height: 40),
                const Text(
                  "DESCRIPTION",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                Text(
                  task['description'] ?? "No description provided for this task.",
                  style: TextStyle(fontSize: 15, color: Colors.blueGrey[700], height: 1.5),
                ),

                const SizedBox(height: 40),
                // Task Completion Toggle
                _buildStatusSection(isCompleted),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomAction(context, isCompleted),
        );
      },
    );
  }

  Widget _priorityBadge(String p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        p.toUpperCase(),
        style: const TextStyle(color: Color(0xFF00ACC1), fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgBlue, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: primaryNavy),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusSection(bool isCompleted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.pending_actions,
            color: isCompleted ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("PROGRESS STATUS", style: TextStyle(fontSize: 10, color: Colors.grey)),
              Text(
                isCompleted ? "Task Completed" : "In Progress",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
      decoration: const BoxDecoration(color: Colors.white),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted ? Colors.grey : primaryNavy,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () => _toggleTaskStatus(!isCompleted),
        child: Text(
          isCompleted ? "REOPEN TASK" : "MARK AS COMPLETE",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- LOGIC ---

  Future<void> _toggleTaskStatus(bool complete) async {
    await FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .collection('tasks')
        .doc(taskId)
        .update({
      'status': complete ? 'completed' : 'in-progress',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _showEditTaskSheet(BuildContext context, Map<String, dynamic> task) {
    // You can implement an edit bottom sheet here later
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Edit feature coming soon!")),
    );
  }
}