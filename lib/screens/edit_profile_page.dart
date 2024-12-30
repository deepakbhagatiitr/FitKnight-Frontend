import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';

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
  List<String> _selectedFitnessGoals = [];
  bool _showEmail = true;
  bool _showPhone = true;
  bool _showLocation = true;

  final List<String> _availableFitnessGoals = [
    'Weight Loss',
    'Muscle Gain',
    'Cardio',
    'Flexibility',
    'Strength Training',
    'Endurance',
    'General Fitness',
  ];

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
    _selectedFitnessGoals = List.from(widget.profile.fitnessGoals);

    // Initialize privacy settings
    _showEmail = widget.profile.privacySettings['showEmail'] ?? true;
    _showPhone = widget.profile.privacySettings['showPhone'] ?? true;
    _showLocation = widget.profile.privacySettings['showLocation'] ?? true;
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

      print('\n=== Update Profile Request ===');
      print('URL: http://192.168.31.36:8000/api/profile/$userId/');

      // Create multipart request
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('http://192.168.31.36:8000/api/profile/$userId/'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Token $token',
      });

      // Add text fields
      request.fields.addAll({
        'username': _nameController.text,
        'bio': _bioController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'location': _locationController.text,
        'fitness_goals': jsonEncode(_selectedFitnessGoals),
        'privacy_settings': jsonEncode({
          'showEmail': _showEmail,
          'showPhone': _showPhone,
          'showLocation': _showLocation,
        }),
      });

      // Add new profile image if selected
      if (_newProfileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            _newProfileImage!.path,
          ),
        );
      }

      print('Request Fields:');
      request.fields.forEach((key, value) {
        print('$key: $value');
      });

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('\n=== Update Profile Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: $responseData');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseData);

        // Parse fitness goals properly
        List<String> fitnessGoals = [];
        try {
          if (jsonResponse['fitness_goals'] != null) {
            // If it's a string, decode it first
            if (jsonResponse['fitness_goals'] is String) {
              fitnessGoals =
                  List<String>.from(jsonDecode(jsonResponse['fitness_goals']));
            } else {
              fitnessGoals = List<String>.from(jsonResponse['fitness_goals']);
            }
          }
        } catch (e) {
          print('Error parsing fitness goals: $e');
        }

        // Construct full image URL
        String imageUrl = jsonResponse['profile_image'] ?? '';
        if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          imageUrl = 'http://192.168.31.36:8000$imageUrl';
        }

        // Create updated profile
        final updatedProfile = Profile(
          userId: widget.profile.userId,
          name: jsonResponse['username'] ?? '',
          bio: jsonResponse['fitness_goals'] ?? '',
          imageUrl: imageUrl, // Use the constructed full URL
          fitnessGoals: fitnessGoals, // Use the parsed fitness goals
          contactInfo: {
            'email': jsonResponse['email'] ?? '',
            'phone': jsonResponse['phone'] ?? '',
            'location': jsonResponse['location'] ?? '',
          },
          privacySettings: {
            'showEmail': jsonResponse['privacy_settings']?['showEmail'] ?? true,
            'showPhone': jsonResponse['privacy_settings']?['showPhone'] ?? true,
            'showLocation':
                jsonResponse['privacy_settings']?['showLocation'] ?? true,
          },
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
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateProfile,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
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
                    ),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(_newProfileImage == null
                          ? 'Change Profile Picture'
                          : 'Change Selected Picture'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Info Section
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  icon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Fitness Goals',
                  icon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Contact Information Section with Privacy Settings
              Text(
                'Contact Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        icon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  Switch(
                    value: _showEmail,
                    onChanged: (value) {
                      setState(() => _showEmail = value);
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        icon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  Switch(
                    value: _showPhone,
                    onChanged: (value) {
                      setState(() => _showPhone = value);
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        icon: Icon(Icons.location_on),
                      ),
                    ),
                  ),
                  Switch(
                    value: _showLocation,
                    onChanged: (value) {
                      setState(() => _showLocation = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Fitness Goals Section
              Text(
                'Workout Preferences',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableFitnessGoals.map((goal) {
                  final isSelected = _selectedFitnessGoals.contains(goal);
                  return FilterChip(
                    label: Text(goal),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFitnessGoals.add(goal);
                        } else {
                          _selectedFitnessGoals.remove(goal);
                        }
                      });
                    },
                  );
                }).toList(),
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
