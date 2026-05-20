import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'add_task.dart';
import 'task_detail.dart';

class WorkspaceDetailPage extends StatelessWidget {
  final String workspaceId;
  const WorkspaceDetailPage({super.key, required this.workspaceId});

  final Color primaryNavy = const Color(0xFF1A4789);
  final Color bgBlue = const Color(0xFFF4F7FA);

  // GlobalKey to capture the QR view image data context
  static final GlobalKey _qrBoundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('workspaces').doc(workspaceId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          Future.microtask(() {
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        var docSnapshot = snapshot.data!;
        var data = docSnapshot.data() as Map<String, dynamic>?;

        if (data == null) {
          return const Scaffold(body: Center(child: Text("Error: Workspace data is empty")));
        }

        bool isAdmin = data['adminId'] == currentUid;
        bool isActive = data['status'] == 'active';
        List members = data['members'] ?? [];
        String joinCode = data['joinCode'] ?? "N/A";
        String workspaceName = data['name'] ?? "Workspace";

        return Scaffold(
          backgroundColor: bgBlue,
          floatingActionButton: isActive
              ? FloatingActionButton(
            backgroundColor: primaryNavy,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddTaskPage(workspaceId: workspaceId)),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          )
              : null,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  if (isAdmin) _buildRequestNotification(context),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.black87),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (value) => _handleMenuSelection(
                          context, value, workspaceId, isActive, data['name'], data['description'], currentUid),
                      itemBuilder: (context) => [
                        if (isAdmin) ...[
                          _buildMenuItem('edit', Icons.edit_outlined, "Edit Workspace"),
                          _buildMenuItem('status', Icons.power_settings_new, isActive ? "Deactivate" : "Activate"),
                          const PopupMenuDivider(),
                          _buildMenuItem('delete', Icons.delete_outline, "Delete", color: Colors.red),
                        ] else ...[
                          _buildMenuItem('leave', Icons.logout, "Leave Workspace", color: Colors.red),
                        ],
                      ],
                    ),
                  )
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.fromLTRB(25, 100, 25, 20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statusBadge(isActive),
                        const SizedBox(height: 8),
                        Text(workspaceName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryNavy)),
                        const SizedBox(height: 4),
                        Text(data['description'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text("TEAMMATE PORTAL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      _buildAccessKeyCard(context, joinCode, workspaceName),
                      const SizedBox(height: 25),
                      const Text("COLLABORATORS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      _buildAvatarStack(context, members),
                      const SizedBox(height: 30),
                      const Text("TASK BACKLOG", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              _buildSliverTaskList(workspaceId, isActive),
            ],
          ),
        );
      },
    );
  }

  // --- REQUEST MANAGEMENT UI ---

  Widget _buildRequestNotification(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('joinRequests')
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black87),
              onPressed: () => _showRequestsDialog(context),
            ),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text("$count", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )
          ],
        );
      },
    );
  }

  void _showRequestsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('workspaces')
              .doc(workspaceId)
              .collection('joinRequests')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            var docs = snapshot.data!.docs;

            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("Join Requests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Divider(),
                  Expanded(
                    child: docs.isEmpty
                        ? const Center(child: Text("No pending requests"))
                        : ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        var request = docs[i].data() as Map<String, dynamic>;
                        String userId = request['uid'] ?? docs[i].id;
                        String userName = request['name'] ?? "Unknown User";
                        String userEmail = request['email'] ?? "";

                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(userName),
                          subtitle: Text(userEmail),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => _approveUser(userId),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.red),
                                onPressed: () => _rejectUser(userId),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _approveUser(String uid) async {
    await FirebaseFirestore.instance.collection('workspaces').doc(workspaceId).update({
      'members': FieldValue.arrayUnion([uid])
    });
    _rejectUser(uid);
  }

  void _rejectUser(String uid) {
    FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .collection('joinRequests')
        .doc(uid)
        .delete();
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String text, {Color? color}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.black87),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(color: color ?? Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- ACCESS CARD UPDATED FOR DYNAMIC SHARE HANDLERS ---
  Widget _buildAccessKeyCard(BuildContext context, String code, String workspaceName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2B5896), Color(0xFF1E3C72)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("ACCESS KEY", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(code, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _cardButton(Icons.copy, "Copy", () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Key copied!")));
                    }),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showFullQR(context, code, workspaceName),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: QrImageView(
                data: code,
                version: QrVersions.auto,
                size: 75,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.circle, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Colors.black),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAvatarStack(BuildContext context, List members) {
    return Row(
      children: [
        // 🚀 Loop through the first 4 members dynamically using a sub-widget handler
        ...members.take(4).map((uid) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _buildSingleMemberAvatar(uid.toString()),
        )),

        // Overflow Indicator (+ X Counter)
        if (members.length > 4)
          CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: Text(
                  "+${members.length - 4}",
                  style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold)
              )
          ),
        const SizedBox(width: 8),

        // Add Button Interaction
        InkWell(
          onTap: () => _showAddMemberDialog(context, members),
          borderRadius: BorderRadius.circular(20),
          child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE3F2FD),
              child: Icon(Icons.add, color: primaryNavy, size: 18)
          ),
        ),
      ],
    );
  }

  Widget _buildSingleMemberAvatar(String uid) {
    return FutureBuilder<QuerySnapshot>(
      // 🔍 FIX: Query by the 'uid' field instead of document ID
      future: FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        // Fallback placeholder while loading or if user isn't found
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return CircleAvatar(
            radius: 18,
            backgroundColor: primaryNavy.withOpacity(0.1),
            child: Icon(Icons.person, size: 16, color: primaryNavy),
          );
        }

        // Get the document data map safely from the query results
        var userDoc = snapshot.data!.docs.first;
        var userData = userDoc.data() as Map<String, dynamic>? ?? {};

        // Match keys directly with your Firestore setup ('profileImage' & 'username')
        String? imageUrl = userData['profileImage'];
        String name = userData['username'] ?? "P";

        // 🖼️ Condition A: Render Network Image if the profile image string exists
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[200],
            backgroundImage: NetworkImage(imageUrl),
          );
        }

        // 🔤 Condition B: Render initial letter badge fallback
        return CircleAvatar(
          radius: 18,
          backgroundColor: primaryNavy.withOpacity(0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : "P",
            style: TextStyle(color: primaryNavy, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildSliverTaskList(String id, bool isActive) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('workspaces')
          .doc(id)
          .collection('tasks')
          .where('isDeleted', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data == null) {
          return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                var doc = snap.data!.docs[index];
                var task = doc.data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TaskDetailPage(taskId: doc.id, workspaceId: workspaceId))),
                  child: _taskCard(task, id),
                );
              },
              childCount: snap.data!.docs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _taskCard(Map<String, dynamic> task, String workspaceId) {
    // 1. Safe state evaluation variables
    final String taskId = task['taskId'] ?? '';
    final String status = task['status'] ?? 'PENDING';
    final bool isCompleted = status == 'DONE';

    // Design system token colors
    const Color primaryNavy = Color(0xFF1A4789);
    const Color successGreen = Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ✅ INTERACTIVE CHECKBOX ICON BUTTON
          IconButton(
            onPressed: () async {
              if (taskId.isEmpty) return;

              // Toggle the status field natively in Firestore
              final String nextStatus = isCompleted ? 'PENDING' : 'DONE';
              await FirebaseFirestore.instance
                  .collection('workspaces')
                  .doc(workspaceId)
                  .collection('tasks')
                  .doc(taskId)
                  .update({
                'status': nextStatus,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            },
            icon: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isCompleted ? successGreen : Colors.grey.shade400,
              size: 26,
            ),
            splashRadius: 24,
          ),
          const SizedBox(width: 10),

          // 📝 TASK INFORMATION TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  " ${task['taskName'] ?? 'Task'}",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.grey.shade400 : primaryNavy,
                    // Adds a clean strikethrough line when task status matches DONE
                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      // Format or clean up the date if you're using Iso8601 strings
                      task['endDate'] != null && task['endDate'].toString().contains('T')
                          ? task['endDate'].toString().split('T')[0]
                          : task['endDate'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "•  ${task['assignedName'] ?? 'Unassigned'}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isCompleted ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 🏷️ PRIORITY BADGE (Fades out when task is completed)
          Opacity(
            opacity: isCompleted ? 0.4 : 1.0,
            child: _priorityBadge(task['priority'] ?? 'MEDIUM'),
          ),
        ],
      ),
    );
  }

  // --- REPAINT LOGIC FOR CAPTURING DATA STREAMS AS IMAGES ---
  Future<void> _shareQrImage(String workspaceName, String code) async {
    try {
      // Find boundary frame elements matching the specific global structural key context
      RenderRepaintBoundary? boundary = _qrBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) return;

      // Force programmatic evaluation layout frame capture matrix context to clear high density image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // Write directly to temporary device storage cache paths directory elements context
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/workspace_qr.png').create();
        await file.writeAsBytes(pngBytes);

        // Call Native system modal to handle media file injection directly across applications
        await Share.shareXFiles(
          [XFile(file.path)],
          text: "Scan this QR code to instantly access our project workspace: *$workspaceName* (Code: $code)!",
        );
      }
    } catch (e) {
      debugPrint("Failed generating shared system asset element background context: $e");
    }
  }

  // --- UPDATED QR DIALOG WITH LIVE EXPORT ACTION ---
  void _showFullQR(BuildContext context, String code, String workspaceName) {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.white,
        elevation: 24,
        shadowColor: primaryNavy.withOpacity(0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Accent Bar for Premium feel
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),

              // Header Group
              Text(
                  "SHARE WORKSPACE",
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: primaryNavy.withOpacity(0.6),
                      fontSize: 10,
                      letterSpacing: 2.0
                  )
              ),
              const SizedBox(height: 4),
              Text(
                workspaceName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryNavy,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),

              // Premium Floating QR container
              RepaintBoundary(
                key: _qrBoundaryKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                    border: Border.all(color: Colors.grey.shade100, width: 1),
                  ),
                  child: QrImageView(
                    data: code,
                    version: QrVersions.auto,
                    size: 180.0,
                    foregroundColor: primaryNavy,
                    eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.circle, color: primaryNavy),
                    dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: primaryNavy),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Clean Code Box with Instant Tap-to-Copy interaction
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Access Key copied!"), behavior: SnackBarBehavior.floating),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: bgBlue.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryNavy.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 24),
                      Text(
                          code,
                          style: TextStyle(
                              letterSpacing: 6,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              color: primaryNavy
                          )
                      ),
                      Icon(Icons.copy_rounded, size: 16, color: primaryNavy.withOpacity(0.4)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Modern Interactive Action Tray
              Row(
                children: [
                  // Share QR Image
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareQrImage(workspaceName, code),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text("Share QR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryNavy,
                        side: BorderSide(color: primaryNavy.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // WhatsApp text share template shortcut
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // 🛠️ Construct your app's join link (replace with your actual domain or scheme)
                        // Example using a universal link format:
                        String appLink = "https://planova.app/join?code=$code";

                        // Modern structured message formatting
                        String message = "🚀 Join my Workspace '$workspaceName' on Planova!\n\n"
                            "👉 Click this link to join directly:\n$appLink\n\n"
                            "Alternatively, enter the Invite Code manually: *$code*";

                        Share.share(message);
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text("Share Link", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Subtle Cancel/Done string option instead of a heavy button
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[500],
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Dismiss", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, String val, String id, bool status, String name, String desc, String currentUid) {
    if (val == 'status') {
      FirebaseFirestore.instance.collection('workspaces').doc(id).update({'status': status ? 'inactive' : 'active'});
    } else if (val == 'delete') {
      _confirmDelete(context, id);
    } else if (val == 'edit') {
      _showEditDialog(context, id, name, desc);
    } else if (val == 'leave') {
      _confirmLeave(context, id, currentUid);
    }
  }

  void _confirmLeave(BuildContext context, String workspaceId, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Leave Workspace?"),
        content: const Text("You will no longer have access to this portal."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () {
            FirebaseFirestore.instance.collection('workspaces').doc(workspaceId).update({'members': FieldValue.arrayRemove([uid])});
            Navigator.pop(context); Navigator.pop(context);
          }, child: const Text("Leave", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, List existingMembers) {
    final String authUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('uid', isEqualTo: authUid)
              .snapshots(),
          builder: (context, userQuerySnap) {
            if (userQuerySnap.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }

            if (!userQuerySnap.hasData || userQuerySnap.data!.docs.isEmpty) {
              return const SizedBox(height: 200, child: Center(child: Text("User profile not found")));
            }

            var userData = userQuerySnap.data!.docs.first.data() as Map<String, dynamic>;
            List friends = userData['friends'] ?? [];

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('workspaces')
                  .doc(workspaceId)
                  .collection('joinRequests')
                  .snapshots(),
              builder: (context, requestSnap) {
                if (!requestSnap.hasData) return const Center(child: CircularProgressIndicator());

                List pendingUids = requestSnap.data!.docs.map((doc) => doc.id).toList();

                List eligible = friends.where((f) =>
                !existingMembers.contains(f) && !pendingUids.contains(f)
                ).toList();

                return Container(
                  padding: const EdgeInsets.all(20),
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    children: [
                      const Text("Invite Friends", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const Divider(),
                      Expanded(
                        child: eligible.isEmpty
                            ? const Center(child: Text("No friends to invite"))
                            : ListView.builder(
                          itemCount: eligible.length,
                          itemBuilder: (context, i) => _buildFriendTile(eligible[i].toString(), context),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFriendTile(String friendUid, BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: friendUid)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox();

        var data = snap.data!.docs.first.data() as Map<String, dynamic>;
        String name = data['username'] ?? "Unknown";
        String email = data['email'] ?? "";

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: primaryNavy.withOpacity(0.1),
            child: Text(name[0].toUpperCase(), style: TextStyle(color: primaryNavy)),
          ),
          title: Text(name),
          subtitle: Text(email),
          trailing: IconButton(
            icon: const Icon(Icons.send, color: Colors.green),
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('workspaces')
                  .doc(workspaceId)
                  .collection('joinRequests')
                  .doc(friendUid)
                  .set({
                'uid': friendUid,
                'name': name,
                'email': email,
                'status': 'pending',
                'timestamp': FieldValue.serverTimestamp(),
                'workspaceName': 'FYP',
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invite sent to $name")));
            },
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, String id, String name, String desc) {
    final nC = TextEditingController(text: name);
    final dC = TextEditingController(text: desc);

    // Define UI theme colors matching your app architecture
    const Color primaryNavy = Color(0xFF1A4789);
    const Color lightBg = Color(0xFFF8FAFC);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: primaryNavy.withOpacity(0.1),
                    child: const Icon(Icons.edit_note_rounded, color: primaryNavy, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Edit Workspace",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Input: Workspace Name
              const Text(
                "WORKSPACE NAME",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: nC,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: primaryNavy),
                  decoration: const InputDecoration(
                    hintText: "Enter workspace name...",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Input: Description
              const Text(
                "DESCRIPTION",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: dC,
                  maxLines: 3,
                  minLines: 1,
                  style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.4),
                  decoration: const InputDecoration(
                    hintText: "What is this workspace used for?",
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Actions Layout Track
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Cancel Action Button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                  const SizedBox(width: 8),

                  // Save Action Button
                  ElevatedButton(
                    onPressed: () {
                      if (nC.text.trim().isEmpty) return;
                      FirebaseFirestore.instance.collection('workspaces').doc(id).update({
                        'name': nC.text.trim(),
                        'description': dC.text.trim(),
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Workspace?"),
        content: const Text("This action is permanent."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel")
          ),
          TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await FirebaseFirestore.instance.collection('workspaces').doc(id).delete();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e"))
                    );
                  }
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool active) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: active ? const Color(0xFFE3F2FD) : Colors.red[50],
              borderRadius: BorderRadius.circular(20)), child: Text(active ? "ACTIVE WORKSPACE" : "INACTIVE",
          style: TextStyle(color: active ? const Color(0xFF1976D2) : Colors.red,
              fontSize: 10, fontWeight: FontWeight.bold)));

  Widget _cardButton(IconData icon, String label, VoidCallback onTap) =>
      InkWell(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))])));

  Widget _priorityBadge(String p) =>
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFE0F7FA),
              borderRadius: BorderRadius.circular(8)), child: Text(p, style: const TextStyle(color: Color(0xFF00ACC1),
              fontSize: 9, fontWeight: FontWeight.bold)));
}