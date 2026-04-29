import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final Color primaryNavy = const Color(0xFF1A4789);
  final Color accentBlue = const Color(0xFF3B82F6);
  final Color bgLight = const Color(0xFFF1F5F9);
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("LOGIN ACTIVITY"),
                  _buildModernActivityLog(),
                  const SizedBox(height: 32),
                  _buildSectionHeader("ACCOUNT PRIVACY"),
                  _buildModernActionTile(
                    icon: Icons.lock_reset_rounded,
                    title: "Update Password",
                    subtitle: "Regularly change your password for safety",
                    onTap: _sendPasswordReset,
                  ),
                  _buildModernActionTile(
                    icon: Icons.no_accounts_rounded,
                    title: "Close Account",
                    subtitle: "Permanently delete your profile and data",
                    onTap: _showDeleteAccountDialog,
                    isDanger: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 70.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: primaryNavy,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          "Security Center",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryNavy, primaryNavy.withOpacity(0.8)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernActivityLog() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_activity')
            .where('userId', isEqualTo: _auth.currentUser?.uid)
            .orderBy('timestamp', descending: true)
            .limit(4)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Text("No recent activity found.", style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              bool isLogin = data['type'] == 'LOGIN';
              DateTime time = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              return IntrinsicHeight(
                child: Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isLogin ? Colors.green : Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [BoxShadow(color: (isLogin ? Colors.green : Colors.orange).withOpacity(0.3), blurRadius: 4)],
                          ),
                        ),
                        if (index != snapshot.data!.docs.length - 1)
                          Expanded(child: VerticalDivider(thickness: 1, color: Colors.grey[200])),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLogin ? "Log In" : "Log Out",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              DateFormat('MMM dd, yyyy • hh:mm a').format(time),
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildModernActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDanger ? Colors.red.withOpacity(0.1) : Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDanger ? Colors.red.withOpacity(0.1) : accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: isDanger ? Colors.red : accentBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDanger ? Colors.red : Colors.black87)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(color: primaryNavy, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2),
      ),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
  }

  void _sendPasswordReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.mail_outline, color: primaryNavy),
            const SizedBox(width: 10),
            const Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "We will send a password reset link to:\n${_auth.currentUser!.email}\n\nDo you want to proceed?",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _auth.sendPasswordResetEmail(email: _auth.currentUser!.email!);
                _showSnackBar("Reset link sent! Check your inbox.");
              } catch (e) {
                _showSnackBar("Error: Could not send reset email.");
              }
            },
            child: const Text("Send Email", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Delete Account", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "This will permanently erase your profile and account data. This action cannot be undone.",
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              try {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) return;

                String authUid = currentUser.uid;

                // 1. Find the document in the 'users' collection where the field 'uid' matches
                final userQuery = await FirebaseFirestore.instance
                    .collection('users')
                    .where('uid', isEqualTo: authUid)
                    .get();

                // 2. Delete the Firestore document(s) found
                if (userQuery.docs.isNotEmpty) {
                  for (var doc in userQuery.docs) {
                    await doc.reference.delete();
                  }
                }

                // 3. Delete the Auth User
                await currentUser.delete();

                // 4. Redirect to Login Page and clear navigation history
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', // Replace with your actual login route name
                        (route) => false,
                  );
                }
              } catch (e) {
                // Firebase requires a recent login for sensitive actions like account deletion
                _showSnackBar("Please log out and log back in to verify your identity before deleting.");
              }
            },
            child: const Text("Delete Forever", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

}