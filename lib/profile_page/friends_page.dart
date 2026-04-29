import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> with SingleTickerProviderStateMixin {
  final Color primaryNavy = const Color(0xFF1A4789);
  final Color accentBlue = const Color(0xFF3B82F6);
  final TextEditingController _searchController = TextEditingController();
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late TabController _tabController;
  List<dynamic> _currentUserFriends = [];

  Map<String, dynamic>? _searchedUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Community", style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryNavy,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          _buildCustomTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildPendingList(), _buildFriendsList()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _searchUser(),
            decoration: InputDecoration(
              hintText: "Search by email...",
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
              suffixIcon: IconButton(
                onPressed: _searchUser,
                icon: Icon(Icons.arrow_forward_rounded, color: accentBlue),
              ),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            ),
          ),
          if (_searchedUser != null) _buildUserPreviewCard(),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(color: primaryNavy, borderRadius: BorderRadius.circular(12)),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [Tab(text: "Requests"), Tab(text: "Friends")],
      ),
    );
  }

  Widget _buildUserPreviewCard() {
    if (_searchedUser == null) return const SizedBox.shrink();

    // Check if this person is already in our friends list
    bool isAlreadyFriend = _currentUserFriends.contains(_searchedUser!['uid']);
    String? imageUrl = _searchedUser!['profileImage'];

    return Container(
      margin: const EdgeInsets.only(top: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primaryNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primaryNavy.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.2),
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            child: imageUrl == null || imageUrl.isEmpty
                ? Text((_searchedUser!['username'] ?? "U")[0].toUpperCase(),
                style: const TextStyle(color: Colors.white))
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_searchedUser!['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(_searchedUser!['email'], style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
              ],
            ),
          ),ElevatedButton(
            // If already friends, onPressed is null (disables button)
            onPressed: isAlreadyFriend ? null : _sendRequest,
            style: ElevatedButton.styleFrom(
              // Color when button is ENABLED (Add)
              backgroundColor: Colors.white,
              foregroundColor: primaryNavy,

              // Color when button is DISABLED (Friend)
              disabledBackgroundColor: Colors.white.withOpacity(0.2), // Light glass effect
              disabledForegroundColor: Colors.white, // This makes the "Friend" text visible

              shape: const StadiumBorder(),
              elevation: isAlreadyFriend ? 0 : 2,
            ),
            child: Text(
                isAlreadyFriend ? "Friend" : "Add",
                style: const TextStyle(fontWeight: FontWeight.bold)
            ),
          )
        ],
      ),
    );
  }


  Widget _buildFriendsList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: currentUid)
          .limit(1)
          .snapshots()
          .map((s) => s.docs.first),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        List friends = (snapshot.data!.data() as Map)['friends'] ?? [];

        if (friends.isEmpty) return const Center(child: Text("No friends yet."));

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('users').where('uid', isEqualTo: friends[index]).get(),
              builder: (context, fSnap) {
                if (!fSnap.hasData || fSnap.data!.docs.isEmpty) return const SizedBox.shrink();
                var fData = fSnap.data!.docs.first.data() as Map;
                String targetUid = fData['uid'];
                String? friendImageUrl = fData['profileImage'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: accentBlue.withOpacity(0.1),
                      backgroundImage: friendImageUrl != null && friendImageUrl.isNotEmpty
                          ? NetworkImage(friendImageUrl)
                          : null,
                      child: friendImageUrl == null || friendImageUrl.isEmpty
                          ? Text(fData['username'][0].toUpperCase(), style: TextStyle(color: accentBlue))
                          : null,
                    ),
                    title: Text(fData['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(fData['email'], style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent, size: 22),
                      onPressed: () => _confirmUnfriend(targetUid, fData['username']),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _confirmUnfriend(String targetUid, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unfriend?"),
        content: Text("Are you sure you want to remove $name from your friends list?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _unfriendUser(targetUid);
              },
              child: const Text("Remove", style: TextStyle(color: Colors.red))
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
            String? requesterImageUrl = data['fromImageUrl'];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[200],
                backgroundImage: requesterImageUrl != null && requesterImageUrl.isNotEmpty
                    ? NetworkImage(requesterImageUrl)
                    : null,
                child: requesterImageUrl == null || requesterImageUrl.isEmpty
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
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

  // Logic: Search User Details
  Future<void> _searchUser() async {
    String email = _searchController.text.trim().toLowerCase();
    if (email.isEmpty) return;

    try {
      // Fetch current user's data to get latest friends list
      final me = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: currentUid)
          .limit(1)
          .get();

      if (me.docs.isNotEmpty) {
        _currentUserFriends = me.docs.first.data()['friends'] ?? [];
      }

      // Search for target user
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        setState(() {
          _searchedUser = query.docs.first.data();
          _searchedUser!['uid'] = query.docs.first.data()['uid'];
        });
      } else {
        _showSnack("User not found");
      }
    } catch (e) {
      _showSnack("Search failed");
    }
  }

  Future<void> _unfriendUser(String targetUid) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        var myDoc = await FirebaseFirestore.instance.collection('users').where('uid', isEqualTo: currentUid).limit(1).get();
        var theirDoc = await FirebaseFirestore.instance.collection('users').where('uid', isEqualTo: targetUid).limit(1).get();

        if (myDoc.docs.isNotEmpty && theirDoc.docs.isNotEmpty) {
          transaction.update(myDoc.docs.first.reference, {
            'friends': FieldValue.arrayRemove([targetUid])
          });
          transaction.update(theirDoc.docs.first.reference, {
            'friends': FieldValue.arrayRemove([currentUid])
          });
        }
      });
      _showSnack("Unfriended successfully");
    } catch (e) {
      _showSnack("Failed to unfriend");
    }
  }

  // Logic: Send Friend Request
  Future<void> _sendRequest() async {
    if (_searchedUser == null) return;

    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final myData = await FirebaseFirestore.instance.collection('users')
        .where('uid', isEqualTo: currentUid).limit(1).get();
    String? myImageUrl = myData.docs.first.data()['profileImage'];

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
      'fromImageUrl': myImageUrl,
    });

    setState(() => _searchedUser = null);
    _searchController.clear();
    _showSnack("Request Sent!");
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}