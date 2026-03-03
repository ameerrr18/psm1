import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_page/login_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const Color primaryNavy = Color(0xFF1A4789);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryNavy,
        title: const Text("Planova Dashboard", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              // 1. Sign out from Firebase
              await FirebaseAuth.instance.signOut();

              // 2. Clear auto-login preference
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('remember_me', false);

              // 3. Navigate back to Login and clear history
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.dashboard_rounded, size: 100, color: primaryNavy),
            const SizedBox(height: 20),
            Text(
              "Welcome,",
              style: TextStyle(fontSize: 22, color: Colors.grey[700]),
            ),
            Text(
              "${user?.email}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
            ),
          ],
        ),
      ),
    );
  }
}