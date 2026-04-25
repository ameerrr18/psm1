import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'add_task.dart';
import 'task_detail.dart';

class WorkspaceDetailPage extends StatelessWidget {
  final String workspaceId;
  const WorkspaceDetailPage({super.key, required this.workspaceId});

  final Color primaryNavy = const Color(0xFF1A4789);
  final Color bgBlue = const Color(0xFFF4F7FA);

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('workspaces').doc(workspaceId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        bool isAdmin = data['adminId'] == currentUid;
        bool isActive = data['status'] == 'active';
        List members = data['members'] ?? [];
        String joinCode = data['joinCode'] ?? "N/A";

        return Scaffold(
          backgroundColor: bgBlue,
          floatingActionButton: isActive
              ? FloatingActionButton(
            backgroundColor: primaryNavy,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddTaskPage(workspaceId: workspaceId)),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          )
              : null,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  // 🔥 Notification Bell for Admin to see Join Requests
                  if (isAdmin) _buildRequestNotification(context),

                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.black87),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (value) => _handleMenuSelection(
                          context, value, workspaceId, isActive, data['name'], data['description'], currentUid),
                      itemBuilder: (context) => [
                        if (isAdmin) ...[
                          _buildMenuItem('edit', Icons.edit_outlined, "Edit Workspace"),
                          _buildMenuItem('status', Icons.power_settings_new, isActive ? "Deactivate" : "Activate"),
                          const PopupMenuDivider(),
                          _buildMenuItem('delete', Icons.delete_outline, "Delete", color: Colors.red),
                        ] else ...[
                          _buildMenuItem('leave', Icons.logout, "Leave Workspace", color: Colors.red),
                        ],
                      ],
                    ),
                  )
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.fromLTRB(25, 100, 25, 20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statusBadge(isActive),
                        const SizedBox(height: 8),
                        Text(data['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A4789))),
                        const SizedBox(height: 4),
                        Text(data['description'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text("TEAMMATE PORTAL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      _buildAccessKeyCard(context, joinCode),
                      const SizedBox(height: 25),
                      const Text("COLLABORATORS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      _buildAvatarStack(context, members),
                      const SizedBox(height: 30),
                      const Text("TASK BACKLOG", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              _buildSliverTaskList(workspaceId, isActive),
            ],
          ),
        );
      },
    );
  }

  // --- REQUEST MANAGEMENT UI ---

  // Update the sub-collection name to match your screenshot: 'joinRequests'
  Widget _buildRequestNotification(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('joinRequests') // Match your Firebase screenshot
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black87),
              onPressed: () => _showRequestsDialog(context),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text("$count", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )
          ],
        );
      },
    );
  }

  void _showRequestsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('workspaces')
              .doc(workspaceId)
              .collection('joinRequests') // Match your Firebase screenshot
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            var docs = snapshot.data!.docs;

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("Join Requests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Divider(),
                  Expanded(
                    child: docs.isEmpty
                        ? const Center(child: Text("No pending requests"))
                        : ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        var request = docs[i].data() as Map<String, dynamic>;
                        String userId = request['uid'] ?? docs[i].id;
                        String userName = request['name'] ?? "Unknown User";
                        String userEmail = request['email'] ?? "";

                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(userName),
                          subtitle: Text(userEmail),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => _approveUser(userId),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _rejectUser(userId),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _approveUser(String uid) async {
    // 1. Add the UID to the members array in the main workspace document
    await FirebaseFirestore.instance.collection('workspaces').doc(workspaceId).update({
      'members': FieldValue.arrayUnion([uid])
    });

    // 2. Clean up: Delete the request document after approval
    _rejectUser(uid);
  }

  void _rejectUser(String uid) {
    FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .collection('joinRequests') // Ensure this matches 'joinRequests'
        .doc(uid)
        .delete();
  }

  // --- EXISTING UI HELPERS (STYLIZED) ---

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String text, {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.black87),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAccessKeyCard(BuildContext context, String code) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2B5896), Color(0xFF1E3C72)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ACCESS KEY", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(code, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _cardButton(Icons.copy, "Copy", () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Key copied!")));
                }),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showFullQR(context, code),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: QrImageView(
                data: code,
                version: QrVersions.auto,
                size: 75,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAvatarStack(BuildContext context, List members) {
    return Row(
      children: [
        ...members.take(4).map((m) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(radius: 20, backgroundColor: primaryNavy.withOpacity(0.1), child: const Icon(Icons.person, size: 20)),
        )),
        if (members.length > 4)
          CircleAvatar(radius: 20, backgroundColor: Colors.grey[300], child: Text("+${members.length - 4}", style: const TextStyle(fontSize: 12, color: Colors.black54))),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _showAddMemberDialog(context, members),
          child: CircleAvatar(radius: 20, backgroundColor: const Color(0xFFE3F2FD), child: Icon(Icons.add, color: primaryNavy)),
        ),
      ],
    );
  }

  Widget _buildSliverTaskList(String id, bool isActive) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('workspaces').doc(id).collection('tasks').where('isDeleted', isEqualTo: false).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SliverToBoxAdapter(child: SizedBox());
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                var doc = snap.data!.docs[index];
                var task = doc.data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailPage(taskId: doc.id, workspaceId: workspaceId))),
                  child: _taskCard(task),
                );
              },
              childCount: snap.data!.docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _taskCard(Map<String, dynamic> task) => Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Row(
      children: [
        const Icon(Icons.radio_button_unchecked, color: Colors.grey),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task['taskName'] ?? "Task", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text("${task['endDate']} • MEMBER", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
        _priorityBadge(task['priority'] ?? 'MEDIUM'),
      ],
    ),
  );

  // --- DIALOGS ---

  void _handleMenuSelection(BuildContext context, String val, String id, bool status, String name, String desc, String currentUid) {
    if (val == 'status') {
      FirebaseFirestore.instance.collection('workspaces').doc(id).update({'status': status ? 'inactive' : 'active'});
    } else if (val == 'delete') {
      _confirmDelete(context, id);
    } else if (val == 'edit') {
      _showEditDialog(context, id, name, desc);
    } else if (val == 'leave') {
      _confirmLeave(context, id, currentUid);
    }
  }

  void _confirmLeave(BuildContext context, String workspaceId, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Leave Workspace?"),
        content: const Text("You will no longer have access to this portal."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () {
            FirebaseFirestore.instance.collection('workspaces').doc(workspaceId).update({'members': FieldValue.arrayRemove([uid])});
            Navigator.pop(context); Navigator.pop(context);
          }, child: const Text("Leave", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, List existingMembers) {
    final String authUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        // Use a Query instead of a direct .doc() to find the custom UID_XXXX document
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('uid', isEqualTo: authUid)
              .snapshots(),
          builder: (context, userQuerySnap) {
            if (userQuerySnap.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }

            if (!userQuerySnap.hasData || userQuerySnap.data!.docs.isEmpty) {
              return const SizedBox(height: 200, child: Center(child: Text("User profile not found")));
            }

            // Extract friends list from your document
            var userData = userQuerySnap.data!.docs.first.data() as Map<String, dynamic>;
            List friends = userData['friends'] ?? [];

            // 2. Filter out members already in the workspace
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('workspaces')
                  .doc(workspaceId)
                  .collection('joinRequests')
                  .snapshots(),
              builder: (context, requestSnap) {
                if (!requestSnap.hasData) return const Center(child: CircularProgressIndicator());

                List pendingUids = requestSnap.data!.docs.map((doc) => doc.id).toList();

                // Logic: Must be a friend, NOT already a member, and NOT already invited
                List eligible = friends.where((f) =>
                !existingMembers.contains(f) && !pendingUids.contains(f)
                ).toList();

                return Container(
                  padding: const EdgeInsets.all(20),
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    children: [
                      const Text("Invite Friends", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const Divider(),
                      Expanded(
                        child: eligible.isEmpty
                            ? const Center(child: Text("No friends to invite"))
                            : ListView.builder(
                          itemCount: eligible.length,
                          itemBuilder: (context, i) => _buildFriendTile(eligible[i].toString(), context),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFriendTile(String friendUid, BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      // Query the users collection to find the friend's details by their UID field
      future: FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: friendUid)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox();

        var data = snap.data!.docs.first.data() as Map<String, dynamic>;
        String name = data['username'] ?? "Unknown";
        String email = data['email'] ?? "";

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: primaryNavy.withOpacity(0.1),
            child: Text(name[0].toUpperCase(), style: TextStyle(color: primaryNavy)),
          ),
          title: Text(name),
          subtitle: Text(email),
          trailing: IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: () {
              // Write to the 'joinRequests' sub-collection per your DB structure
              FirebaseFirestore.instance
                  .collection('workspaces')
                  .doc(workspaceId)
                  .collection('joinRequests')
                  .doc(friendUid)
                  .set({
                'uid': friendUid,
                'name': name,
                'email': email,
                'status': 'pending',
                'timestamp': FieldValue.serverTimestamp(),
                'workspaceName': 'FYP',
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invite sent to $name")));
            },
          ),
        );
      },
    );
  }

  void _showFullQR(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("WORKSPACE PORTAL", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 11, letterSpacing: 1.5)),
              const SizedBox(height: 24),
              QrImageView(
                data: code,
                version: QrVersions.auto,
                size: 220.0,
                foregroundColor: primaryNavy,
                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: primaryNavy),
                dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: primaryNavy),
              ),
              const SizedBox(height: 28),
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: bgBlue, borderRadius: BorderRadius.circular(16)), child: Text(code, style: TextStyle(letterSpacing: 6, fontWeight: FontWeight.w900, fontSize: 26, color: primaryNavy))),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("DONE", style: TextStyle(color: Colors.white)))),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, String id, String name, String desc) {
    final nC = TextEditingController(text: name);
    final dC = TextEditingController(text: desc);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Workspace"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: nC, decoration: const InputDecoration(labelText: "Name")), TextField(controller: dC, decoration: const InputDecoration(labelText: "Description"))]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), ElevatedButton(onPressed: () { FirebaseFirestore.instance.collection('workspaces').doc(id).update({'name': nC.text, 'description': dC.text}); Navigator.pop(context); }, child: const Text("Save"))],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Workspace?"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), TextButton(onPressed: () { FirebaseFirestore.instance.collection('workspaces').doc(id).update({'status': 'deleted', 'isDeleted': true}); Navigator.pop(context); Navigator.pop(context); }, child: const Text("Delete", style: TextStyle(color: Colors.red)))],
      ),
    );
  }

  Widget _statusBadge(bool active) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: active ? const Color(0xFFE3F2FD) : Colors.red[50],
              borderRadius: BorderRadius.circular(20)), child: Text(active ? "ACTIVE WORKSPACE" : "INACTIVE",
          style: TextStyle(color: active ? const Color(0xFF1976D2) : Colors.red,
              fontSize: 10, fontWeight: FontWeight.bold)));

  Widget _cardButton(IconData icon, String label, VoidCallback onTap) =>
      InkWell(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))])));

  Widget _priorityBadge(String p) =>
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFE0F7FA),
              borderRadius: BorderRadius.circular(8)), child: Text(p, style: const TextStyle(color: Color(0xFF00ACC1),
              fontSize: 9, fontWeight: FontWeight.bold)));
}