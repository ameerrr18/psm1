import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ScanQrPage extends StatefulWidget {
  const ScanQrPage({super.key});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  bool isScanning = true;
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleQrResult(String code) async {
    if (!isScanning) return;
    setState(() => isScanning = false);

    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      // 1. Find the workspace
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

        // 2. Check if already a member
        if ((data['members'] as List).contains(currentUid)) {
          _showSimpleDialog("Already a Member", "You are already in $workspaceName.");
          return;
        }

        // 3. Show Details & Confirm Auto-Join
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

  // 🔥 DIRECT JOIN LOGIC (No Admin Approval Needed)
  Future<void> _performAutoJoin(DocumentReference ref, String name) async {
    final user = FirebaseAuth.instance.currentUser;
    final String currentUid = user?.uid ?? '';

    try {
      // 1. Create the request in the sub-collection (Matches your security rules)
      await ref.collection('joinRequests').doc(currentUid).set({
        'uid': currentUid,
        'name': user?.displayName ?? "New User",
        'email': user?.email,
        'status': 'pending',
        'workspaceName': name,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        // 2. Close the Confirmation Dialog
        Navigator.pop(context);

        // 3. Show success snackbar on the Team Page instead of a blocking Dialog
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Request sent for $name!"))
        );

        // 4. 🔥 GO BACK TO team_page.dart
        // This pops the ScanQrPage and returns to the previous screen
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
        title: Text("Join Workspace?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workspaceName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(description, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => isScanning = true); // Resume scanning
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
              Navigator.pop(context); // Close dialog
              if (title == "Welcome!") {
                Navigator.pop(context); // Exit scan page to Team page
              } else {
                setState(() => isScanning = true); // Resume scanning
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
          // Visual scanning frame
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