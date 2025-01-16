import 'dart:io';
import 'user_role.dart';

class SignupFormData {
  String username;
  String email;
  String password;
  String passwordConfirm;
  String phoneNumber;
  String location;
  UserRole? role;
  File? profileImage;
  
  // Workout Buddy specific fields
  String? fitnessGoals;
  List<String> workoutPreferences;
  String? availability;
  
  // Group Organizer specific fields
  String? groupName;
  String? activityType;
  String? schedule;
  String? description;

  SignupFormData({
    this.username = '',
    this.email = '',
    this.password = '',
    this.passwordConfirm = '',
    this.phoneNumber = '',
    this.location = '',
    this.role,
    this.profileImage,
    this.fitnessGoals,
    this.workoutPreferences = const [],
    this.availability,
    this.groupName,
    this.activityType,
    this.schedule,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'username': username,
      'email': email,
      'password': password,
      'password_confirm': passwordConfirm,
      'phone_number': phoneNumber.replaceAll(RegExp(r'[^0-9]'), ''),
      'user_location': location,
      'role': role == UserRole.workoutBuddy ? 'workout_buddy' : 'group_organizer',
    };

    if (role == UserRole.workoutBuddy) {
      data.addAll({
        'fitness_goals': fitnessGoals,
        'workout_preferences': workoutPreferences,
        'availability': availability,
      });
    } else {
      data.addAll({
        'group_name': groupName,
        'activity_type': activityType,
        'schedule': schedule,
        'description': description,
      });
    }

    return data;
  }
} 