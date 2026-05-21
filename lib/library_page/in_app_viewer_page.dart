import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart'; // 🔑 Added for reliable modern storage requests

class InAppViewerPage extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  final bool isPdf;

  const InAppViewerPage({
    super.key,
    required this.fileUrl,
    required this.fileName,
    required this.isPdf,
  });

  @override
  State<InAppViewerPage> createState() => _InAppViewerPageState();
}

class _InAppViewerPageState extends State<InAppViewerPage> {
  String? _localPdfPath;
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isSharing = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    if (widget.isPdf) {
      _downloadAndSavePdfToCache();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _downloadAndSavePdfToCache() async {
    try {
      final response = await http.get(Uri.parse(widget.fileUrl));
      final bytes = response.bodyBytes;

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/local_render_${DateTime.now().millisecondsSinceEpoch}.pdf");

      await file.writeAsBytes(bytes, flush: true);
      setState(() {
        _localPdfPath = file.path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load document view: $e";
        _isLoading = false;
      });
    }
  }

  // 💾 SAFELY DOWNLOAD FILES COMPLIANT WITH MODERN OS RULES
  Future<void> _downloadFileToDevice() async {
    setState(() { _isDownloading = true; });
    try {
      // 1. Request Necessary System Permissions dynamically
      if (Platform.isAndroid) {
        if (widget.isPdf) {
          // Request storage access for older versions; modern Android handles downloads differently
          await Permission.storage.request();
        } else {
          // Photos access permission for saving images
          Map<Permission, PermissionStatus> statuses = await [
            Permission.photos,
            Permission.storage,
          ].request();

          if (statuses[Permission.photos]!.isDenied) {
            _showCustomToast("Gallery permission is required to save images.", isSuccess: false);
            setState(() { _isDownloading = false; });
            return;
          }
        }
      }

      final response = await http.get(Uri.parse(widget.fileUrl));
      final bytes = response.bodyBytes;

      if (widget.isPdf) {
        String savePath = "";
        String locationTarget = "";

        if (Platform.isAndroid) {
          // Official modern access strategy to get public paths safely
          final Directory androidPublicDownloadDir = Directory('/storage/emulated/0/Download');

          if (await androidPublicDownloadDir.exists()) {
            savePath = androidPublicDownloadDir.path;
            locationTarget = "Downloads folder";
          } else {
            // Use external storage directories type downloads to request app specific container matching
            final externalDirs = await getExternalStorageDirectories(type: StorageDirectory.downloads);
            if (externalDirs != null && externalDirs.isNotEmpty) {
              savePath = externalDirs.first.path;
              locationTarget = "Internal App Storage";
            } else {
              savePath = (await getApplicationDocumentsDirectory()).path;
              locationTarget = "App Storage";
            }
          }
        } else {
          // iOS standard pathing rules
          final iosDir = await getApplicationDocumentsDirectory();
          savePath = iosDir.path;
          locationTarget = "App Documents";
        }

        // Sanitize naming attributes
        String safeName = widget.fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
        if (!safeName.toLowerCase().endsWith('.pdf')) safeName += '.pdf';

        final fileToSave = File("$savePath/$safeName");
        await fileToSave.writeAsBytes(bytes, flush: true);

        _showCustomToast("Saved safely to $locationTarget: $safeName", isSuccess: true);
      } else {
        // --- SECURE GAL IMAGE WRITING PATTERN ---
        final tempDir = await getTemporaryDirectory();
        final tempFile = File("${tempDir.path}/temp_hold_${DateTime.now().millisecondsSinceEpoch}.png");
        await tempFile.writeAsBytes(bytes, flush: true);

        // Native platform bridge call saves it cleanly to photos roll
        await Gal.putImage(tempFile.path);
        _showCustomToast("Image saved directly to Photos Roll!", isSuccess: true);
      }
    } catch (e) {
      _showCustomToast("Download error: $e", isSuccess: false);
    } finally {
      setState(() { _isDownloading = false; });
    }
  }

  // 📤 SHARE TO WHATSAPP / SYSTEM TRAY
  Future<void> _shareFileToApps() async {
    setState(() { _isSharing = true; });
    try {
      final response = await http.get(Uri.parse(widget.fileUrl));
      final bytes = response.bodyBytes;

      String safeName = widget.fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
      final extension = widget.isPdf ? '.pdf' : '.png';
      if (!safeName.toLowerCase().endsWith(extension)) safeName += extension;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File("${tempDir.path}/$safeName");
      await tempFile.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: "Sending document via Planova",
      );
    } catch (e) {
      _showCustomToast("Could not prepare share file: $e", isSuccess: false);
    } finally {
      setState(() { _isSharing = false; });
    }
  }

  void _showCustomToast(String msg, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? const Color(0xFF10B981) : Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isPdf ? const Color(0xFFF1F5F9) : Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.fileName,
          style: const TextStyle(color: Color(0xFF1A4789), fontSize: 15, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A4789), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isSharing
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A4789))),
          )
              : IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF1A4789), size: 22),
            onPressed: _isLoading ? null : _shareFileToApps,
            tooltip: "Share Document",
          ),
          _isDownloading
              ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A4789))),
          )
              : IconButton(
            icon: const Icon(Icons.file_download_rounded, color: Color(0xFF1A4789), size: 24),
            onPressed: _isLoading ? null : _downloadFileToDevice,
            tooltip: "Download Document",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A4789)))
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
          : widget.isPdf
          ? PDFView(
        filePath: _localPdfPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
      )
          : Center(
        child: InteractiveViewer(
          maxScale: 4.0,
          child: Image.network(
            widget.fileUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1A4789)));
            },
            errorBuilder: (context, error, stackTrace) => const Text(
              "Failed to render image asset.",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}