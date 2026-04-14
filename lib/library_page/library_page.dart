import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_folder_page.dart';
import 'folder_detail_page.dart';
import 'upload_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  final Color primaryNavy = const Color(0xFF1A4789);
  final Color secondaryTeal = const Color(0xFF8DE1E1);
  final Color lightBg = const Color(0xFFF8FAFC);

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
          /// ➕ ADD FOLDER
          Container(
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: lightBg,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: IconButton(
              icon: Icon(Icons.add, color: primaryNavy),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddFolderPage()),
                );
              },
            ),
          ),

          /// 📤 UPLOAD
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadPage()),
                );
              },
              icon: const Icon(Icons.file_upload_outlined, size: 18),
              label: const Text("Upload"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [

          /// SEARCH
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: lightBg,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Search folders...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          /// FOLDER LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('folders')
                  .where('userId', isEqualTo: uid)
                  .where('status', isEqualTo: 'active')
                  .snapshots(),

              builder: (context, snapshot) {

                /// 🔴 SHOW ERROR
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                /// ⏳ LOADING
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                /// 📭 EMPTY
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyVaultState();
                }

                /// ✅ DATA
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                    return _buildFolderItem(context, data);
                  },
                );
              },
            )
          ),
        ],
      ),
    );
  }

  Widget _buildFolderItem(BuildContext context, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FolderDetailPage(
              folderId: data['folderId'],
              folderName: data['folderName'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade100),
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
              child: Text(
                data['folderName'] ?? "",
                style: TextStyle(
                  color: primaryNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyVaultState() {
    return Center(
      child: Text("Vault is Empty",
          style: TextStyle(
              color: primaryNavy,
              fontWeight: FontWeight.bold)),
    );
  }
}