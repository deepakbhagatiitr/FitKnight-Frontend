import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserRole {
  workoutBuddy,
  groupOrganizer,
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  File? _profileImage;
  final _picker = ImagePicker();
  UserRole? _selectedRole;

  final _fitnessGoalsController = TextEditingController();
  final List<String> _workoutPreferences = [];
  final _availabilityController = TextEditingController();

  final _groupNameController = TextEditingController();
  final _activityTypeController = TextEditingController();
  final _locationController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _phoneController = TextEditingController();

  final List<String> _workoutOptions = [
    'Gym',
    'Yoga',
    'Running',
    'Swimming',
    'Cycling',
    'CrossFit',
    'Boxing',
  ];

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fitnessGoalsController.dispose();
    _availabilityController.dispose();
    _groupNameController.dispose();
    _activityTypeController.dispose();
    _locationController.dispose();
    _scheduleController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a role')),
        );
        return;
      }

      if (_selectedRole == UserRole.workoutBuddy &&
          _workoutPreferences.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select at least one workout preference')),
        );
        return;
      }

      try {
        print('\n=== Signup Request ===');
        print('URL: http://192.168.31.36:8000/api/register/');

        // Create multipart request
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('http://192.168.31.36:8000/api/register/'),
        );

        // Add common fields
        request.fields.addAll({
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'password_confirm': _confirmPasswordController.text,
          'phone_number':
              _phoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          'user_location': _locationController.text,
          'role': _selectedRole == UserRole.workoutBuddy
              ? 'workout_buddy'
              : 'group_organizer',
        });

        // Add role-specific fields
        if (_selectedRole == UserRole.workoutBuddy) {
          request.fields.addAll({
            'fitness_goals': _fitnessGoalsController.text,
            'workout_preferences': jsonEncode(
                _workoutPreferences.map((e) => e.toLowerCase()).toList()),
            'availability': _availabilityController.text,
          });
        } else {
          request.fields.addAll({
            'group_name': _groupNameController.text,
            'activity_type': _activityTypeController.text,
            'schedule': _scheduleController.text,
            'description': _descriptionController.text,
          });
        }

        // Add profile image if selected
        if (_profileImage != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'profile_image',
              _profileImage!.path,
            ),
          );
        }

        print('Request Fields:');
        request.fields.forEach((key, value) {
          print('  $key: $value');
        });

        final response = await request.send();
        final responseData = await response.stream.bytesToString();

        print('\n=== Response ===');
        print('Status Code: ${response.statusCode}');
        print('Response Body: $responseData');

        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sign up successful! Please login.'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        } else {
          final errorData = jsonDecode(responseData);
          throw Exception(errorData['message'] ?? 'Registration failed');
        }
      } catch (e) {
        print('Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      if (_profileImage != null)
                        Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: FileImage(_profileImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_a_photo),
                        label: Text(_profileImage == null
                            ? 'Upload Profile Picture'
                            : 'Change Profile Picture'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Choose a unique username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      if (value.contains(' ')) {
                        return 'Username cannot contain spaces';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      hintText: 'Enter 10-digit phone number',
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      final phoneNumber =
                          value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (phoneNumber.length != 10) {
                        return 'Phone number must be exactly 10 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Confirm your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Your Role',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<UserRole>(
                          title: const Text('Workout Buddy'),
                          value: UserRole.workoutBuddy,
                          groupValue: _selectedRole,
                          onChanged: (UserRole? value) {
                            setState(() {
                              _selectedRole = value;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<UserRole>(
                          title: const Text('Group Organizer'),
                          value: UserRole.groupOrganizer,
                          groupValue: _selectedRole,
                          onChanged: (UserRole? value) {
                            setState(() {
                              _selectedRole = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_selectedRole != null) ...[
                    const SizedBox(height: 16),
                  ],
                  if (_selectedRole == UserRole.workoutBuddy) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fitnessGoalsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Fitness Goals',
                        hintText: 'Describe your fitness goals',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'Please describe your fitness goals'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Workout Preferences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the types of workouts you\'re interested in:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _workoutOptions.map((workout) {
                        return FilterChip(
                          label: Text(workout),
                          selected: _workoutPreferences.contains(workout),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _workoutPreferences.add(workout);
                              } else {
                                _workoutPreferences.remove(workout);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (_workoutPreferences.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Please select at least one workout preference',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _availabilityController,
                      decoration: InputDecoration(
                        labelText: 'Availability',
                        hintText: 'Enter your workout availability',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'Please enter your availability'
                          : null,
                    ),
                  ],
                  if (_selectedRole == UserRole.groupOrganizer) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _groupNameController,
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
                      controller: _activityTypeController,
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
                      controller: _scheduleController,
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
                      controller: _descriptionController,
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
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _handleSignUp,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
