import 'package:flutter/material.dart';

class TaskPage extends StatelessWidget {
  const TaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data matching your screenshot
    final List<Map<String, dynamic>> tasks = [
      {
        "title": "DB Optimization: B-Tree In...",
        "time": "6H",
        "date": "MAR 23",
        "priority": "CRITICAL",
        "color": const Color(0xFFFF5252),
        "isDone": false,
      },
      {
        "title": "SwiftUI Reactive State Lab",
        "time": "10H",
        "date": "MAR 26",
        "priority": "HIGH",
        "color": const Color(0xFF1A4789),
        "isDone": false,
      },
      {
        "title": "Heuristic Evaluation Report",
        "time": "8H",
        "date": "MAR 30",
        "priority": "MEDIUM",
        "color": const Color(0xFF4FC3F7),
        "isDone": false,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A4789)),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          "All Tasks",
          style: TextStyle(color: Color(0xFF1A4789), fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18),
              label: const Text("New"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A4789),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search tasks...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Task List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return _buildTaskCard(tasks[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Custom Status Radio
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1A4789), width: 2),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  task['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A4789),
                  ),
                ),
              ),
              // Priority Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task['color'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task['priority'],
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 39), // Align with text
              Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(task['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 15),
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(task['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 15),
          // Analyze Risk Button
          Row(
            children: [
              const SizedBox(width: 39),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Color(0xFF1A4789)),
                    SizedBox(width: 6),
                    Text(
                      "Analyze Risk",
                      style: TextStyle(color: Color(0xFF1A4789), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.delete_outline, color: Colors.grey[300]),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right, color: Colors.grey[300]),
            ],
          )
        ],
      ),
    );
  }
}