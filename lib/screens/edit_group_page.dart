import 'package:flutter/material.dart';
import '../services/group_management_service.dart';
import '../widgets/group/schedule_editor.dart';

class EditGroupPage extends StatefulWidget {
  final int groupId;
  final String currentName;
  final String currentDescription;
  final String currentActivityType;
  final Map<String, String> currentSchedule;

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
  final _groupService = GroupManagementService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _activityTypeController;

  bool _isLoading = false;
  Map<String, String> _schedule = {};

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

  final List<String> _weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _descriptionController =
        TextEditingController(text: widget.currentDescription);
    _activityTypeController =
        TextEditingController(text: widget.currentActivityType);
    _schedule = Map.from(widget.currentSchedule);
  }

  Future<void> _updateGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      _schedule.removeWhere((key, value) => value.isEmpty);

      final Map<String, dynamic> requestBody = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'activity_type': _activityTypeController.text.trim(),
        'schedule': _schedule,
      };


      await _groupService.updateGroup(widget.groupId, requestBody);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
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
              _buildBasicInfoCard(),
              const SizedBox(height: 16),
              ScheduleEditor(
                schedule: _schedule,
                weekDays: _weekDays,
                onScheduleUpdate: (day, time) {
                  setState(() => _schedule[day] = time);
                },
                onScheduleRemove: (day) {
                  setState(() => _schedule.remove(day));
                },
              ),
              const SizedBox(height: 16),
              _buildDescriptionCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
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
                  : activityTypes.contains(_activityTypeController.text)
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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _schedule['default']?.isEmpty ?? true
                  ? null
                  : scheduleOptions.contains(_schedule['default'])
                      ? _schedule['default']
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
                    _schedule['default'] = newValue;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
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
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _activityTypeController.dispose();
    super.dispose();
  }
}
