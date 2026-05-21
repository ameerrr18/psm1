import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'upload_page.dart';
import 'scan_pdf_page.dart';
import 'in_app_viewer_page.dart';

class FolderDetailPage extends StatelessWidget {
  final String folderId;
  final String folderName;

  const FolderDetailPage({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  final Color primaryNavy = const Color(0xFF1A4789);
  final Color lightBg = const Color(0xFFF8FAFC);

  /// 📥 SHOW UPLOAD SELECTION MENU
  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text(
                "Add Document",
                style: TextStyle(color: primaryNavy, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 25),
              _buildOptionTile(
                icon: Icons.file_copy_rounded,
                title: "Upload Files",
                subtitle: "Select an existing document from storage",
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UploadPage(folderId: folderId)),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildOptionTile(
                icon: Icons.document_scanner_rounded,
                title: "Scan to PDF",
                subtitle: "Use camera to capture and convert to PDF",
                onTap: () {
                  Navigator.pop(context); // Dismiss the sheet overlay
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // 🔑 PASS THE CURRENT FOLDER ID TO THE SCANNER PAGE HERE
                      builder: (context) => ScanPdfPage(folderId: folderId),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Icon(icon, color: primaryNavy, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(folderName.toUpperCase(), style: TextStyle(color: primaryNavy, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("SUBJECT VAULT", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () => _showUploadOptions(context),
              icon: const Icon(Icons.upload_sharp, size: 16),
              label: const Text("Upload", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
              child: TextField(
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  hintText: "Search in ${folderName.toUpperCase()}...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDF2F7)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('documents')
                  .where('folderId', isEqualTo: folderId)
                  .orderBy('uploadedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SingleChildScrollView(child: _buildEmptyVaultState());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return _buildFileItem(context, data); // Passed context here
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(BuildContext context, Map<String, dynamic> data) {
    bool isPdf = data['fileType'] == 'pdf';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: lightBg, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(isPdf ? Icons.picture_as_pdf : Icons.image, color: primaryNavy),
        title: Text(data['fileName'] ?? "Untitled", style: TextStyle(fontWeight: FontWeight.bold, color: primaryNavy)),
        subtitle: const Text("Tap to view document", style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.more_vert, size: 20),
        onTap: () {
          if (data['fileUrl'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InAppViewerPage(
                  fileUrl: data['fileUrl'],
                  fileName: data['fileName'] ?? "Untitled Document",
                  isPdf: data['fileType'] == 'pdf',
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Error: File link not found")),
            );
          }
        },
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open file viewer")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Widget _buildEmptyVaultState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFD1E3F8).withOpacity(0.5), width: 2)),
              child: const Icon(Icons.file_copy_outlined, size: 50, color: Color(0xFFD1E3F8)),
            ),
            const SizedBox(height: 30),
            Text("Vault is Empty", style: TextStyle(color: primaryNavy, fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 15),
            Text("Upload your syllabus or lecture notes.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}