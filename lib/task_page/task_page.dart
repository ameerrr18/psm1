import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_newtask.dart';
import 'package:intl/intl.dart';
import 'detailtask_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskPage extends StatefulWidget {
  final VoidCallback? onBack;
  const TaskPage({super.key, this.onBack});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  String searchQuery = "";
  String filterPriority = "All";
  String filterStatus = "All";
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  void _confirmCompleteTask(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Complete Task"),
        content: Text("Mark '${task['taskName']}' as completed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('tasks')
                  .doc(task['taskId'])
                  .update({'status': "DONE"});
              Navigator.pop(context);
            },
            child: const Text(
              "Confirm",
              style: TextStyle(color: Color(0xFF1A4789), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFFF5252);
      case 'HIGH':
        return const Color(0xFF1A4789);
      case 'MEDIUM':
        return const Color(0xFF4FC3F7);
      case 'LOW':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showFilterMenu() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              right: 30,
              top: 160,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "PRIORITY",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _filterItem("All", filterPriority, (v) => setState(() => filterPriority = v)),
                      _filterItem("Low", filterPriority, (v) => setState(() => filterPriority = v)),
                      _filterItem("Medium", filterPriority, (v) => setState(() => filterPriority = v)),
                      _filterItem("High", filterPriority, (v) => setState(() => filterPriority = v)),
                      _filterItem("Critical", filterPriority, (v) => setState(() => filterPriority = v)),
                      const SizedBox(height: 15),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "STATUS",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _filterItem("All", filterStatus, (v) => setState(() => filterStatus = v)),
                      _filterItem("PENDING", filterStatus, (v) => setState(() => filterStatus = v)),
                      _filterItem("DONE", filterStatus, (v) => setState(() => filterStatus = v)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterItem(String text, String selected, Function(String) onTap) {
    bool isSelected = text == selected;

    return InkWell(
      onTap: () {
        onTap(text);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            if (isSelected)
              const Icon(Icons.check, size: 18, color: Color(0xFF1A4789))
            else
              const SizedBox(width: 18),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1A4789),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("All Tasks",
            style: TextStyle(color: Color(0xFF1A4789), fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const AddNewTask())),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("New"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A4789),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: "Search tasks...",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showFilterMenu,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.filter_list, color: Color(0xFF1A4789)),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('userId', isEqualTo: currentUserId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  // --- FIX: Handle missing isDeleted field ---
                  final bool isDeleted = data['isDeleted'] ?? false;
                  if (isDeleted) return false; // Hide if it is explicitly deleted

                  final name = (data['taskName'] ?? "").toLowerCase();
                  final priority = (data['priority'] ?? "");
                  final status = (data['status'] ?? "PENDING");

                  bool matchesSearch = name.contains(searchQuery);
                  bool matchesPriority = filterPriority == "All" || priority.toUpperCase() == filterPriority.toUpperCase();
                  bool matchesStatus = filterStatus == "All" || status.toUpperCase() == filterStatus.toUpperCase();

                  return matchesSearch && matchesPriority && matchesStatus;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          "No tasks found",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isEmpty ? "Start by adding a new task!" : "Try a different search or filter",
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                }
                // --------------------------------------------------------

                docs.sort((a, b) {
                  final aDone = (a['status'] == "DONE") ? 1 : 0;
                  final bDone = (b['status'] == "DONE") ? 1 : 0;
                  return aDone.compareTo(bDone);
                });

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    data['taskId'] = docs[index].id;
                    return _buildTaskCard(context, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Map<String, dynamic> task) {
    bool isDone = task['status'] == "DONE";

    DateTime date = DateTime.parse(task['taskDate']);
    String formattedDate = DateFormat('MMM d').format(date).toUpperCase();

    return Dismissible(
      // --- FIX: ValueKey ensures unique identity during swipe ---
      key: ValueKey(task['taskId']),
      direction: DismissDirection.horizontal,

      background: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.only(left: 20),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Icon(Icons.check, color: Colors.white),
      ),

      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(25),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),

      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (isDone) return false;

          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Complete Task"),
              content: Text("Mark '${task['taskName']}' as completed?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Confirm", style: TextStyle(color: Color(0xFF1A4789), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        } else {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Delete Task"),
              content: Text("Are you sure you want to delete '${task['taskName']}'?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      },

      onDismissed: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Mark as DONE logic
          await FirebaseFirestore.instance
              .collection('tasks')
              .doc(task['taskId'])
              .update({'status': "DONE"});
        } else {
          final String taskId = task['taskId'];

          try {
            // SOFT DELETE: Move to history instead of deleting permanently
            await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
              'isDeleted': true,
              'deletedAt': FieldValue.serverTimestamp(),
            });

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${task['taskName']} moved to Task History"),
                  backgroundColor: const Color(0xFF1A4789),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            debugPrint("Error moving to history: $e");
          }
        }
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailTaskPage(task: task),
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFFF3F6FA) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDone ? 0.02 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (isDone) {
                        FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(task['taskId'])
                            .update({'status': "PENDING"});
                      } else {
                        _confirmCompleteTask(task);
                      }
                    },
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: isDone ? 1.2 : 1,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone ? const Color(0xFF1A4789) : Colors.transparent,
                          border: Border.all(color: const Color(0xFF1A4789), width: 2),
                        ),
                        child: isDone
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      task['taskName'] ?? 'No Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDone ? Colors.grey : const Color(0xFF1A4789),
                        decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone
                          ? Colors.grey.shade300
                          : _getPriorityColor(task['priority'] ?? 'MEDIUM'),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task['priority'] ?? 'MEDIUM',
                      style: TextStyle(
                        color: isDone ? Colors.grey[600] : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const SizedBox(width: 39),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text("${task['effort']}H", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(width: 15),
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const SizedBox(width: 39),
                  _buildAnalyzeButton(),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFF1F4F8), borderRadius: BorderRadius.circular(15)),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, size: 14, color: Color(0xFF1A4789)),
          SizedBox(width: 6),
          Text("Analyze Risk", style: TextStyle(color: Color(0xFF1A4789), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}