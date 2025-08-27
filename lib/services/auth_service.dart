import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/signup_form_data.dart';
import '../models/user_role.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'package:flutter/material.dart';

// Custom exception for user not found
class UserNotFoundException implements Exception {
  final String message;
  UserNotFoundException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  static const String baseUrl = 'https://fitness-backend-km9x.onrender.com/api';
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  Future<Map<String, dynamic>> login(
      BuildContext context, String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username.trim(),
          'password': password.trim(),
        }),
      );

      final data = json.decode(response.body);
      print('Login response: $data');

      if (data['status'] == 'success') {
        final userId = data['user']?['id']?.toString() ?? '';
        final userData = data['user'] as Map<String, dynamic>;
        final username = userData['username'] as String;
        final userType = userData['userType'] as String;

        final normalizedUserType =
            userType.toLowerCase() == 'buddy' ? 'buddy' : 'group';

        // Saving user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token'] ?? '');
        await prefs.setString('userType', normalizedUserType);
        await prefs.setString('userId', userId);
        await prefs.setString('username', username);

        if (data['profile_image'] != null) {
          await prefs.setString('profileImage', data['profile_image']);
        }
        if (data['fitness_goals'] != null) {
          await prefs.setString('fitnessGoals', data['fitness_goals']);
        }
        if (data['workout_preferences'] != null) {
          await prefs.setString(
              'workoutPreferences', json.encode(data['workout_preferences']));
        }
        if (data['availability'] != null) {
          await prefs.setString('availability', data['availability']);
        }
        if (data['user_location'] != null) {
          await prefs.setString('location', data['user_location']);
        }

        Provider.of<NotificationProvider>(context, listen: false)
            .initialize(data['token'] ?? '');

        return data;
      } else {
        final message = data['message'] ?? 'Login failed';

        if (message.toLowerCase().contains('not registered') ||
            message.toLowerCase().contains('user is not registered')) {
          throw UserNotFoundException(
              'User is not registered. Please sign up first.');
        }

        if (message.toLowerCase().contains('invalid username or password')) {
          throw Exception('Invalid username or password. Please try again.');
        }

        throw Exception(message);
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<void> signup(SignupFormData formData) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/register/'),
    );

    final Map<String, String> fields = {
      'username': formData.username,
      'email': formData.email,
      'password': formData.password,
      'password_confirm': formData.passwordConfirm,
      'phone_number': formData.phoneNumber.replaceAll(RegExp(r'[^0-9]'), ''),
      'user_location': formData.location,
      'role': formData.role == UserRole.workoutBuddy
          ? 'workout_buddy'
          : 'group_organizer',
    };

    if (formData.role == UserRole.workoutBuddy) {
      fields.addAll({
        'fitness_goals': formData.fitnessGoals ?? '',
        'workout_preferences': jsonEncode(formData.workoutPreferences),
        'availability': formData.availability ?? '',
      });
    } else {
      fields.addAll({
        'group_name': formData.groupName ?? '',
        'activity_type': formData.activityType ?? '',
        'schedule': formData.schedule ?? '',
        'description': formData.description ?? '',
      });
    }

    request.fields.addAll(fields);

    if (formData.profileImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image',
          formData.profileImage!.path,
        ),
      );
    }

    try {
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode != 201) {
        final errorData = jsonDecode(responseData);
        throw Exception(errorData['message'] ??
            errorData.entries.map((e) => '${e.key}: ${e.value}').join(', ') ??
            'Registration failed');
      }

      if (formData.role == UserRole.groupOrganizer) {
        final responseJson = jsonDecode(responseData);
        final token = responseJson['token'];

        if (token != null) {
          final groupResponse = await http.post(
            Uri.parse('$baseUrl/groups/'),
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'name': formData.groupName,
              'activity_type': formData.activityType,
              'schedule': formData.schedule,
              'description': formData.description,
              'location': formData.location,
            }),
          );

          if (groupResponse.statusCode != 201) {
            throw Exception('Failed to create group: ${groupResponse.body}');
          }
        }
      }
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/logout/'),
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
        );
      } catch (e) {
        print('Error calling logout API: $e');
      }
    }

    await prefs.clear();
  }
}
