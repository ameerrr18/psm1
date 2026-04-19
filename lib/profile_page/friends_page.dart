import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final Color primaryNavy = const Color(0xFF1A4789);
  final TextEditingController _searchController = TextEditingController();
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Map<String, dynamic>? _searchedUser;
  bool _isSearching = false;

  // Logic: Search User Details
  Future<void> _searchUser() async {
    String email = _searchController.text.trim().toLowerCase();
    if (email.isEmpty) return;

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      setState(() {
        _searchedUser = query.docs.first.data();
        // CRITICAL: Use the 'uid' field from the document data, NOT the document ID
        _searchedUser!['uid'] = query.docs.first.data()['uid'];
      });
    } else {
      _showSnack("User not found");
    }
  }

  // Logic: Send Friend Request
  Future<void> _sendRequest() async {
    if (_searchedUser == null) return;

    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // CRITICAL FIX: Use the UID we found during the search
    final String targetUid = _searchedUser!['uid'];

    if (targetUid == currentUid) {
      _showSnack("You can't add yourself!");
      return;
    }

    await FirebaseFirestore.instance.collection('friendRequests').add({
      'from': FirebaseAuth.instance.currentUser?.uid,
      'to': targetUid, // Now this will match what the recipient sees as their own UID
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'fromEmail': FirebaseAuth.instance.currentUser?.email,
      'fromName': FirebaseAuth.instance.currentUser?.displayName ?? "User",
    });

    setState(() => _searchedUser = null);
    _searchController.clear();
    _showSnack("Request Sent!");
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Community", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        leading: BackButton(color: primaryNavy),
      ),
      body: Column(
        children: [
          // Search Section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Enter friend's email...",
                    filled: true, fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: _searchUser
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                if (_searchedUser != null) _buildUserPreviewCard(),
              ],
            ),
          ),

          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelColor: primaryNavy,
                    indicatorColor: primaryNavy,
                    tabs: const [Tab(text: "Requests"), Tab(text: "Friends")],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [_buildPendingList(), _buildFriendsList()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Inside your _FriendsPageState class

  Widget _buildUserPreviewCard() {
    if (_searchedUser == null) return const SizedBox.shrink();

    // Handle date formatting safely
    String memberSince = "Recent";
    if (_searchedUser!['createdAt'] != null) {
      DateTime date = (_searchedUser!['createdAt'] as Timestamp).toDate();
      memberSince = DateFormat('MMM dd, yyyy').format(date);
    }

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: primaryNavy.withOpacity(0.1),
                child: Text(
                  (_searchedUser!['username'] ?? "U")[0].toUpperCase(),
                  style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _searchedUser!['username'] ?? "Unknown User",
                      style: TextStyle(color: primaryNavy, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _searchedUser!['email'] ?? "",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("MEMBER SINCE", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(memberSince, style: TextStyle(color: primaryNavy, fontWeight: FontWeight.w600)),
                ],
              ),
              ElevatedButton(
                onPressed: _sendRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                ),
                child: const Text("Add Friend", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friendRequests')
          .where('to', isEqualTo: currentUid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No pending requests"));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_outline)),
              title: Text(data['fromName'] ?? "Unknown"),
              subtitle: Text(data['fromEmail'] ?? ""),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _handleRequest(docs[index].id, true, data['from'])),
                  IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _handleRequest(docs[index].id, false, data['from'])),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- (Keeping your _handleRequest and _buildFriendsList logic from previous turn) ---
  Future<void> _handleRequest(String requestId, bool accept, String otherUid) async {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      if (accept) {
        // We use a transaction to ensure atomic updates
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // 1. Find the current user's document
          var myQuery = await FirebaseFirestore.instance.collection('users')
              .where('uid', isEqualTo: currentUid).limit(1).get();

          // 2. Find the other user's document
          var theirQuery = await FirebaseFirestore.instance.collection('users')
              .where('uid', isEqualTo: otherUid).limit(1).get();

          if (myQuery.docs.isNotEmpty && theirQuery.docs.isNotEmpty) {
            // 3. Perform the updates inside the transaction
            transaction.update(myQuery.docs.first.reference, {
              'friends': FieldValue.arrayUnion([otherUid])
            });
            transaction.update(theirQuery.docs.first.reference, {
              'friends': FieldValue.arrayUnion([currentUid])
            });
          }
        });
      }

      // 4. Delete the request
      await FirebaseFirestore.instance.collection('friendRequests').doc(requestId).delete();
      _showSnack(accept ? "Accepted!" : "Declined");

    } catch (e) {
      print("Transaction failed: $e");
      _showSnack("Permission Error: Ensure rules allow 'friends' update.");
    }
  }

  Widget _buildFriendsList() {
    return StreamBuilder<DocumentSnapshot>(
      // 1. Get the current user's document to see their friends list
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .limit(1)
          .snapshots()
          .map((snapshot) => snapshot.docs.first),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var data = snapshot.data!.data() as Map<String, dynamic>?;
        List friends = data?['friends'] ?? [];

        if (friends.isEmpty) return const Center(child: Text("No friends yet."));

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            // 2. Query for the friend's user data using their long UID string
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('uid', isEqualTo: friends[index])
                  .limit(1)
                  .get(),
              builder: (context, friendSnap) {
                if (!friendSnap.hasData || friendSnap.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                var friendData = friendSnap.data!.docs.first.data() as Map<String, dynamic>;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primaryNavy.withOpacity(0.1),
                    child: Text((friendData['username'] ?? "U")[0].toUpperCase()),
                  ),
                  title: Text(friendData['username'] ?? "User"),
                  subtitle: Text(friendData['email'] ?? ""),
                );
              },
            );
          },
        );
      },
    );
  }
}