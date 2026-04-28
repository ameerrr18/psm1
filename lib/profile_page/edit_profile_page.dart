import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final Color primaryNavy = const Color(0xFF1A4789);
  final Color accentBlue = const Color(0xFF3B82F6);
  final Color bgLight = const Color(0xFFF1F5F9);

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _profileImageUrl;
  File? _imageFile;
  bool _isLoading = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user!.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data();
        setState(() {
          _usernameController.text = data['username'] ?? "";
          _emailController.text = data['email'] ?? "";
          _profileImageUrl = data['profileImage'];
        });
      }
    } catch (e) {
      debugPrint("Error loading: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _saveProfile() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      String? imageUrl = _profileImageUrl;
      if (_imageFile != null) {
        final ref = FirebaseStorage.instance.ref().child('user_profiles').child('${user!.uid}.jpg');
        await ref.putFile(_imageFile!);
        imageUrl = await ref.getDownloadURL();
      }

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: user!.uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(querySnapshot.docs.first.id).update({
          'username': _usernameController.text.trim(),
          'profileImage': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated"), behavior: SnackBarBehavior.floating));
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primaryNavy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildImagePicker(),
            const SizedBox(height: 40),
            _buildModernField("Username", _usernameController, Icons.alternate_email_rounded),
            const SizedBox(height: 20),
            _buildModernField("Account Email", _emailController, Icons.email_rounded),
            const SizedBox(height: 50),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.white,
              backgroundImage: _imageFile != null
                  ? FileImage(_imageFile!)
                  : (_profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null) as ImageProvider?,
              child: (_imageFile == null && _profileImageUrl == null)
                  ? Icon(Icons.person_rounded, size: 50, color: primaryNavy.withOpacity(0.2))
                  : null,
            ),
          ),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentBlue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.camera_enhance_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernField(String label, TextEditingController controller, IconData icon, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: TextStyle(color: primaryNavy.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          style: TextStyle(fontWeight: FontWeight.w600, color: enabled ? Colors.black87 : Colors.grey),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: enabled ? accentBlue : Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: primaryNavy.withOpacity(0.4),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Apply Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}