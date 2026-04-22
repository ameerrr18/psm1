import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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

  // --- LOGIC: Toggle Selection ---
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

  int _getDaysRemaining(Timestamp? expireAt) {
    if (expireAt == null) return 30;
    final now = DateTime.now();
    final expiration = expireAt.toDate();

    // Use difference in hours for more precision on the last day
    final hoursLeft = expiration.difference(now).inHours;

    if (hoursLeft <= 0) return 0; // It should be gone
    return expiration.difference(now).inDays;
  }

  // --- ACTIONS: Restore & Delete ---
  Future<void> _handleBulkRestore() async {
    bool? confirmed = await _showConfirmDialog(
        "Restore Tasks",
        "Selected tasks will be returned to your active schedule.",
        "Restore",
        Colors.green
    );

    if (confirmed == true) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var id in selectedTaskIds) {
        DocumentReference docRef = FirebaseFirestore.instance.collection('tasks').doc(id);
        batch.update(docRef, {
          'isDeleted': false,
          'status': 'PENDING',
          'deletedAt': FieldValue.delete(),
          'expireAt': FieldValue.delete(),
        });
      }
      await batch.commit();
      _exitSelectionMode();
    }
  }

  Future<void> _handleBulkPermanentDelete() async {
    bool? confirmed = await _showConfirmDialog(
        "Permanent Delete",
        "Warning: This action cannot be undone. Selected tasks will be deleted forever.",
        "Delete Permanently",
        Colors.red
    );

    if (confirmed == true) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var id in selectedTaskIds) {
        DocumentReference docRef = FirebaseFirestore.instance.collection('tasks').doc(id);
        batch.delete(docRef);
      }
      await batch.commit();
      _exitSelectionMode();
    }
  }

  void _exitSelectionMode() {
    setState(() {
      selectedTaskIds.clear();
      isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isSelectionMode
            ? IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: _exitSelectionMode)
            : IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryNavy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isSelectionMode ? "${selectedTaskIds.length} Selected" : "Trash Recovery",
          style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isSelectionMode) ...[
            // 🔥 Select All Button
            StreamBuilder<QuerySnapshot>(
              // Update this specific stream in your actions:
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('userId', isEqualTo: currentUserId)
                  .where('isDeleted', isEqualTo: true)
                  .where('expireAt', isGreaterThan: Timestamp.now())
                  .snapshots(),
              builder: (context, snapshot) {
                final allIds = snapshot.data?.docs.map((d) => d.id).toList() ?? [];
                bool isAllSelected = selectedTaskIds.length == allIds.length && allIds.isNotEmpty;

                return IconButton(
                  icon: Icon(isAllSelected ? Icons.deselect : Icons.select_all, color: primaryNavy),
                  onPressed: () {
                    setState(() => isAllSelected ? selectedTaskIds.clear() : selectedTaskIds = allIds.toSet());
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.restart_alt, color: Colors.green),
              onPressed: selectedTaskIds.isEmpty ? null : _handleBulkRestore,
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              onPressed: selectedTaskIds.isEmpty ? null : _handleBulkPermanentDelete,
            ),
          ] else
            IconButton(
              icon: Icon(Icons.checklist_rtl_rounded, color: primaryNavy),
              onPressed: () => setState(() => isSelectionMode = true),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('userId', isEqualTo: currentUserId)
            .where('isDeleted', isEqualTo: true)
        // 🔥 ONLY show tasks that have NOT expired yet
            .where('expireAt', isGreaterThan: Timestamp.now())
            .orderBy('expireAt', descending: false) // Shows those about to expire first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Note: Chaining 'where' with 'orderBy' usually requires a Firestore Index.
            // Check your debug console for the link to create it!
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Trash is empty"));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String docId = docs[index].id;
              final bool isSelected = selectedTaskIds.contains(docId);

              // Calculate the days remaining for the UI
              int daysLeft = _getDaysRemaining(data['expireAt'] as Timestamp?);

              return _buildHistoryCard(data, docId, isSelected, daysLeft);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> data, String docId, bool isSelected, int daysLeft) {
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
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
                  Text(data['taskName'] ?? "Unnamed Task", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: daysLeft < 7 ? Colors.red : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "$daysLeft days until deleted",
                        style: TextStyle(color: daysLeft < 7 ? Colors.red : Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isSelectionMode) ...[
              IconButton(
                icon: const Icon(Icons.history, color: Colors.green),
                onPressed: () {
                  setState(() => selectedTaskIds = {docId});
                  _handleBulkRestore();
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                onPressed: () {
                  setState(() => selectedTaskIds = {docId});
                  _handleBulkPermanentDelete();
                },
              ),
            ]
          ],
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content, String confirmText, Color color) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _cleanOldTasks() async {
    var expiredTasks = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: currentUserId)
        .where('isDeleted', isEqualTo: true)
        .where('expireAt', isLessThan: Timestamp.now())
        .get();

    if (expiredTasks.docs.isNotEmpty) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var doc in expiredTasks.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print("Cleaned up ${expiredTasks.docs.length} old tasks.");
    }
  }

  @override
  void initState() {
    super.initState();
    _cleanOldTasks();
  }

}