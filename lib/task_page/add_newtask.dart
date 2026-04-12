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
  DateTime selectedDate = DateTime.now();
  final Color primaryNavy = const Color(0xFF1A4789);

  void _validateAndCreate() {
    if (_taskNameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _effortController.text.trim().isEmpty) {

      _showWarningDialog("Please fill in all details (Title, Description, and Effort) before creating the task.");
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
            const Text("Missing Info"),
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
      // 1. QUERY the collection instead of using .doc()
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user.uid) // Match the field shown in your screenshot
          .limit(1)
          .get();

      String fetchedUsername = "user";

      if (userQuery.docs.isNotEmpty) {
        final data = userQuery.docs.first.data() as Map<String, dynamic>;
        fetchedUsername = data['username'] ?? "user";
        print("Found Username: $fetchedUsername");
      } else {
        print("No document found with uid field: ${user.uid}");
      }

      // 2. Format the custom ID
      String cleanName = fetchedUsername.replaceAll(' ', '').toLowerCase();
      String timestamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
      String customId = "$cleanName-$timestamp";
      String taskName = _taskNameController.text.toUpperCase();

      // 3. Save Task
      await FirebaseFirestore.instance.collection('tasks').doc(customId).set({
        'userId': user.uid,
        'taskId': customId,
        'taskName': taskName.trim(),
        'taskDate': selectedDate.toIso8601String(),
        'description': _descriptionController.text.trim(),
        'effort': _effortController.text.trim(),
        'priority': selectedPriority,
        'status': currentStatus,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("Error: $e");
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
        title: Text(
          "New Task",
          style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label("TASK NAME"),
            _textField(_taskNameController, "e.g., Database Design"),

            const SizedBox(height: 20),
            _label("DESCRIPTION"),
            _textField(_descriptionController, "Details about the assignment...", maxLines: 3),

            const SizedBox(height: 20),
            _label("DUE DATE"),
            _datePicker(),

            const SizedBox(height: 20),
            _label("EFFORT (HRS)"),
            _textField(
              _effortController,
              "2",
              keyboardType: TextInputType.number,
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.6), // 👈 shadow effect here only
              ),
            ),

            const SizedBox(height: 20),
            _label("PRIORITY"),
            _prioritySelector(),

            const SizedBox(height: 40),
            _buildSubmitButton(),
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
        style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _textField(
      TextEditingController controller,
      String hint, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
        TextStyle? hintStyle, // 👈 add this
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: hintStyle, // 👈 apply here
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _datePicker() {
    return GestureDetector(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: primaryNavy),
            const SizedBox(width: 10),
            Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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