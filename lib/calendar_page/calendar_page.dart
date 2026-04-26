import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planova/task_page/detailtask_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../task_page/add_newtask.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final Color primaryNavy = const Color(0xFF1A4789);
  final Color accentAzure = const Color(0xFF0078D4);
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _selectedDay = _normalizeDate(_focusedDay);
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Color _generateTaskColor(String taskId) {
    final List<Color> modernPalette = [
      const Color(0xFF0078D4),
      const Color(0xFF107C10),
      const Color(0xFFD83B01),
      const Color(0xFF80397B),
      const Color(0xFF008272),
    ];
    return modernPalette[taskId.hashCode % modernPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFF),
      appBar: AppBar(
        title: const Text("My Schedule",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (context) => const AddNewTask())),
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


      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('userId', isEqualTo: currentUid)
            .where('isDeleted', isEqualTo: false)
            .where('status', isNotEqualTo: 'DONE')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          Map<DateTime, List<Map<String, dynamic>>> taskMap = {};
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            data['taskId'] = doc.id;
            try {
              DateTime start = _normalizeDate(DateTime.parse(data['startDate']).toLocal());
              DateTime end = _normalizeDate(DateTime.parse(data['endDate']).toLocal());
              int daysSpan = end.difference(start).inDays;
              for (int i = 0; i <= daysSpan; i++) {
                DateTime currentDay = start.add(Duration(days: i));
                if (taskMap[currentDay] == null) taskMap[currentDay] = [];
                taskMap[currentDay]!.add(data);
              }
            } catch (e) {}
          }

          DateTime selectedKey = _normalizeDate(_selectedDay ?? DateTime.now());
          List<Map<String, dynamic>> selectedTasks = taskMap[selectedKey] ?? [];

          return Column(
            children: [
              _buildCalendarGrid(taskMap),
              const SizedBox(height: 20),
              _buildTaskHeader(selectedTasks.length),
              const SizedBox(height: 10),
              Expanded(child: _buildTaskList(selectedTasks)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendarGrid(Map<DateTime, List<Map<String, dynamic>>> taskMap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
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
        eventLoader: (day) => taskMap[_normalizeDate(day)] ?? [],
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox();
            final dayTasks = events.cast<Map<String, dynamic>>();
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: dayTasks.take(3).map((task) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: 4, width: 8,
                  decoration: BoxDecoration(
                    color: _generateTaskColor(task['taskId']),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )).toList(),
              ),
            );
          },
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(color: accentAzure.withOpacity(0.1), shape: BoxShape.circle),
          todayTextStyle: TextStyle(color: accentAzure, fontWeight: FontWeight.bold),
          selectedDecoration: BoxDecoration(color: primaryNavy, shape: BoxShape.circle),
        ),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      ),
    );
  }

  Widget _buildTaskHeader(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(DateFormat('MMMM d').format(_selectedDay!),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text("$count Tasks", style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_rounded, size: 60, color: Colors.grey[200]),
            const Text("No tasks found", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      // Padding adjusted for the Bottom Nav Bar only (100)
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        Color taskColor = _generateTaskColor(task['taskId']);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
          ),
          child: ListTile(
            leading: Container(width: 4, height: 30, decoration: BoxDecoration(color: taskColor, borderRadius: BorderRadius.circular(10))),
            title: Text(task['taskName'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${task['effort']} hrs • ${task['priority']}"),
            trailing: const Icon(Icons.chevron_right_rounded),
            // Use the taskId field from your calendar task object
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DetailTaskPage(taskId: task['taskId']))),
          ),
        );
      },
    );
  }
}