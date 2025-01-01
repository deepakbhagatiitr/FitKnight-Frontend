import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';
import '../utils/string_extensions.dart';

class EditProfilePage extends StatefulWidget {
  final Profile profile;

  const EditProfilePage({super.key, required this.profile});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  File? _newProfileImage;
  final _picker = ImagePicker();
  bool _isLoading = false;
  late bool _showEmail;
  late bool _showPhone;
  late bool _showLocation;
  final List<String> _workoutOptions = [
    'Gym',
    'Yoga',
    'Running',
    'Swimming',
    'Cycling',
    'CrossFit',
    'Boxing',
  ];
  late List<String> _selectedWorkoutPreferences;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _bioController = TextEditingController(text: widget.profile.bio);
    _emailController =
        TextEditingController(text: widget.profile.contactInfo['email']);
    _phoneController =
        TextEditingController(text: widget.profile.contactInfo['phone']);
    _locationController =
        TextEditingController(text: widget.profile.contactInfo['location']);
    _showEmail = widget.profile.privacySettings['showEmail'] ?? true;
    _showPhone = widget.profile.privacySettings['showPhone'] ?? true;
    _showLocation = widget.profile.privacySettings['showLocation'] ?? true;
    _selectedWorkoutPreferences = List.from(widget.profile.workoutPreferences);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _newProfileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('userId');

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://192.168.31.36:8000/api/profile/$userId/'),
      );

      request.headers.addAll({
        'Authorization': 'Token $token',
      });

      // Create privacy settings map
      final privacySettings = {
        'showEmail': _showEmail,
        'showPhone': _showPhone,
        'showLocation': _showLocation,
      };

      // Save privacy settings to SharedPreferences immediately
      await prefs.setBool('showEmail', _showEmail);
      await prefs.setBool('showPhone', _showPhone);
      await prefs.setBool('showLocation', _showLocation);

      final Map<String, String> requestFields = {
        'username': _nameController.text.trim(),
        'fitness_goals': _bioController.text.trim(),
        'email': _emailController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'user_location': _locationController.text.trim(),
        'workout_preferences': jsonEncode(
            _selectedWorkoutPreferences.map((e) => e.toLowerCase()).toList()),
        'privacy_settings': jsonEncode(privacySettings),
      };

      request.fields.addAll(requestFields);

      if (_newProfileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            _newProfileImage!.path,
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData);

        String imageUrl = jsonResponse['profile_image'] ?? '';
        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          imageUrl = 'http://192.168.31.36:8000$imageUrl';
        }

        final updatedProfile = Profile(
          userId: widget.profile.userId,
          name: jsonResponse['username'] ?? '',
          bio: jsonResponse['fitness_goals'] ?? '',
          imageUrl: imageUrl,
          workoutPreferences: jsonResponse['workout_preferences'] != null
              ? List<String>.from((jsonResponse['workout_preferences'] as List)
                  .map((e) => e.toString().capitalize()))
              : [],
          contactInfo: {
            'email': jsonResponse['email'] ?? '',
            'phone': jsonResponse['phone_number'] ?? '',
            'location': jsonResponse['user_location'] ?? '',
          },
          privacySettings: privacySettings, // Use the local privacy settings
          fitnessHistory: widget.profile.fitnessHistory,
          groupGoals: widget.profile.groupGoals,
          groupActivities: widget.profile.groupActivities,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, updatedProfile);
        }
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateProfile,
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
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _newProfileImage != null
                          ? FileImage(_newProfileImage!)
                          : (widget.profile.imageUrl.isNotEmpty
                              ? NetworkImage(
                                  widget.profile.imageUrl.startsWith('http')
                                      ? widget.profile.imageUrl
                                      : 'http://192.168.31.36:8000${widget.profile.imageUrl}',
                                )
                              : null) as ImageProvider?,
                      child: _newProfileImage == null &&
                              widget.profile.imageUrl.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  icon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              if (widget.profile.role != 'group_organizer') ...[
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    icon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  icon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  icon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  icon: Icon(Icons.location_on),
                ),
              ),
              if (widget.profile.role != 'group_organizer') ...[
                const SizedBox(height: 24),
                const Text(
                  'Workout Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _workoutOptions.map((workout) {
                    return FilterChip(
                      label: Text(workout),
                      selected: _selectedWorkoutPreferences.contains(workout),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedWorkoutPreferences.add(workout);
                          } else {
                            _selectedWorkoutPreferences.remove(workout);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Privacy Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Show Email'),
                value: _showEmail,
                onChanged: (bool value) {
                  setState(() {
                    _showEmail = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Show Phone Number'),
                value: _showPhone,
                onChanged: (bool value) {
                  setState(() {
                    _showPhone = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Show Location'),
                value: _showLocation,
                onChanged: (bool value) {
                  setState(() {
                    _showLocation = value;
                  });
                },
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
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
