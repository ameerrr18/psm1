import 'package:flutter/material.dart';

class DetailTaskPage extends StatelessWidget {
  final Map<String, dynamic> task;

  const DetailTaskPage({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(task['taskName'])),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text("Task ID: ${task['taskId']}"),
      ),
    );
  }
}