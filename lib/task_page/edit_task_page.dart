import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTaskPage extends StatefulWidget {
  final Map<String, dynamic> task; // Pass the existing task data here
  const EditTaskPage({super.key, required this.task});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  late TextEditingController _taskNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _effortController;

  late String selectedPriority;
  late DateTime selectedDate;
  final Color primaryNavy = const Color(0xFF1A4789);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing task data
    _taskNameController = TextEditingController(text: widget.task['taskName']);
    _descriptionController = TextEditingController(text: widget.task['description']);
    _effortController = TextEditingController(text: widget.task['effort'].toString());

    // Normalize priority to UPPERCASE to avoid Dropdown/Selection mismatch errors
    selectedPriority = (widget.task['priority'] ?? "MEDIUM").toString().toUpperCase();

    // Parse the existing date
    selectedDate = DateTime.parse(widget.task['taskDate'] ?? DateTime.now().toIso8601String());
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _descriptionController.dispose();
    _effortController.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    if (_taskNameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _effortController.text.trim().isEmpty) {
      _showWarningDialog("Please ensure Title, Description, and Effort are filled.");
      return;
    }
    _updateTask();
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Missing Info"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  Future<void> _updateTask() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.task['taskId']) // Use the specific document ID
          .update({
        'taskName': _taskNameController.text.trim().toUpperCase(),
        'description': _descriptionController.text.trim(),
        'effort': _effortController.text.trim(),
        'taskDate': selectedDate.toIso8601String(),
        'priority': selectedPriority,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context); // Return to Detail Page
    } catch (e) {
      setState(() => _isSaving = false);
      print("Error updating task: $e");
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
        title: Text("Edit Task", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label("TASK NAME"),
            _textField(_taskNameController, "e.g., Database Design"),

            const SizedBox(height: 20),
            _label("DESCRIPTION"),
            _textField(_descriptionController, "Details...", maxLines: 3),

            const SizedBox(height: 20),
            _label("DUE DATE"),
            _datePicker(),

            const SizedBox(height: 20),
            _label("EFFORT (HRS)"),
            _textField(_effortController, "2", keyboardType: TextInputType.number),

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

  // --- UI COMPONENTS (Identical to AddNewTask for consistency) ---

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
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
        onPressed: _validateAndSave,
        child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}