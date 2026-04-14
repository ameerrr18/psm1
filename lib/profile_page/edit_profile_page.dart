import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final Color primaryNavy = const Color(0xFF1A4789);

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String role = "user";
  bool isLoading = false;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// 🔥 LOAD USER DATA
  Future<void> _loadUserData() async {
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid) // IMPORTANT: docId must be uid
        .get();

    if (doc.exists) {
      var data = doc.data()!;

      _usernameController.text = data['username'] ?? "";
      _emailController.text = data['email'] ?? user!.email ?? "";
      role = data['role'] ?? "user";

      setState(() {});
    }
  }

  /// 🔥 RE-AUTHENTICATION (REQUIRED FOR EMAIL CHANGE)
  Future<void> _reauthenticateUser() async {
    String password = "";

    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController passController = TextEditingController();

        return AlertDialog(
          title: const Text("Re-authentication Required"),
          content: TextField(
            controller: passController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Enter your password",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                password = passController.text;
                Navigator.pop(context);
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );

    if (password.isEmpty) {
      throw Exception("Password required");
    }

    AuthCredential credential = EmailAuthProvider.credential(
      email: user!.email!,
      password: password,
    );

    await user!.reauthenticateWithCredential(credential);
  }

  /// 🔥 UPDATE PROFILE
  Future<void> _updateProfile() async {
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      /// ✅ EMAIL CHANGE (FIXED)
      if (_emailController.text.trim() != user!.email) {
        await _reauthenticateUser();

        await user!.verifyBeforeUpdateEmail(
          _emailController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Verification email sent. Please verify before email updates."),
          ),
        );
      }

      /// ✅ UPDATE FIRESTORE
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'username': _usernameController.text.trim(),
        'email': user!.email, // ALWAYS SYNC FROM AUTH
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      /// APPBAR
      appBar: AppBar(
        title: Text("Edit Profile",
            style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      /// BODY
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            /// USERNAME
            _buildInput("Username", _usernameController, Icons.person),

            const SizedBox(height: 20),

            /// EMAIL
            _buildInput("Email", _emailController, Icons.email),

            const SizedBox(height: 20),

            /// ROLE
            _buildRoleDropdown(),

            const Spacer(),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Save Changes",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// 🔹 INPUT FIELD
  Widget _buildInput(
      String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: primaryNavy.withOpacity(0.6),
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: primaryNavy),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  /// 🔹 ROLE DROPDOWN
  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Role",
            style: TextStyle(
                color: primaryNavy.withOpacity(0.6),
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButton<String>(
            value: role,
            isExpanded: true,
            underline: const SizedBox(),
            items: ["user", "admin"]
                .map((e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            ))
                .toList(),
            onChanged: (value) {
              setState(() => role = value!);
            },
          ),
        ),
      ],
    );
  }
}