import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddTaskPage extends StatefulWidget {
  final String workspaceId;
  const AddTaskPage({super.key, required this.workspaceId});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _effortController = TextEditingController();

  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  String? _selectedAssignee;
  String _priority = "MEDIUM";

  final Color primaryNavy = const Color(0xFF1A4789);

  Stream<List<Map<String, dynamic>>> _getWorkspaceMembers() {
    return FirebaseFirestore.instance
        .collection('workspaces')
        .doc(widget.workspaceId)
        .snapshots()
        .asyncMap((wsSnap) async {
      if (!wsSnap.exists) return [];

      // This gets the list of raw UIDs: ["cVgbG...", "1hzfM...", "AYGTm..."]
      List<dynamic> memberIds = wsSnap.data()?['members'] ?? [];
      if (memberIds.isEmpty) return [];

      // 🔥 FIX: Query the 'uid' FIELD inside the documents, not the Document ID itself
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', whereIn: memberIds.take(10).toList())
          .get();

      return userQuery.docs.map((doc) => {
        'uid': doc.data()['uid'], // The actual Firebase UID
        'name': doc.data()['username'] ?? 'Unknown', // Matches your "username" field in DB
      }).toList();
    });
  }

  Future<void> _createTask() async {
    if (_titleController.text.isEmpty || _selectedAssignee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in the title and assign a member")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('workspaces')
        .doc(widget.workspaceId)
        .collection('tasks')
        .add({
      'taskName': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'effort': _effortController.text.trim(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'priority': _priority,
      'assignedTo': _selectedAssignee,
      'status': 'PENDING',
      'isDeleted': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("New Task", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel("TASK TITLE"),
            _textField(_titleController, "e.g., Database Design"),

            const SizedBox(height: 20),
            _sectionLabel("DESCRIPTION"),
            _textField(_descController, "Details about the assignment...", maxLines: 3),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel("ASSIGN TO"),
                      _buildMemberDropdown(),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel("EFFORT (HRS)"),
                      _textField(_effortController, "2", keyboardType: TextInputType.number),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel("START DATE"),
                      _datePicker(isStartDate: true),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel("END DATE"),
                      _datePicker(isStartDate: false),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),
            _sectionLabel("PRIORITY"),
            _buildPriorityPicker(),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: _createTask,
                child: const Text(
                  "Create Smart Task  >",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Your DatePicker logic integrated
  Widget _datePicker({required bool isStartDate}) {
    DateTime displayDate = isStartDate ? startDate : endDate;
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    return GestureDetector(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: displayDate.isBefore(today) ? today : displayDate,
          firstDate: today,
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryNavy,
                  onPrimary: Colors.white,
                  onSurface: primaryNavy,
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

  Widget _buildMemberDropdown() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getWorkspaceMembers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _styledDropdownWrapper(
            child: const Text("Fetching team...", style: TextStyle(color: Colors.grey, fontSize: 13)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _styledDropdownWrapper(
            child: const Text("No members in group", style: TextStyle(color: Colors.redAccent, fontSize: 13)),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // Matching your text field color
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedAssignee,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryNavy),
              hint: const Text("Select Member", style: TextStyle(fontSize: 13, color: Colors.grey)),
              borderRadius: BorderRadius.circular(15), // Rounded corners for the popup menu
              dropdownColor: Colors.white,
              items: snapshot.data!.map((member) {
                return DropdownMenuItem<String>(
                  value: member['uid'],
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: primaryNavy.withOpacity(0.1),
                        child: Text(
                          member['name'][0].toUpperCase(),
                          style: TextStyle(fontSize: 10, color: primaryNavy, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        member['name'],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedAssignee = val),
            ),
          ),
        );
      },
    );
  }

// Helper wrapper for loading/error states to keep size consistent
  Widget _styledDropdownWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _buildPriorityPicker() {
    List<String> priorities = ["LOW", "MEDIUM", "HIGH", "CRITICAL"];
    return Row(
      children: priorities.map((p) {
        bool isSelected = _priority == p;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _priority = p),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? primaryNavy : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _textField(TextEditingController controller, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}