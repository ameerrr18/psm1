import 'package:flutter/material.dart';

class LibraryHistoryPage extends StatelessWidget {
  const LibraryHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LibraryHistoryPage", style: TextStyle(color: Color(0xFF1A4789))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A4789)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(child: Text("LibraryHistoryPage Settings coming soon!")),
    );
  }
}