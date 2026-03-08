import 'package:flutter/material.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  final Color primaryNavy = const Color(0xFF1A4789);
  final Color secondaryTeal = const Color(0xFF8DE1E1);
  final Color lightBg = const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Workspaces",
          style: TextStyle(
              color: primaryNavy,
              fontSize: 24,
              fontWeight: FontWeight.bold
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: primaryNavy,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Search/Invite Section ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: lightBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        icon: Icon(Icons.tag, size: 18, color: Colors.grey),
                        hintText: "Enter invite code...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryTeal,
                    foregroundColor: primaryNavy,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  ),
                  child: const Text("Join", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // --- Workspace Cards List ---
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
                children: [
                  _buildWorkspaceCard(
                    context,
                    "Database Design",
                    "Normalization, query optimization, and architectural patterns for distributed databases.",
                    "3 MEMBERS",
                    Icons.grid_view_rounded,
                  ),
                  _buildWorkspaceCard(
                    context,
                    "FYP",
                    "Final Year Project - Building an intelligent autonomous agent for academic task management.",
                    "3 MEMBERS",
                    Icons.grid_view_rounded,
                  ),
                  _buildWorkspaceCard(
                    context,
                    "AI",
                    "Neural networks, search algorithms, and the fundamentals of generative models.",
                    "2 MEMBERS",
                    Icons.grid_view_rounded,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceCard(BuildContext context, String title, String desc, String members, IconData icon) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: secondaryTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_outline, size: 14, color: primaryNavy),
                    const SizedBox(width: 4),
                    Text(
                      members,
                      style: TextStyle(
                          color: primaryNavy,
                          fontSize: 10,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
                color: primaryNavy,
                fontSize: 18,
                fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 15),
          const Divider(color: Color(0xFFF1F4F8)),
          Align(
            alignment: Alignment.centerRight,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: lightBg,
              child: Icon(Icons.arrow_forward_rounded, size: 18, color: primaryNavy),
            ),
          ),
        ],
      ),
    );
  }
}