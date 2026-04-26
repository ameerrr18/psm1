import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'edit_task_page.dart';

class DetailTaskPage extends StatelessWidget {
  // FIXED: Changed from Map to String ID to match your NotiPage navigation
  final String taskId;
  const DetailTaskPage({super.key, required this.taskId});

  final Color primaryNavy = const Color(0xFF1A4789);
  final Color bgLight = const Color(0xFFF8FAFC);

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL': return const Color(0xFFFF5252);
      case 'HIGH': return primaryNavy;
      case 'MEDIUM': return const Color(0xFF4FC3F7);
      case 'LOW': return Colors.green;
      default: return Colors.grey;
    }
  }

  Future<void> _moveToHistory(BuildContext context, String taskId) async {
    DateTime expiration = DateTime.now().add(const Duration(days: 30));

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
        'expireAt': Timestamp.fromDate(expiration),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Moved to Task History"),
            backgroundColor: primaryNavy,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _toggleTaskStatus(String taskId, bool currentlyDone) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'status': currentlyDone ? "PENDING" : "DONE",
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      // Listen to the taskId passed from the constructor
      stream: FirebaseFirestore.instance.collection('tasks').doc(taskId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text("Task Not Found")),
            body: const Center(child: Text("This task may have been deleted.")),
          );
        }

        // FETCH DATA
        var data = snapshot.data!.data() as Map<String, dynamic>;
        // Ensure taskId is inside the map for EditTaskPage
        data['taskId'] = snapshot.data!.id;

        bool isDone = (data['status'] ?? "PENDING") == "DONE";

        String startStr = "Not Set";
        String endStr = "Not Set";
        if (data['startDate'] != null) {
          try {
            startStr = DateFormat('MMM dd, yyyy').format(DateTime.parse(data['startDate']));
          } catch (_) {}
        }
        if (data['endDate'] != null) {
          try {
            endStr = DateFormat('MMM dd, yyyy').format(DateTime.parse(data['endDate']));
          } catch (_) {}
        }

        return Scaffold(
          backgroundColor: bgLight,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: primaryNavy),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text("Task Detail", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: Icon(Icons.edit_note_rounded, color: primaryNavy, size: 28),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditTaskPage(task: data)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.auto_delete_outlined, color: Colors.redAccent, size: 24),
                onPressed: () => _showDeleteConfirmation(context, taskId),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(isDone),
                    _buildEffortBadge(data['effort'] ?? 0),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  data['taskName'] ?? "Unnamed Task",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryNavy, letterSpacing: -0.5),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    _buildDetailCard(Icons.calendar_today_rounded, "Start Date", startStr, Colors.blue),
                    const SizedBox(width: 15),
                    _buildDetailCard(Icons.event_available_rounded, "Due Date", endStr, Colors.orange),
                  ],
                ),
                const SizedBox(height: 15),
                _buildPriorityFullCard(data['priority'] ?? "Medium"),
                const SizedBox(height: 40),
                Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy)),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Text(
                    (data['description'] == null || data['description'].isEmpty)
                        ? "No description provided."
                        : data['description'],
                    style: TextStyle(fontSize: 16, height: 1.8, color: Colors.blueGrey[800]),
                  ),
                ),
                const SizedBox(height: 40),
                _buildMarkAsDoneButton(taskId, isDone),
                const SizedBox(height: 15),
                _buildAIButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildEffortBadge(dynamic effort) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 4),
          Text(
            "$effort Hours",
            style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityFullCard(String priority) {
    Color pColor = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, color: pColor),
          const SizedBox(width: 12),
          Text("Priority:", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            priority.toUpperCase(),
            style: TextStyle(color: pColor, fontWeight: FontWeight.bold, fontSize: 15),
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
            style: TextStyle(color: isDone ? Colors.green[700] : primaryNavy, fontWeight: FontWeight.bold, fontSize: 12),
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkAsDoneButton(String taskId, bool isDone) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: OutlinedButton.icon(
        onPressed: () => _toggleTaskStatus(taskId, isDone),
        icon: Icon(isDone ? Icons.settings_backup_restore : Icons.check_circle_outline, color: isDone ? Colors.grey : Colors.green),
        label: Text(
          isDone ? "Mark as Pending" : "Mark as Completed",
          style: TextStyle(color: isDone ? Colors.grey[700] : Colors.green, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isDone ? Colors.grey[300]! : Colors.green),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildAIButton() {
    return Container(
      width: double.infinity, height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primaryNavy, const Color(0xFF2A5298)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: primaryNavy.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white),
            SizedBox(width: 12),
            Text("Analyze Risk with Planova AI", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete this Task?"),
        content: const Text("This task will be moved to History."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _moveToHistory(context, taskId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}