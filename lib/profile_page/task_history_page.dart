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
  final Color accentBlue = const Color(0xFF3B82F6);
  final Color bgLight = const Color(0xFFF1F5F9);

  Set<String> selectedTaskIds = {};
  bool isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _cleanOldTasks();
  }

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
      backgroundColor: bgLight,
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(),
          _buildTrashStatusHeader(),
          _buildTaskList(),
        ],
      ),
      bottomNavigationBar: isSelectionMode ? _buildBottomActionBar() : null,
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: isSelectionMode
          ? IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: _exitSelectionMode)
          : IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: primaryNavy, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        isSelectionMode ? "${selectedTaskIds.length} Selected" : "Trash Recovery",
        style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        if (!isSelectionMode)
          IconButton(
            icon: Icon(Icons.checklist_rtl_rounded, color: primaryNavy),
            onPressed: () => setState(() => isSelectionMode = true),
          )
        else
          _buildSelectAllButton(),
      ],
    );
  }

  Widget _buildSelectAllButton() {
    return StreamBuilder<QuerySnapshot>(
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
    );
  }

  Widget _buildTrashStatusHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryNavy, accentBlue]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_delete_outlined, color: Colors.white70, size: 30),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Automatic Cleanup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text("Tasks stay here for 30 days before permanent deletion.",
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: currentUserId)
          .where('isDeleted', isEqualTo: true)
          .where('expireAt', isGreaterThan: Timestamp.now())
          .orderBy('expireAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Using a trash-specific icon but keeping the grey theme and 60px size
                  Icon(
                    Icons.delete_outline_rounded,
                    size: 60,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  // Title following the Task theme (18px, grey[500], w500)
                  Text(
                    "Trash is empty",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle following the Task theme (grey[400])
                  Text(
                    "Items you delete will appear here.",
                    style: TextStyle(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final String docId = docs[index].id;
                final bool isSelected = selectedTaskIds.contains(docId);
                int daysLeft = _getDaysRemaining(data['expireAt'] as Timestamp?);

                return _buildModernHistoryCard(data, docId, isSelected, daysLeft);
              },
              childCount: docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernHistoryCard(Map<String, dynamic> data, String docId, bool isSelected, int daysLeft) {
    bool isUrgent = daysLeft < 7;

    return GestureDetector(
      onLongPress: () => _toggleSelection(docId),
      onTap: () => isSelectionMode ? _toggleSelection(docId) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isSelected ? accentBlue : Colors.white, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            if (isSelectionMode)
              Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: isSelected ? accentBlue : Colors.grey[300]),
            if (isSelectionMode) const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['taskName'] ?? "Unnamed Task",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isUrgent ? Colors.red : Colors.orange).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule_rounded, size: 12, color: isUrgent ? Colors.red : Colors.orange),
                        const SizedBox(width: 4),
                        Text("$daysLeft days left",
                            style: TextStyle(color: isUrgent ? Colors.red : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isSelectionMode) _buildQuickActions(docId),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(String docId) {
    return Row(
      children: [
        _circleIconButton(Icons.settings_backup_restore_rounded, Colors.green, () {
          selectedTaskIds = {docId};
          _handleBulkRestore();
        }),
        const SizedBox(width: 8),
        _circleIconButton(Icons.delete_forever_rounded, Colors.redAccent, () {
          selectedTaskIds = {docId};
          _handleBulkPermanentDelete();
        }),
      ],
    );
  }

  Widget _circleIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.restore),
                label: const Text("Restore"),
                onPressed: selectedTaskIds.isEmpty ? null : _handleBulkRestore,
                style: ElevatedButton.styleFrom(foregroundColor: Colors.white ,iconColor: Colors.white ,backgroundColor: Colors.green, shape: StadiumBorder()),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text("Delete"),
                onPressed: selectedTaskIds.isEmpty ? null : _handleBulkPermanentDelete,
                style: ElevatedButton.styleFrom(foregroundColor: Colors.white ,iconColor: Colors.white, backgroundColor: Colors.redAccent, shape: StadiumBorder()),
              ),
            ),
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
}