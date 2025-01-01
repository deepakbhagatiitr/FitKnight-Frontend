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

      final Map<String, String> requestBody = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'activity_type': _activityTypeController.text.trim(),
        'schedule': _scheduleController.text.trim(),
      };

      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('http://192.168.31.36:8000/api/groups/${widget.groupId}/'),
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
                      TextFormField(
                        controller: _activityTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Activity Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.sports),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an activity type';
                          }
                          return null;
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
                      TextFormField(
                        controller: _scheduleController,
                        decoration: const InputDecoration(
                          labelText: 'Schedule',
                          hintText:
                              'e.g., Monday, Wednesday, Friday 6:00 AM - 7:00 AM',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a schedule';
                          }
                          return null;
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
