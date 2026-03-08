import 'package:flutter/material.dart';

class LibraryPage extends StatelessWidget {
  final VoidCallback? onBack;
  const LibraryPage({super.key, this.onBack});

  // Colors based on your established design system
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Library",
                style: TextStyle(
                    color: primaryNavy,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const Text("ACADEMIC VAULT",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1)),
          ],
        ),
        actions: [
          // Plus Button
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: lightBg,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: primaryNavy, size: 20),
              onPressed: () {},
            ),
          ),
          // Upload Button
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_upload_outlined, size: 18),
              label: const Text("Upload"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                foregroundColor: Colors.white,
                elevation: 5,
                shadowColor: primaryNavy.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Search folders & documents...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
          ),

          // --- Content List ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              children: [
                _sectionLabel("SUBJECT FOLDERS"),
                _buildFolderItem("SYLLABUS & SCHEDULES", "1 DOCUMENTS"),
                _buildFolderItem("MOBILE LAB REPORTS", "0 DOCUMENTS"),
                _buildFolderItem("AI MODEL SPECS", "1 DOCUMENTS"),
                _buildFolderItem("HCI DESIGN ASSETS", "0 DOCUMENTS"),

                const SizedBox(height: 30),
                _sectionLabel("GENERAL DOCUMENTS"),

                // --- Empty State (From image_9d4037.png) ---
                _buildEmptyVaultState(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(text,
          style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1)),
    );
  }

  Widget _buildFolderItem(String title, String count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightBg,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.folder_outlined, color: primaryNavy),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: primaryNavy,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text(count,
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 5),
          Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyVaultState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        // Dashed circle icon
        Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: secondaryTeal.withOpacity(0.5),
              style: BorderStyle.solid, // Flutter doesn't native dash, but solid looks close here
              width: 1.5,
            ),
            color: secondaryTeal.withOpacity(0.05),
          ),
          child: Icon(Icons.content_paste_search_rounded,
              size: 40, color: secondaryTeal),
        ),
        const SizedBox(height: 25),
        Text("Vault is Empty",
            style: TextStyle(
                color: primaryNavy, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Upload your syllabus or lecture notes. Planova will extract the intelligence and link it to your schedule.",
            textAlign: TextAlign.center,
            style: TextStyle(color: primaryNavy.withOpacity(0.6), fontSize: 12, height: 1.5),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}