import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          folderName,
          style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Center(
        child: Text(
          "Folder ID: $folderId",
          style: TextStyle(color: primaryNavy),
        ),
      ),
    );
  }
}