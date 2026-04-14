import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// 🔥 GENERATE CUSTOM WORKSPACE ID
  String _generateWorkspaceId(String name) {
    String firstWord = name.trim().split(" ").first.toLowerCase();
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    return "$firstWord-$timestamp";
  }

  Future<void> _createWorkspace() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;

    try {
      String workspaceId =
      _generateWorkspaceId(_nameController.text.trim());

      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .set({
        'workspaceId': workspaceId,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'qr_code': workspaceId, // simple placeholder (can generate real QR later)
        'status': 'active',
        'createdBy': user?.uid,
        'members': [user?.uid],
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
          style: TextStyle(
            color: primaryNavy,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const SizedBox(height: 20),

            /// WORKSPACE NAME
            _label("WORKSPACE NAME"),
            const SizedBox(height: 8),
            _inputField(
              controller: _nameController,
              hint: "e.g., Marketing Campaign 2024",
            ),

            const SizedBox(height: 20),

            /// DESCRIPTION
            _label("DESCRIPTION"),
            const SizedBox(height: 8),
            _inputField(
              controller: _descController,
              hint: "What is this group working on?",
              maxLines: 4,
            ),

            const Spacer(),

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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_ios, size: 16)
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// FOOTER TEXT
            Center(
              child: Text(
                "PROJECTS, MEMBERS & TASKS IN ONE PLACE",
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// LABEL
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

  /// INPUT FIELD
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
          border: InputBorder.none,
        ),
      ),
    );
  }
}