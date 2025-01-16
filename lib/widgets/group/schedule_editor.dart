import 'package:flutter/material.dart';

class ScheduleEditor extends StatelessWidget {
  final Map<String, String> schedule;
  final List<String> weekDays;
  final Function(String, String) onScheduleUpdate;
  final Function(String) onScheduleRemove;

  const ScheduleEditor({
    super.key,
    required this.schedule,
    required this.weekDays,
    required this.onScheduleUpdate,
    required this.onScheduleRemove,
  });

  Future<TimeOfDay?> _selectTime(BuildContext context) async {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: weekDays.length,
              itemBuilder: (context, index) {
                final day = weekDays[index];
                return ListTile(
                  title: Text(day.capitalize()),
                  subtitle: Text(schedule[day] ?? 'Not set'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.access_time),
                        onPressed: () async {
                          final startTime = await _selectTime(context);
                          if (startTime != null) {
                            final endTime = await _selectTime(context);
                            if (endTime != null) {
                              onScheduleUpdate(
                                day,
                                '${startTime.format(context)}-${endTime.format(context)}',
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => onScheduleRemove(day),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 