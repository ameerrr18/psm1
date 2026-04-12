import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetailTaskPage extends StatelessWidget {
  final Map<String, dynamic> task;

  const DetailTaskPage({super.key, required this.task});

  // Helper to get priority color (matching your TaskPage logic)
  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL': return const Color(0xFFFF5252);
      case 'HIGH': return const Color(0xFF1A4789);
      case 'MEDIUM': return const Color(0xFF4FC3F7);
      case 'LOW': return Colors.green;
      default: return Colors.grey;
    }
  }

  Future<void> _deleteTask(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(task['taskId'])
          .delete();
      if (context.mounted) {
        Navigator.pop(context); // Go back to list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${task['taskName']} deleted")),
        );
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDone = task['status'] == "DONE";
    DateTime date = DateTime.parse(task['taskDate']);
    String formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(date);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4789), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Task Details",
            style: TextStyle(color: Color(0xFF1A4789), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDone ? Colors.green.withOpacity(0.1) : const Color(0xFF1A4789).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                task['status'] ?? "PENDING",
                style: TextStyle(
                  color: isDone ? Colors.green : const Color(0xFF1A4789),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Task Name
            Text(
              task['taskName'] ?? "Unnamed Task",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A4789),
              ),
            ),
            const SizedBox(height: 24),

            // Information Grid
            Row(
              children: [
                _buildInfoChip(Icons.calendar_today, "Due Date", formattedDate),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.timer_outlined, "Effort", "${task['effort']} Hours"),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoChip(
              Icons.flag_outlined,
              "Priority",
              task['priority'] ?? "MEDIUM",
              color: _getPriorityColor(task['priority'] ?? "MEDIUM"),
            ),

            const SizedBox(height: 32),

            // Description Section
            const Text(
              "Description",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A4789),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                (task['description'] == null || task['description'].isEmpty)
                    ? "No description provided for this task."
                    : task['description'],
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.blueGrey[700],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Bottom Action (Optional: Analyze Risk button style matching TaskPage)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                    color: const Color(0xFF1A4789),
                    borderRadius: BorderRadius.circular(30)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 20, color: Colors.white),
                    SizedBox(width: 10),
                    Text("Run AI Risk Analysis",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value, {Color? color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color ?? Colors.grey[400]),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color ?? const Color(0xFF1A4789)
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Task"),
        content: const Text("Are you sure you want to permanently delete this task?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTask(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}