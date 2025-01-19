import 'package:flutter/material.dart';

class GroupOrganizerForm extends StatelessWidget {
  final TextEditingController groupNameController;
  final TextEditingController activityTypeController;
  final TextEditingController scheduleController;
  final TextEditingController descriptionController;

  static const List<String> activityTypes = [
    'Boxing',
    'Judo',
    'Kickboxing',
    'Muay Thai',
    'Sambo',
    'Karate',
    'Taekwondo',
    'Kung Fu',
    'Aikido',
  ];

  static const List<String> scheduleOptions = [
    'Morning',
    'Afternoon',
    'Evening',
  ];

  const GroupOrganizerForm({
    super.key,
    required this.groupNameController,
    required this.activityTypeController,
    required this.scheduleController,
    required this.descriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: groupNameController,
          decoration: InputDecoration(
            labelText: 'Group Name',
            hintText: 'Enter your group name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) =>
              value!.isEmpty ? 'Please enter a group name' : null,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: activityTypeController.text.isEmpty
              ? null
              : activityTypeController.text,
          decoration: InputDecoration(
            labelText: 'Activity Type',
            hintText: 'Select activity type',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: activityTypes.map((String type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          validator: (value) => value == null || value.isEmpty
              ? 'Please select activity type'
              : null,
          onChanged: (String? newValue) {
            if (newValue != null) {
              activityTypeController.text = newValue;
            }
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value:
              scheduleController.text.isEmpty ? null : scheduleController.text,
          decoration: InputDecoration(
            labelText: 'Schedule',
            hintText: 'Select group schedule',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: scheduleOptions.map((String schedule) {
            return DropdownMenuItem<String>(
              value: schedule,
              child: Text(schedule),
            );
          }).toList(),
          validator: (value) =>
              value == null || value.isEmpty ? 'Please select schedule' : null,
          onChanged: (String? newValue) {
            if (newValue != null) {
              scheduleController.text = newValue;
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Enter group description',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) =>
              value!.isEmpty ? 'Please enter a description' : null,
        ),
      ],
    );
  }
}
