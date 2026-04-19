import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WorkspaceDetailPage extends StatelessWidget {
  final String workspaceId;
  const WorkspaceDetailPage({super.key, required this.workspaceId});

  @override
  Widget build(BuildContext context) {
    final Color primaryNavy = const Color(0xFF1A4789);
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('workspaces').doc(workspaceId).snapshots(),
      builder: (context, snapshot) {
        // 🔥 Add this error check
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Workspace not found")));
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        bool isAdmin = data['adminId'] == currentUid;

        return Scaffold(
          appBar: AppBar(
            title: Text(data['name'], style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: () => _showQRDialog(context, data['inviteCode']),
              )
            ],
          ),
          body: Column(
            children: [
              if (isAdmin) _buildAdminRequests(workspaceId),
              Expanded(child: _buildTaskList(workspaceId)),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: primaryNavy,
            onPressed: () => _showAddTaskDialog(context, workspaceId),
            child: const Icon(Icons.add_task, color: Colors.white),
          ),
        );
      },
    );
  }

  // --- ADMIN APPROVAL SECTION ---
  Widget _buildAdminRequests(String id) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('workspaces').doc(id).collection('joinRequests').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox();
        return Container(
          color: Colors.orange.withOpacity(0.1),
          child: Column(
            children: snap.data!.docs.map((doc) {
              var d = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text("Request from: ${d['name']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _approveUser(id, d['uid'])),
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => doc.reference.delete()),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _approveUser(String wsId, String userUid) async {
    await FirebaseFirestore.instance.collection('workspaces').doc(wsId).update({
      'members': FieldValue.arrayUnion([userUid])
    });
    await FirebaseFirestore.instance.collection('workspaces').doc(wsId).collection('joinRequests').doc(userUid).delete();
  }

  // --- TASK LIST SECTION ---
  Widget _buildTaskList(String id) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('workspaces').doc(id).collection('tasks').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(
          children: snap.data!.docs.map((doc) => ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(doc['title']),
          )).toList(),
        );
      },
    );
  }

  // --- QR & DIALOGS ---
  void _showQRDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Workspace Invite QR"),
        content: SizedBox(
          width: 250,
          height: 250,
          child: Center(
            child: QrImageView(
              data: code, // The inviteCode string from Firestore
              version: QrVersions.auto,
              size: 200.0,
              gapless: false,
              // You can style it to match your Navy theme
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF1A4789),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: Color(0xFF1A4789),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, String wsId) {
    final tc = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("New Workspace Task"),
      content: TextField(controller: tc, decoration: const InputDecoration(hintText: "Task Name")),
      actions: [
        TextButton(onPressed: () async {
          await FirebaseFirestore.instance.collection('workspaces').doc(wsId).collection('tasks').add({
            'title': tc.text,
            'createdAt': FieldValue.serverTimestamp(),
          });
          Navigator.pop(context);
        }, child: const Text("Add"))
      ],
    ));
  }
}