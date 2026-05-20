import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // 👈 ADD THIS IMPORT

class ScanQrPage extends StatefulWidget {
  final String? initialCode;

  const ScanQrPage({super.key, this.initialCode});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  bool isScanning = true;
  final MobileScannerController controller = MobileScannerController();
  final ImagePicker _imagePicker = ImagePicker(); // 👈 Initialize picker

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleQrResult(widget.initialCode!);
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// 🖼️ NEW FUNCTION: Pick an image from gallery and extract the QR code data
  Future<void> _importQrFromGallery() async {
    try {
      // 1. Stop the live camera engine stream BEFORE opening the system sheet
      await controller.stop();
      setState(() => isScanning = false);

      // 2. Pick the image AND downscale it slightly to optimize ML Kit recognition speed
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,  // Restricting excessive resolution prevents engine timeouts
        maxHeight: 1024,
      );

      // If the user cancelled, restart the camera stream smoothly
      if (pickedFile == null) {
        await controller.start();
        setState(() => isScanning = true);
        return;
      }

      // 3. Let ML Kit analyze the static file path matrix
      final BarcodeCapture? capture = await controller.analyzeImage(pickedFile.path);

      if (capture != null && capture.barcodes.isNotEmpty) {
        final String? rawValue = capture.barcodes.first.rawValue;
        if (rawValue != null && rawValue.isNotEmpty) {
          debugPrint("🚀 QR Code extracted successfully: $rawValue");

          // Force scanning true flag state right before handling so validation conditions pass
          setState(() => isScanning = true);
          _handleQrResult(rawValue);
          return; // Exit execution block completely on success
        }
      }

      // 4. Fallback: If nothing was found, alert user and restart the live camera feed
      _showSimpleDialog("No QR Code Found", "We couldn't detect a valid workspace link or code in that picture.");
      await controller.start();
      setState(() => isScanning = true);

    } catch (e) {
      debugPrint("Error parsing gallery file: $e");
      _showSimpleDialog("Error", "Failed processing image asset: $e");

      // Safe recovery fallback loop
      try { await controller.start(); } catch(_) {}
      setState(() => isScanning = true);
    }
  }

  Future<void> _handleQrResult(String code) async {
    if (!isScanning) return;
    setState(() => isScanning = false);

    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      var query = await FirebaseFirestore.instance
          .collection('workspaces')
          .where('joinCode', isEqualTo: code.trim().toUpperCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        var workspaceDoc = query.docs.first;
        var data = workspaceDoc.data();
        String workspaceName = data['name'] ?? "Unnamed Workspace";
        String description = data['description'] ?? "No description provided.";

        if ((data['members'] as List).contains(currentUid)) {
          _showSimpleDialog("Already a Member", "You are already in $workspaceName.");
          return;
        }

        _showConfirmJoinDialog(
          workspaceName: workspaceName,
          description: description,
          onConfirm: () => _performAutoJoin(workspaceDoc.reference, workspaceName),
        );
      } else {
        _showSimpleDialog("Invalid Code", "This QR code does not match any workspace.");
      }
    } catch (e) {
      _showSimpleDialog("Error", "Something went wrong: $e");
    }
  }

  Future<void> _performAutoJoin(DocumentReference ref, String name) async {
    final user = FirebaseAuth.instance.currentUser;
    final String currentUid = user?.uid ?? '';

    try {
      await ref.collection('joinRequests').doc(currentUid).set({
        'uid': currentUid,
        'name': user?.displayName ?? "New User",
        'email': user?.email,
        'status': 'pending',
        'workspaceName': name,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Request sent for $name!"))
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showSimpleDialog("Request Failed", "Could not send join request: $e");
    }
  }

  void _showConfirmJoinDialog({
    required String workspaceName,
    required String description,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Join Workspace?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workspaceName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isScanning = true);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A4789)),
            child: const Text("Join Now", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSimpleDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (title == "Welcome!") {
                Navigator.pop(context);
              } else {
                setState(() => isScanning = true);
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan to Join"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // 🛠️ ADD GALLERY ENTRY BUTTON TO APP BAR
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_rounded),
            tooltip: "Import from Gallery",
            onPressed: _importQrFromGallery,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQrResult(barcode.rawValue!);
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}