import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditTaskPage extends StatefulWidget {
  final Map<String, dynamic> task; // Task data passed from Detail Page
  const EditTaskPage({super.key, required this.task});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  late TextEditingController _taskNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _effortController;

  late String selectedPriority;
  late DateTime startDate;
  late DateTime endDate;

  final Color primaryNavy = const Color(0xFF1A4789);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize data from the existing task
    _taskNameController = TextEditingController(text: widget.task['taskName']);
    _descriptionController = TextEditingController(text: widget.task['description']);
    _effortController = TextEditingController(text: widget.task['effort']?.toString() ?? "0");

    selectedPriority = (widget.task['priority'] ?? "MEDIUM").toString().toUpperCase();

    // Parse existing dates from Firestore strings
    startDate = DateTime.parse(widget.task['startDate'] ?? DateTime.now().toIso8601String());
    endDate = DateTime.parse(widget.task['endDate'] ?? DateTime.now().add(const Duration(days: 1)).toIso8601String());
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
      _showWarningDialog("Please ensure all fields are filled before saving.");
      return;
    }

    if (endDate.isBefore(startDate)) {
      _showWarningDialog("The End Date cannot be earlier than the Start Date.");
      return;
    }

    _updateTask();
  }

  void _showWarningDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Action Required", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _updateTask() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(widget.task['taskId']) // Using the ID from the passed task map
          .update({
        'taskName': _taskNameController.text.trim().toUpperCase(),
        'description': _descriptionController.text.trim(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'effort': _effortController.text.trim(),
        'priority': selectedPriority,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context); // Go back to Detail Page
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
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// 🔥 SCROLLABLE FORM
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("TASK NAME"),
                    _textField(_taskNameController, "e.g., Database Design"),

                    const SizedBox(height: 20),
                    _label("DESCRIPTION"),
                    _textField(_descriptionController, "Assignment details...", maxLines: 3),

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
                onPressed: _validateAndSave,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Update Smart Task",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.save_as_rounded, color: Colors.white),
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

  // --- REUSABLE DESIGN COMPONENTS ---

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
    final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return GestureDetector(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: displayDate,
          firstDate: today,
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: primaryNavy, onPrimary: Colors.white, onSurface: primaryNavy),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          setState(() {
            if (isStartDate) {
              startDate = picked;
              if (startDate.isAfter(endDate)) endDate = startDate;
            } else {
              endDate = picked;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(15)),
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
        onPressed: _validateAndSave,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Update Smart Task", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Icon(Icons.save_as_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}