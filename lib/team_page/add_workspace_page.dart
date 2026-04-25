import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class AddWorkspacePage extends StatefulWidget {
  const AddWorkspacePage({super.key});

  @override
  State<AddWorkspacePage> createState() => _AddWorkspacePageState();
}

class _AddWorkspacePageState extends State<AddWorkspacePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final Color primaryNavy = const Color(0xFF1A4789);
  final Color bgColor = const Color(0xFFF5F6FB);

  bool _isLoading = false;
  final List<String> _selectedFriends = []; // Stores the long UIDs of selected friends
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  /// 🔥 GENERATE CUSTOM WORKSPACE ID
  String _generateWorkspaceId(String name) {
    String firstWord = name.trim().split(" ").first.toLowerCase();
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    return "$firstWord-$timestamp";
  }

  /// 🔥 GENERATE UNIQUE JOIN CODE (e.g., WORK-5921)
  String _generateJoinCode(String name) {
    String prefix = name.trim().split(" ").first.toUpperCase();
    if (prefix.length > 4) prefix = prefix.substring(0, 4);

    // Generate 4 random digits
    String randomDigits = (Random().nextInt(9000) + 1000).toString();
    return "$prefix-$randomDigits";
  }

  /// 🔥 CREATE WORKSPACE LOGIC
  Future<void> _createWorkspace() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a workspace name")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String workspaceId = _generateWorkspaceId(_nameController.text.trim());
      String joinCode = _generateJoinCode(_nameController.text.trim());
      String name = _nameController.text.toUpperCase();

      // Combine the creator and selected friends into the members array
      List<String> allMembers = [currentUid, ..._selectedFriends];

      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .set({
        'workspaceId': workspaceId,
        'joinCode': joinCode,
        'name': name,
        'description': _descController.text.trim(),
        'qr_code': workspaceId,
        'status': 'active',
        'createdBy': currentUid,
        'adminId': currentUid,
        'admins': [currentUid],
        'members': allMembers,
        'pendingRequests': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "New Workspace",
          style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _label("WORKSPACE NAME"),
            const SizedBox(height: 8),
            _inputField(
              controller: _nameController,
              hint: "e.g., Marketing Campaign 2026",
            ),

            const SizedBox(height: 20),
            _label("DESCRIPTION"),
            const SizedBox(height: 8),
            _inputField(
              controller: _descController,
              hint: "What is this group working on?",
              maxLines: 2,
            ),

            const SizedBox(height: 20),
            _label("SELECT FRIENDS TO ADD"),
            const SizedBox(height: 8),

            /// 🔥 FRIEND SELECTOR LIST
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: _buildFriendPicker(),
              ),
            ),

            const SizedBox(height: 20),

            /// CREATE BUTTON
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createWorkspace,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Create Workspace",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white)
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 🔥 FETCH AND DISPLAY FRIENDS
  Widget _buildFriendPicker() {
    return StreamBuilder<QuerySnapshot>(
      // Get the current user's document to find their 'friends' list
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: currentUid)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("User profile not found"));

        var userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        List friendsUids = userData['friends'] ?? [];

        if (friendsUids.isEmpty) {
          return const Center(
            child: Text("No friends yet.\nAdd friends in Profile first!", textAlign: TextAlign.center),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: friendsUids.length,
          itemBuilder: (context, index) {
            String friendUid = friendsUids[index];

            // Use FutureBuilder to get friend details by their internal 'uid' field
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('uid', isEqualTo: friendUid)
                  .limit(1)
                  .get(),
              builder: (context, friendSnap) {
                if (!friendSnap.hasData || friendSnap.data!.docs.isEmpty) return const SizedBox();

                var fData = friendSnap.data!.docs.first.data() as Map<String, dynamic>;
                String name = fData['username'] ?? "Unknown";
                String email = fData['email'] ?? "";
                bool isSelected = _selectedFriends.contains(friendUid);

                return CheckboxListTile(
                  title: Text(name, style: TextStyle(color: primaryNavy, fontWeight: FontWeight.w600)),
                  subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                  value: isSelected,
                  activeColor: primaryNavy,
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedFriends.add(friendUid);
                      } else {
                        _selectedFriends.remove(friendUid);
                      }
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey[600],
        letterSpacing: 1,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }
}