import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskHistoryPage extends StatefulWidget {
  const TaskHistoryPage({super.key});

  @override
  State<TaskHistoryPage> createState() => _TaskHistoryPageState();
}

class _TaskHistoryPageState extends State<TaskHistoryPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  final Color primaryNavy = const Color(0xFF1A4789);

  Set<String> selectedTaskIds = {};
  bool isSelectionMode = false;

  void _toggleSelection(String docId) {
    setState(() {
      if (selectedTaskIds.contains(docId)) {
        selectedTaskIds.remove(docId);
        if (selectedTaskIds.isEmpty) isSelectionMode = false;
      } else {
        selectedTaskIds.add(docId);
        isSelectionMode = true;
      }
    });
  }

  // Helper for Confirmation Dialogs
  Future<bool?> _showConfirmDialog(String title, String content, String confirmText, Color color) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBulkRestore() async {
    final confirmed = await _showConfirmDialog(
        "Restore Tasks",
        "Restore selected tasks? Tasks marked as 'DONE' will be reset to 'PENDING'.",
        "Restore",
        Colors.green
    );

    if (confirmed == true) {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // We need to fetch the current data for selected IDs to check their status
      // Or we can just apply the update to all selected tasks
      for (var id in selectedTaskIds) {
        DocumentReference docRef = FirebaseFirestore.instance.collection('tasks').doc(id);

        batch.update(docRef, {
          'isDeleted': false,
          'deletedAt': FieldValue.delete(),
          'status': 'PENDING', // Force status back to PENDING upon restore
        });
      }

      await batch.commit();
      setState(() {
        selectedTaskIds.clear();
        isSelectionMode = false;
      });
    }
  }

  Future<void> _handleBulkDelete() async {
    final confirmed = await _showConfirmDialog("Permanent Delete", "This will delete tasks forever. Proceed?", "Delete", Colors.red);
    if (confirmed == true) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var id in selectedTaskIds) {
        batch.delete(FirebaseFirestore.instance.collection('tasks').doc(id));
      }
      await batch.commit();
      setState(() { selectedTaskIds.clear(); isSelectionMode = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isSelectionMode
            ? IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() { isSelectionMode = false; selectedTaskIds.clear(); }))
            : IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A4789), size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(
          isSelectionMode ? "${selectedTaskIds.length} Selected" : "Task History",
          style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
        ),
        actions: [
          // If NOT in selection mode, show the "Enter Selection" button
          if (!isSelectionMode)
            IconButton(
              icon: Icon(Icons.checklist_rtl_rounded, color: primaryNavy),
              onPressed: () => setState(() => isSelectionMode = true),
              tooltip: "Select Tasks",
            ),

          // If IN selection mode, show Select All, Restore, and Delete
          if (isSelectionMode) ...[
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tasks').where('userId', isEqualTo: currentUserId).where('isDeleted', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                final allIds = snapshot.data?.docs.map((d) => d.id).toList() ?? [];
                bool isAllSelected = selectedTaskIds.length == allIds.length && allIds.isNotEmpty;
                return IconButton(
                  icon: Icon(isAllSelected ? Icons.deselect : Icons.select_all, color: primaryNavy),
                  onPressed: () => setState(() => isAllSelected ? selectedTaskIds.clear() : selectedTaskIds = allIds.toSet()),
                );
              },
            ),
            IconButton(icon: const Icon(Icons.restart_alt, color: Colors.green), onPressed: selectedTaskIds.isEmpty ? null : _handleBulkRestore),
            IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: selectedTaskIds.isEmpty ? null : _handleBulkDelete),
          ]
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('userId', isEqualTo: currentUserId)
            .where('isDeleted', isEqualTo: true)
            .orderBy('deletedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text("History is empty"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String docId = docs[index].id;
              final bool isSelected = selectedTaskIds.contains(docId);

              return _buildHistoryCard(data, docId, isSelected);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data, String docId, bool isSelected) {
    return GestureDetector(
      onLongPress: () => _toggleSelection(docId),
      onTap: () => isSelectionMode ? _toggleSelection(docId) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryNavy.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? primaryNavy : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            if (isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Icon(isSelected ? Icons.check_circle : Icons.radio_button_unchecked, color: isSelected ? primaryNavy : Colors.grey),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['taskName'] ?? "Unnamed Task", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy)),
                  Text("Priority: ${data['priority'] ?? 'Medium'}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            // Individual buttons only show when NOT in bulk selection mode
            if (!isSelectionMode) ...[
              IconButton(icon: const Icon(Icons.restart_alt, color: Colors.green), onPressed: () {
                setState(() => selectedTaskIds = {docId});
                _handleBulkRestore();
              }),
              IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: () {
                setState(() => selectedTaskIds = {docId});
                _handleBulkDelete();
              }),
            ]
          ],
        ),
      ),
    );
  }
}