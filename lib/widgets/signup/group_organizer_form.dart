import 'package:flutter/material.dart';

class GroupOrganizerForm extends StatelessWidget {
  final TextEditingController groupNameController;
  final TextEditingController activityTypeController;
  final TextEditingController scheduleController;
  final TextEditingController descriptionController;

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
        TextFormField(
          controller: activityTypeController,
          decoration: InputDecoration(
            labelText: 'Activity Type',
            hintText: 'Enter the type of activities',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) =>
              value!.isEmpty ? 'Please enter activity type' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: scheduleController,
          decoration: InputDecoration(
            labelText: 'Schedule',
            hintText: 'Enter group schedule',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) =>
              value!.isEmpty ? 'Please enter schedule' : null,
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