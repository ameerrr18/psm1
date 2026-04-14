import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddFolderPage extends StatefulWidget {
  const AddFolderPage({super.key});

  @override
  State<AddFolderPage> createState() => _AddFolderPageState();
}

class _AddFolderPageState extends State<AddFolderPage> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;

  String generateFolderId(String name) {
    String first = name.trim().split(" ").first.toLowerCase();
    int time = DateTime.now().millisecondsSinceEpoch;
    return "$first-$time";
  }

  Future<void> createFolder() async {
    if (_controller.text.isEmpty) return;

    setState(() => isLoading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    String id = generateFolderId(_controller.text);

    await FirebaseFirestore.instance
        .collection('folders')
        .doc(id)
        .set({
      'folderId': id,
      'userId': uid,
      'folderName': _controller.text.trim(),
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Folder")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Folder name",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : createFolder,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text("Create"),
            )
          ],
        ),
      ),
    );
  }
}