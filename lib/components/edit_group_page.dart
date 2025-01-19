import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EditGroupPage extends StatefulWidget {
  final int groupId;

  final String currentName;

  final String currentDescription;

  final String currentActivityType;

  final String currentSchedule;

  const EditGroupPage({
    Key? key,
    required this.groupId,
    required this.currentName,
    required this.currentDescription,
    required this.currentActivityType,
    required this.currentSchedule,
  }) : super(key: key);

  @override
  State<EditGroupPage> createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;

  late TextEditingController _descriptionController;

  late TextEditingController _activityTypeController;

  late TextEditingController _scheduleController;

  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.currentName);

    _descriptionController =
        TextEditingController(text: widget.currentDescription);

    _activityTypeController =
        TextEditingController(text: widget.currentActivityType);

    _scheduleController = TextEditingController(text: widget.currentSchedule);
  }

  Future<void> _updateGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final Map<String, dynamic> requestBody = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'activity_type': _activityTypeController.text.trim(),
        'schedule': _scheduleController.text.trim(),
      };

      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('http://10.81.88.76:8000/api/groups/${widget.groupId}/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (!mounted) return;

        // Refresh potential members
        final potentialMembersResponse = await http.get(
          Uri.parse(
              'http://10.81.88.76:8000/api/groups/${widget.groupId}/potential-members/'),
          headers: {
            'Authorization': 'Token $token',
          },
        );

        if (potentialMembersResponse.statusCode == 200) {
          print('Potential members refreshed successfully');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to update group: ${response.body}');
      }
    } catch (e) {
      print('Error updating group: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<TimeOfDay?> _selectTime(BuildContext context) async {
    return showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Group'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateGroup,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Group Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a group name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _activityTypeController.text.isEmpty
                            ? null
                            : activityTypes
                                    .contains(_activityTypeController.text)
                                ? _activityTypeController.text
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'Activity Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.sports),
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
                            setState(() {
                              _activityTypeController.text = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
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
                      DropdownButtonFormField<String>(
                        value: _scheduleController.text.isEmpty
                            ? null
                            : scheduleOptions.contains(_scheduleController.text)
                                ? _scheduleController.text
                                : null,
                        decoration: const InputDecoration(
                          labelText: 'Schedule',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: scheduleOptions.map((String schedule) {
                          return DropdownMenuItem<String>(
                            value: schedule,
                            child: Text(schedule),
                          );
                        }).toList(),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please select schedule'
                            : null,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _scheduleController.text = newValue;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Group Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();

    _descriptionController.dispose();

    _activityTypeController.dispose();

    _scheduleController.dispose();

    super.dispose();
  }
}
