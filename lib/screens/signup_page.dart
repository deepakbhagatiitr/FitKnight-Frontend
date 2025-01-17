import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import '../models/user_role.dart';
import '../models/signup_form_data.dart';
import '../services/auth_service.dart';
import '../widgets/signup/profile_image_picker.dart';
import '../widgets/signup/basic_info_form.dart';
import '../widgets/signup/workout_buddy_form.dart';
import '../widgets/signup/group_organizer_form.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  final _fitnessGoalsController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _activityTypeController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _descriptionController = TextEditingController();

  // State variables
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  File? _profileImage;
  UserRole? _selectedRole;
  final List<String> _workoutPreferences = [];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _fitnessGoalsController.dispose();
    _availabilityController.dispose();
    _groupNameController.dispose();
    _activityTypeController.dispose();
    _scheduleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleWorkoutPreferenceChanged(String workout, bool selected) {
    setState(() {
      if (selected) {
        _workoutPreferences.add(workout);
      } else {
        _workoutPreferences.remove(workout);
      }
    });
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
        final formData = SignupFormData(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          passwordConfirm: _confirmPasswordController.text,
          phoneNumber: _phoneController.text,
          location: _locationController.text,
          role: _selectedRole,
          profileImage: _profileImage,
          fitnessGoals: _fitnessGoalsController.text,
          workoutPreferences: _workoutPreferences,
          availability: _availabilityController.text,
          groupName: _groupNameController.text,
          activityType: _activityTypeController.text,
          schedule: _scheduleController.text,
          description: _descriptionController.text,
        );

        await _authService.signup(formData);

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
      } catch (e) {
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
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Image Picker
                ProfileImagePicker(
                  profileImage: _profileImage,
                  onImagePicked: (File image) {
                    setState(() => _profileImage = image);
                  },
                ),
                const SizedBox(height: 16),

                // Basic Information Form
                BasicInfoForm(
                  usernameController: _usernameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  phoneController: _phoneController,
                  locationController: _locationController,
                  isPasswordVisible: _isPasswordVisible,
                  isConfirmPasswordVisible: _isConfirmPasswordVisible,
                  onPasswordVisibilityChanged: (value) {
                    setState(() => _isPasswordVisible = value);
                  },
                  onConfirmPasswordVisibilityChanged: (value) {
                    setState(() => _isConfirmPasswordVisible = value);
                  },
                ),
                const SizedBox(height: 16),

                // Role Selection
                const Text(
                  'Select Your Role',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<UserRole>(
                        title: const Text('Workout Buddy'),
                        value: UserRole.workoutBuddy,
                        groupValue: _selectedRole,
                        onChanged: (UserRole? value) {
                          setState(() => _selectedRole = value);
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<UserRole>(
                        title: const Text('Group Organizer'),
                        value: UserRole.groupOrganizer,
                        groupValue: _selectedRole,
                        onChanged: (UserRole? value) {
                          setState(() => _selectedRole = value);
                        },
                      ),
                    ),
                  ],
                ),

                // Role-specific forms
                if (_selectedRole == UserRole.workoutBuddy)
                  WorkoutBuddyForm(
                    fitnessGoalsController: _fitnessGoalsController,
                    availabilityController: _availabilityController,
                    workoutPreferences: _workoutPreferences,
                    onWorkoutPreferenceChanged: _handleWorkoutPreferenceChanged,
                  )
                else if (_selectedRole == UserRole.groupOrganizer)
                  GroupOrganizerForm(
                    groupNameController: _groupNameController,
                    activityTypeController: _activityTypeController,
                    scheduleController: _scheduleController,
                    descriptionController: _descriptionController,
                  ),

                const SizedBox(height: 24),

                // Sign Up Button
                FilledButton(
                  onPressed: _handleSignUp,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Sign Up', style: TextStyle(fontSize: 16)),
                ),

                const SizedBox(height: 16),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
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
    );
  }
}
