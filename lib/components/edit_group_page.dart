import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EditGroupPage extends StatefulWidget {
  final Map<String, dynamic> group;

  const EditGroupPage({super.key, required this.group});

  @override
  State<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  String? _selectedActivity;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group['name']);
    _locationController = TextEditingController(text: widget.group['location']);
    _selectedActivity = widget.group['activity'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Group'),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Implement save functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Changes saved!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedActivity,
            decoration: const InputDecoration(
              labelText: 'Activity',
              border: OutlineInputBorder(),
            ),
            items: ['Yoga', 'CrossFit', 'Weight Training', 'Pilates', 'Gym']
                .map((activity) => DropdownMenuItem(
                      value: activity,
                      child: Text(activity),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedActivity = value),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
