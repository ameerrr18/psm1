import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  final Color primaryNavy = const Color(0xFF1A4789);
  bool _isLoading = false;
  List<dynamic> _recommendations = [];

  // --- THE AI CONNECTION ---
  Future<void> _getAIRecommendation() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      // 1. Get real tasks from your Firestore 'tasks' collection
      final taskSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: user?.uid)
          .where('isDeleted', isEqualTo: false) // Matches your DB field exactly
          .get();

// 2. Map the Firestore data
      final taskList = taskSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'taskId': doc.id,
          'taskName': data['taskName'] ?? "Unnamed Task",
          'description': data['description'] ?? "No description",
          'dueDate': data['endDate'] ?? DateTime.now().toIso8601String(),
          'currentPriority': (data['priority'] ?? 'MEDIUM').toString(),
          'effort': data['effort'] ?? "1",
        };
      }).toList();

// DEBUG: See if the app actually found data before sending to AI
      print("Tasks sent to AI: ${taskList.length}");

      if (taskList.isEmpty) {
        throw "No pending tasks found to analyze.";
      }

      // 3. Call your Deployed Firebase Function
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('getTaskPrioritization');
      final result = await callable.call({
        'currentTasks': taskList,
        'currentDateTime': DateTime.now().toIso8601String(),
      });

// ADD THIS LINE TO DEBUG:
      print("AI RAW RESPONSE: ${result.data}");

      setState(() {
        _recommendations = result.data['recommendedPriorities'] ?? [];
        _isLoading = false;
      });

// Add a check to see if the list is empty
      if (_recommendations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("AI finished, but no recommendations were generated. Check if your tasks have descriptions!")),
        );
      }

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Planova AI Assistant", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryNavy,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildAIHeader(),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_recommendations.isEmpty)
            _buildEmptyState()
          else
            _buildRecommendationList(),
        ],
      ),
    );
  }

  Widget _buildAIHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryNavy.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.psychology, size: 50, color: Color(0xFF1A4789)),
          const SizedBox(height: 10),
          const Text(
            "Predictive Task Prioritization",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            "AI analyzes your workload to recommend the best focus.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _getAIRecommendation,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryNavy,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Run AI Analysis"),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _recommendations.length,
        itemBuilder: (context, index) {
          final item = _recommendations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(15),
              leading: _getPriorityIcon(item['recommendedPriority']),
              title: Text(
                "Recommendation: ${item['recommendedPriority'].toString().toUpperCase()}",
                style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(item['reasoning']),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Expanded(
      child: Center(
        child: Text("Click the button to generate AI insights"),
      ),
    );
  }

  Widget _getPriorityIcon(String priority) {
    Color color = Colors.blue;
    if (priority == 'critical') color = Colors.red;
    if (priority == 'high') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(Icons.priority_high, color: color),
    );
  }
}