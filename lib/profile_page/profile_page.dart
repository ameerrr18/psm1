import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:planova/profile_page/security_page.dart';
import 'package:planova/profile_page/task_history_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_page/login_page.dart';
import 'edit_profile_page.dart';
import 'library_history_page.dart';
import 'friends_page.dart';
import 'dart:ui';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color primaryNavy = const Color(0xFF1A4789);
  final Color lightBg = const Color(0xFFF8FAFC);
  bool isDarkMode = false;

  String? _profileImageUrl;
  String _username = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// 📥 FETCH DYNAMIC DATA
  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Searching by the 'uid' field inside the document to handle custom doc IDs
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data();
        setState(() {
          _username = data['username'] ?? "User";
          _profileImageUrl = data['profileImage']; // This maps to your DB field
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  /// 🚪 FIXED LOGOUT LOGIC
  Future<void> _handleLogout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // 1. Perform Firestore updates FIRST while user is still authed
        await FirebaseFirestore.instance
            .collection('user_activity')
            .add({
          'userId': user.uid,
          'type': 'LOGOUT',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // 2. Clear local session data (Remember Me)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', false);

      // 3. Perform the actual Firebase Sign Out
      await FirebaseAuth.instance.signOut();

      // 4. Navigate back to Login
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging out: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Profile", style: TextStyle(color: primaryNavy, fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: Icon(Icons.edit_outlined, color: primaryNavy),
              onPressed: () async {
                // Refresh data when returning from Edit Profile
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
                _loadUserProfile();
              }
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            _buildUserInfo(_username, user?.email ?? "No Email Found"),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
              ),
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel("APP APPEARANCE"),
                  _buildDarkModeToggle(),

                  const SizedBox(height: 30),
                  _sectionLabel("SETTINGS & SECURITY"),

                  _buildSettingTile(
                      Icons.people_alt_outlined,
                      "Friends & Social",
                      const Color(0xFF8DE1E1),
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsPage()))
                  ),

                  _buildSettingTile(
                      Icons.shield_outlined,
                      "Security & Privacy",
                      Colors.green,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityPage()))
                  ),

                  _buildSettingTile(
                      Icons.history_rounded,
                      "Library History",
                      Colors.orange,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LibraryHistoryPage()))
                  ),

                  _buildSettingTile(
                      Icons.restore_rounded,
                      "Task History",
                      Colors.purple,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskHistoryPage()))
                  ),

                  const SizedBox(height: 40),
                  _buildLogoutAction(),

                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      "PLANOVA AI VERSION 1.0.0",
                      style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(String name, String email) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: primaryNavy.withOpacity(0.1),
                // ✅ UPDATED IMAGE LOGIC
                backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                    ? NetworkImage(_profileImageUrl!)
                    : null,
                child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                    ? Icon(Icons.person, size: 40, color: primaryNavy)
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFF8DE1E1), shape: BoxShape.circle),
                  child: Icon(Icons.psychology_outlined, size: 18, color: primaryNavy),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(color: primaryNavy, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: primaryNavy.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text("PREMIUM SCHOLAR", style: TextStyle(color: primaryNavy, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 15),
      child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
    );
  }

  Widget _buildDarkModeToggle() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.wb_sunny_outlined, color: Colors.orange),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dark Mode", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
                const Text("Adjust display settings", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: isDarkMode,
            onChanged: (val) => setState(() => isDarkMode = val),
            activeColor: primaryNavy,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 15),
              Expanded(child: Text(title, style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold))),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutAction() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ElevatedButton(
        // ✅ FIX: The button now triggers the confirmation dialog, NOT the logout directly
        onPressed: () => _showLogoutConfirmation(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.red.withOpacity(0.2)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, size: 22),
            SizedBox(width: 12),
            Text(
              "Log Out",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white, // Prevents Material 3 tinting
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Log Out",
                  style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A4789)),
                ),
              ],
            ),
            content: const Text(
              "Are you sure you want to log out? You'll need to enter your credentials to get back in.",
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  // ✅ This is where the actual logout logic happens
                  onPressed: () {
                    Navigator.pop(context);
                    _handleLogout();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}