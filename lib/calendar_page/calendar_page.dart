import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planova/task_page/detailtask_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final Color primaryNavy = const Color(0xFF1A4789);
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Schedule", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('userId', isEqualTo: currentUid) // CRITICAL: You must filter by userId first
            .where('isDeleted', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          // Map tasks to their dates
          Map<DateTime, List<Map<String, dynamic>>> taskMap = {};
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            data['taskId'] = doc.id;
            DateTime date = DateTime.parse(data['taskDate']).toLocal();
            DateTime dayOnly = DateTime(date.year, date.month, date.day);

            if (taskMap[dayOnly] == null) taskMap[dayOnly] = [];
            taskMap[dayOnly]!.add(data);
          }

          // Filter tasks for the selected day
          List<Map<String, dynamic>> selectedTasks = taskMap[DateTime(
              _selectedDay!.year, _selectedDay!.month, _selectedDay!.day)] ?? [];

          return Column(
            children: [
              _buildCalendarGrid(taskMap),
              const SizedBox(height: 10),
              Expanded(
                child: _buildTaskList(selectedTasks),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, List<Map<String, dynamic>>> taskMap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        eventLoader: (day) => taskMap[DateTime(day.year, day.month, day.day)] ?? [],

        // Microsoft Style Customization
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: primaryNavy.withOpacity(0.2), shape: BoxShape.circle),
          selectedDecoration: BoxDecoration(color: primaryNavy, shape: BoxShape.circle),
          markerDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
          markersMaxCount: 1,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 10),
            const Text("No tasks for this day", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        bool isDone = task['status'] == "DONE";

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            leading: VerticalDivider(
              thickness: 4,
              color: _getPriorityColor(task['priority']),
            ),
            title: Text(
              task['taskName'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryNavy,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text("${task['effort']} Hours • ${task['priority']}"),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailTaskPage(task: task)),
            ),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'CRITICAL': return Colors.red;
      case 'HIGH': return Colors.orange;
      case 'MEDIUM': return Colors.blue;
      case 'LOW': return Colors.green;
      default: return Colors.grey;
    }
  }
}