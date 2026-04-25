import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'folder_detail_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final Color primaryNavy = const Color(0xFF1A4789);
  final Color lightBg = const Color(0xFFF4F7FA);
  final Color accentBlue = const Color(0xFF2B5896);

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _folderNameController = TextEditingController(); // For popup
  String _searchQuery = "";

  /// 🛠️ SHOW CREATE FOLDER POPUP
  void _showCreateFolderDialog(BuildContext context) {
    // Controller to capture the folder name inside the popup
    final TextEditingController _folderController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Wrap content height
              children: [
                // Top Close Button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.grey, size: 20),
                  ),
                ),

                // Title
                Text(
                  "Create Folder",
                  style: TextStyle(
                    color: Color(0xFF1A4789), // Your primaryNavy
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Organize your academic materials by subject or project.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 25),

                // Input Field
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF1A4789).withOpacity(0.5)),
                  ),
                  child: TextField(
                    controller: _folderController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters, // Mimics your DB look
                    decoration: const InputDecoration(
                      hintText: "e.g., DATABASE DESIGN",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _handleCreateFolder(_folderController.text, context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B5896), // Your accentBlue
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Create Subject Vault",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String generateFolderId(String name) {
    String first = name.trim().split(" ").first.toLowerCase();
    int time = DateTime.now().millisecondsSinceEpoch;
    return "$first-$time";
  }

  /// 💾 Updated Creation Logic using Custom ID
  Future<void> _handleCreateFolder(String name, BuildContext context) async {
    String folderName = name.trim();
    if (folderName.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 1. Generate the ID based on your specific logic
    String customId = generateFolderId(folderName);

    try {
      // 2. Use .doc(customId) to set the document name manually
      await FirebaseFirestore.instance.collection('folders').doc(customId).set({
        'folderId': customId,
        'userId': uid,
        'folderName': folderName.toUpperCase(), // Keeps the "SUBJECT" look
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context); // Close the popup
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject Vault Created!")),
      );
    } catch (e) {
      debugPrint("Error creating folder: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Library",
                style: TextStyle(color: primaryNavy, fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("ACADEMIC VAULT",
                style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateFolderDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("New Folder", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          /// SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  hintText: "Search folders...",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('folders')
                  .where('userId', isEqualTo: uid)
                  .where('status', isEqualTo: 'active')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final filteredDocs = snapshot.data?.docs.where((doc) {
                  final name = (doc.data() as Map<String, dynamic>)['folderName']?.toString().toLowerCase() ?? "";
                  return name.contains(_searchQuery);
                }).toList() ?? [];

                if (filteredDocs.isEmpty) return _buildEmptyVaultState();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    const Text("SUBJECT FOLDERS", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 15),
                    ...filteredDocs.map((doc) => _buildFolderItem(context, doc.data() as Map<String, dynamic>)).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FolderDetailPage(folderId: data['folderId'], folderName: data['folderName']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.folder_outlined, color: primaryNavy, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((data['folderName'] ?? "").toUpperCase(),
                      style: TextStyle(color: primaryNavy, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  const Text("0 DOCUMENTS", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyVaultState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined, size: 100, color: Color(0xFFD1E3F8)),
            const SizedBox(height: 30),
            Text("Library is Empty", style: TextStyle(color: primaryNavy, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}