import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({Key? key}) : super(key: key);

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _activityTypeController = TextEditingController();
  final _locationController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _descriptionController = TextEditingController();
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

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final Map<String, String> requestBody = {
        'name': _nameController.text.trim(),
        'activity_type': _activityTypeController.text.trim(),
        'schedule': _scheduleController.text.trim(),
        'description': _descriptionController.text.trim(),
      };

      final response = await http.post(
        Uri.parse('http://10.81.93.48:8000/api/groups/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            'Failed to create group: ${errorData['error'] ?? response.body}');
      }
    } catch (e) {
      print('Error creating group: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Group'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Group Details',
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
                                  : activityTypes.contains(
                                          _activityTypeController.text)
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
                              validator: (value) =>
                                  value == null || value.isEmpty
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
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _scheduleController.text.isEmpty
                                  ? null
                                  : scheduleOptions
                                          .contains(_scheduleController.text)
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
                              validator: (value) =>
                                  value == null || value.isEmpty
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
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _createGroup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Create Group',
                        style: TextStyle(fontSize: 16),
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
    _activityTypeController.dispose();
    _locationController.dispose();
    _scheduleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
