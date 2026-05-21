import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Handles extracting current dynamic userId

class ScanPdfPage extends StatefulWidget {
  final String folderId; // 🔑 Passed directly to target the correct workspace vault folder

  const ScanPdfPage({super.key, required this.folderId});

  @override
  State<ScanPdfPage> createState() => _ScanPdfPageState();
}

class _ScanPdfPageState extends State<ScanPdfPage> {
  final Color primaryNavy = const Color(0xFF1A4789);

  bool _isProcessing = false;
  List<String> _scannedImagePaths = [];
  String _extractedOcrText = "";

  Future<void> _startDocumentScan() async {
    setState(() { _isProcessing = true; });
    try {
      List<String>? pictures = await CunningDocumentScanner.getPictures();
      if (pictures != null && pictures.isNotEmpty) {
        setState(() {
          _scannedImagePaths = pictures;
        });
        await _performOcrOnScans(pictures);
      }
    } catch (e) {
      _showSnackBar("Scanner Error: $e");
    } finally {
      setState(() { _isProcessing = false; });
    }
  }

  Future<void> _performOcrOnScans(List<String> imagePaths) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    StringBuffer accumulatedText = StringBuffer();

    try {
      for (int i = 0; i < imagePaths.length; i++) {
        final InputImage inputImage = InputImage.fromFilePath(imagePaths[i]);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

        accumulatedText.writeln("--- PAGE ${i + 1} TEXT ---");
        accumulatedText.writeln(recognizedText.text);
        accumulatedText.writeln("\n");
      }

      setState(() {
        _extractedOcrText = accumulatedText.toString();
      });
    } catch (e) {
      _showSnackBar("OCR Processing Error: $e");
    } finally {
      textRecognizer.close();
    }
  }

  // 📄 EXPORTS, UPLOADS TO FIREBASE, AND SAVES TO FIRESTORE
  Future<void> _exportUploadAndSavePdf() async {
    if (_scannedImagePaths.isEmpty) return;

    setState(() { _isProcessing = true; });
    final pdf = pw.Document();

    try {
      // 1. Generate the PDF layout structure in memory
      for (var path in _scannedImagePaths) {
        final imageFile = File(path);
        final imageBytes = await imageFile.readAsBytes();
        final pdfImage = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain));
            },
          ),
        );
      }

      final outputDir = await getApplicationDocumentsDirectory();
      final String timestampName = "Planova_Scan_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${outputDir.path}/$timestampName");
      await file.writeAsBytes(await pdf.save());

      // 2. Upload the file to Firebase Storage
      // Matches path style: folders/{folderId}/{fileName}
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('folders')
          .child(widget.folderId)
          .child(timestampName);

      UploadTask uploadTask = storageRef.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 3. Save matching structural data to Firestore 'documents' collection
      String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "unknown_user";

      await FirebaseFirestore.instance.collection('documents').add({
        'fileName': timestampName,
        'fileType': 'pdf',
        'fileUrl': downloadUrl,
        'folderId': widget.folderId,
        'uploadedAt': FieldValue.serverTimestamp(),
        'userId': currentUid,
        'ocrText': _extractedOcrText, // Saves the extracted text alongside the file data
      });

      _showSnackBar("PDF Saved & Uploaded to Vault Successfully!");

      // Auto-exit page to return to the updated folder layout
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("Failed to save or upload payload: $e");
    } finally {
      setState(() { _isProcessing = false; });
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Planova Scan Suite",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      body: _isProcessing
          ? Center(child: CircularProgressIndicator(color: primaryNavy))
          : Stack(
        children: [
          if (_scannedImagePaths.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Icon(Icons.document_scanner_rounded, color: Colors.white.withOpacity(0.4), size: 72),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Ready to scan A4 Documents",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Features perspective edge-correction & live text extraction",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  "SCANNED PAGES OVERVIEW",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _scannedImagePaths.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 105,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                          image: DecorationImage(
                            image: FileImage(File(_scannedImagePaths[index])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  "EXTRACTED OCR PLAIN TEXT RESULT",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: SelectionArea(
                    child: Text(
                      _extractedOcrText.trim().isEmpty
                          ? "No digital text parsed out yet. Tap capture to run engine updates."
                          : _extractedOcrText,
                      style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.5, fontFamily: 'Courier'),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),

          Positioned(
            bottom: 34,
            left: 24,
            right: 24,
            child: Row(
              children: [
                if (_scannedImagePaths.isNotEmpty) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.08),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _startDocumentScan,
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                      label: const Text("Rescan/Add", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _exportUploadAndSavePdf,
                      icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                      label: const Text("Save & Upload", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _startDocumentScan,
                      icon: const Icon(Icons.camera_rounded, size: 20),
                      label: const Text("Open Smart Camera Launcher", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}