import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;

class UploadPage extends StatefulWidget {
  final String? folderId;

  const UploadPage({super.key, this.folderId});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final Color primaryNavy = const Color(0xFF1A4789);
  bool _isUploading = false;
  double _progress = 0.0;

  Future<void> _uploadPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      await _startUpload(file, fileName);
    }
  }

  Future<void> _uploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File file = File(image.path);
      String fileName = p.basename(image.path);
      await _startUpload(file, fileName);
    }
  }

  Future<void> _startUpload(File file, String fileName) async {
    setState(() {
      _isUploading = true;
      _progress = 0.0;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('folders')
          .child(widget.folderId ?? 'general')
          .child(fileName);

      final uploadTask = storageRef.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (mounted) {
          setState(() {
            _progress = snapshot.bytesTransferred / snapshot.totalBytes;
          });
        }
      });

      // Wait for upload to finish completely
      await uploadTask.whenComplete(() => null);

      String downloadUrl = await storageRef.getDownloadURL();
      await _saveToFirestore(fileName, downloadUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Upload Successful!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveToFirestore(String fileName, String url) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection('documents').add({
      'folderId': widget.folderId,
      'fileName': fileName,
      'fileUrl': url,
      'fileType': p.extension(fileName).replaceFirst('.', '').toLowerCase(),
      'userId': uid,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Upload to Vault", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              "Choose a document type to add to your subject vault.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 40),
            _buildUploadCard(
              title: "PDF Document",
              subtitle: "Upload syllabus, notes, or assignments",
              icon: Icons.picture_as_pdf,
              onTap: _isUploading ? null : _uploadPdf,
            ),
            const SizedBox(height: 16),
            _buildUploadCard(
              title: "Image / Photo",
              subtitle: "Upload photos of lecture slides or whiteboards",
              icon: Icons.image,
              onTap: _isUploading ? null : _uploadImage,
            ),
            const Spacer(),
            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                color: primaryNavy,
                minHeight: 8,
              ),
              const SizedBox(height: 10),
              Text(
                "${(_progress * 100).toStringAsFixed(0)}% Uploading...",
                style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
          color: onTap == null ? Colors.grey.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryNavy.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryNavy, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline, color: primaryNavy),
          ],
        ),
      ),
    );
  }
}