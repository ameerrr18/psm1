import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_workspace_page.dart';
import 'workspace_detail_page.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final TextEditingController _inviteController = TextEditingController();
  final Color primaryNavy = const Color(0xFF1A4789);
  final Color secondaryTeal = const Color(0xFF8DE1E1);
  final Color lightBg = const Color(0xFFF8FAFC);

  // Logic to Join via code
  Future<void> _joinWorkspace() async {
    String code = _inviteController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final String currentUid = user?.uid ?? '';

    var query = await FirebaseFirestore.instance
        .collection('workspaces')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      var workspaceDoc = query.docs.first;
      var data = workspaceDoc.data();

      // Check if already a member
      if ((data['members'] as List).contains(currentUid)) {
        _showSnack("You are already a member!");
        return;
      }

      // Create a Join Request
      await workspaceDoc.reference.collection('joinRequests').doc(currentUid).set({
        'uid': currentUid,
        'name': user?.displayName ?? "New User",
        'email': user?.email,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      _inviteController.clear();
      _showSnack("Request sent to Admin!");
    } else {
      _showSnack("Invalid Workspace Code");
    }
  }

  void _showSnack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Workspaces", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddWorkspacePage())),
            icon: CircleAvatar(backgroundColor: primaryNavy, child: const Icon(Icons.add, color: Colors.white, size: 20)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Join Section
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
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('workspaces')
                    .where('members', arrayContains: FirebaseAuth.instance.currentUser?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  // --- ADD THIS ERROR CHECK ---
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text("No workspaces found."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      return _buildWorkspaceCard(
                        context,
                        data['name'] ?? 'Unnamed',
                        data['description'] ?? '',
                        "${(data['members'] as List).length} MEMBERS",
                        data['inviteCode'] ?? '',
                        docs[index].id,
                      );
                    },
                  );
                },
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceCard(BuildContext context, String title, String desc, String members, String code,String workspaceId) {
    return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkspaceDetailPage(workspaceId: workspaceId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(25),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // (KEEP ALL YOUR EXISTING UI HERE — no change)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("CODE: $code", style: TextStyle(color: secondaryTeal, fontWeight: FontWeight.bold, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: secondaryTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  Icon(Icons.people_outline, size: 14, color: primaryNavy),
                  const SizedBox(width: 4),
                  Text(members, style: TextStyle(color: primaryNavy, fontSize: 10, fontWeight: FontWeight.bold)),
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
            child: CircleAvatar(radius: 18, backgroundColor: lightBg, child: Icon(Icons.arrow_forward_rounded, size: 18, color: primaryNavy)),
          ),
        ],
      ),
        ),
    );
  }
}