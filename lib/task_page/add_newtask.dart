import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddNewTask extends StatefulWidget {
  const AddNewTask({super.key});

  @override
  State<AddNewTask> createState() => _AddNewTaskState();
}

class _AddNewTaskState extends State<AddNewTask> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _effortController = TextEditingController();

  String selectedPriority = "MEDIUM";
  String currentStatus = "PENDING";

  // 🔥 Separate Start and End Dates
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now().add(const Duration(days: 1)); // Default end to tomorrow

  final Color primaryNavy = const Color(0xFF1A4789);

  void _validateAndCreate() {
    if (_taskNameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _effortController.text.trim().isEmpty) {
      _showWarningDialog("Please fill in all details before creating the task.");
      return;
    }

    // 🔥 Logical check: End date must be after or on start date
    if (endDate.isBefore(startDate)) {
      _showWarningDialog("End date (Due Date) cannot be before the Start Date.");
      return;
    }

    _createTask();
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 10),
            const Text("Action Required"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _createTask() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      String fetchedUsername = "user";
      if (userQuery.docs.isNotEmpty) {
        final data = userQuery.docs.first.data() as Map<String, dynamic>;
        fetchedUsername = data['username'] ?? "user";
      }

      String cleanName = fetchedUsername.replaceAll(' ', '').toLowerCase();
      String timestamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
      String customId = "$cleanName-$timestamp";
      String taskName = _taskNameController.text.toUpperCase();

      WriteBatch batch = FirebaseFirestore.instance.batch();

      // --- 1. CREATE THE TASK ---
      await FirebaseFirestore.instance.collection('tasks').doc(customId).set({
        'userId': user.uid,
        'taskId': customId,
        'taskName': taskName.trim(),
        'isDeleted': false,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'description': _descriptionController.text.trim(),
        'effort': _effortController.text.trim(),
        'priority': selectedPriority,
        'status': currentStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // --- 2. CREATE THE NOTIFICATION (NEW) ---
      // This ensures the NotiPage will show this new entry immediately
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid, // Field name must match your NotiPage query
        'title': 'New Task Assigned',
        'message': 'You created: $taskName',
        'type': 'task',
        'targetId': customId, // This links back to the task we just created
        'timestamp': FieldValue.serverTimestamp(), // Critical for 'orderBy'
      });

      await batch.commit();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error: $e");
      _showWarningDialog("Failed to create task. Please try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("New Task", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// 🔥 SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("TASK NAME"),
                    _textField(_taskNameController, "e.g., Database Design"),

                    const SizedBox(height: 20),
                    _label("DESCRIPTION"),
                    _textField(_descriptionController, "Details about the assignment...", maxLines: 3),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("START DATE"),
                              _datePicker(isStartDate: true),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label("END DATE (DUE)"),
                              _datePicker(isStartDate: false),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    _label("EFFORT (HRS)"),
                    _textField(_effortController, "2", keyboardType: TextInputType.number),

                    const SizedBox(height: 20),
                    _label("PRIORITY"),
                    _prioritySelector(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            /// 🔥 BUTTON (ALWAYS ABOVE KEYBOARD)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: _validateAndCreate,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Create Smart Task",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _datePicker({required bool isStartDate}) {
    DateTime displayDate = isStartDate ? startDate : endDate;

    // 🔥 Define "Today" at the start of the day (00:00:00)
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    return GestureDetector(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: displayDate.isBefore(today) ? today : displayDate,

          // 🔥 This prevents picking any date before today
          firstDate: today,

          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryNavy, // Header background color
                  onPrimary: Colors.white, // Header text color
                  onSurface: primaryNavy, // Body text color
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          setState(() {
            if (isStartDate) {
              startDate = picked;
              // Ensure End Date is at least the same as Start Date
              if (startDate.isAfter(endDate)) {
                endDate = startDate;
              }
            } else {
              endDate = picked;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(15)
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: primaryNavy),
            const SizedBox(width: 8),
            Text(
              DateFormat('dd/MM/yyyy').format(displayDate),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prioritySelector() {
    List<String> priorities = ["LOW", "MEDIUM", "HIGH", "CRITICAL"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: priorities.map((p) {
        bool isSelected = selectedPriority == p;
        return GestureDetector(
          onTap: () => setState(() => selectedPriority = p),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? primaryNavy : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              p,
              style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        onPressed: _validateAndCreate,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Create Smart Task", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}