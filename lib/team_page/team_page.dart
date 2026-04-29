import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'add_workspace_page.dart';
import 'workspace_detail_page.dart';
import 'scan_qr_page.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _TeamPageState extends State<TeamPage> {
  final TextEditingController _inviteController = TextEditingController();
  final Color primaryNavy = const Color(0xFF1A4789);
  final Color secondaryTeal = const Color(0xFF8DE1E1);
  final Color lightBg = const Color(0xFFF8FAFC);

  void _showSnack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  // 🔥 UPDATED JOIN LOGIC
  Future<void> _joinWorkspace() async {
    String code = _inviteController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final String currentUid = user?.uid ?? '';

    var query = await FirebaseFirestore.instance
        .collection('workspaces')
        .where('joinCode', isEqualTo: code) // Consistently use joinCode
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      var workspaceDoc = query.docs.first;
      var data = workspaceDoc.data();

      if ((data['members'] as List).contains(currentUid)) {
        _showSnack("You are already a member!");
        return;
      }

      var existingRequest = await workspaceDoc.reference
          .collection('joinRequests')
          .doc(currentUid)
          .get();

      if (existingRequest.exists) {
        _showSnack("Request already pending approval.");
        return;
      }

      await workspaceDoc.reference.collection('joinRequests').doc(currentUid).set({
        'uid': currentUid,
        'name': user?.displayName ?? "New User",
        'email': user?.email,
        'status': 'pending',
        'workspaceName': data['name'], // Store name to show in pending list
        'joinCode': code,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _inviteController.clear();
      FocusScope.of(context).unfocus();
      _showSnack("Request sent to Admin!");
    } else {
      _showSnack("Invalid Workspace Code");
    }
  }


  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // 🔥 COMBINED STREAMS: Memberships + Pending Requests
    Stream<List<Map<String, dynamic>>> combinedStream = CombineLatestStream.list([
      // Stream 1: Workspaces where user is a member
      FirebaseFirestore.instance
          .collection('workspaces')
          .where('members', arrayContains: currentUid)
          .snapshots()
          .map((snap) => snap.docs.map((doc) => {...doc.data(), 'id': doc.id, 'isPending': false}).toList()),

      FirebaseFirestore.instance
          .collectionGroup('joinRequests') // 🔥 Fixed: added .instance and changed name to collectionGroup
          .where('uid', isEqualTo: currentUid)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snap) => snap.docs.map((doc) => {
        'name': doc.data()['workspaceName'] ?? 'Pending...',
        'joinCode': doc.data()['joinCode'] ?? '',
        'id': doc.reference.parent.parent?.id ?? '', // Gets Workspace ID
        'isPending': true,
        'description': 'Waiting for admin approval...',
        'members': []
      }).toList()),
    ]).map((lists) => [...lists[0], ...lists[1]]);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Workspaces", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanQrPage()),
              );
            },
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddWorkspacePage())),
            icon: CircleAvatar(backgroundColor: primaryNavy, child: const Icon(Icons.add, color: Colors.white, size: 20)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      controller: _inviteController,
                      // Add these two lines:
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [UpperCaseTextFormatter()],
                      decoration: const InputDecoration(
                        icon: Icon(Icons.tag, size: 18, color: Colors.grey),
                        hintText: "Enter invite code...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _joinWorkspace,
                  style: ElevatedButton.styleFrom(backgroundColor: secondaryTeal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text("Join", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: lightBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(35))),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: combinedStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  var workspaces = snapshot.data ?? [];
                  if (workspaces.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_outlined, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            "No workspaces found",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Create a new workspace to get started!",
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
                    itemCount: workspaces.length,
                    itemBuilder: (context, index) {
                      var data = workspaces[index];
                      return _buildWorkspaceCard(
                        context,
                        data['name'] ?? 'Unnamed',
                        data['description'] ?? '',
                        "${(data['members'] as List? ?? []).length} MEMBERS",
                        data['joinCode'] ?? data['inviteCode'] ?? '',
                        data['id'],
                        data['isPending'] ?? false,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceCard(BuildContext context, String title, String desc, String members, String code, String workspaceId, bool isPending) {
    return InkWell(
      onTap: isPending
          ? () => _showSnack("Still waiting for admin approval...")
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WorkspaceDetailPage(workspaceId: workspaceId)),
        );
      },
      borderRadius: BorderRadius.circular(25),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPending ? Colors.white.withOpacity(0.6) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("CODE: $code", style: TextStyle(color: secondaryTeal, fontWeight: FontWeight.bold, fontSize: 12)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: isPending ? Colors.orange.withOpacity(0.1) : secondaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child: Row(children: [
                    Icon(isPending ? Icons.hourglass_empty : Icons.people_outline, size: 14, color: isPending ? Colors.orange : primaryNavy),
                    const SizedBox(width: 4),
                    Text(
                        isPending ? "PENDING" : members,
                        style: TextStyle(color: isPending ? Colors.orange : primaryNavy, fontSize: 10, fontWeight: FontWeight.bold)
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(title, style: TextStyle(color: primaryNavy, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
            const SizedBox(height: 15),
            const Divider(color: Color(0xFFF1F4F8)),
            Align(
              alignment: Alignment.centerRight,
              child: CircleAvatar(
                  radius: 18,
                  backgroundColor: lightBg,
                  child: Icon(
                      isPending ? Icons.lock_clock : Icons.arrow_forward_rounded,
                      size: 18,
                      color: isPending ? Colors.grey : primaryNavy
                  )
              ),
            ),
          ],
        ),
      ),
    );
  }
}