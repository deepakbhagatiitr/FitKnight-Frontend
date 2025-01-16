import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';

class ProfileService {
  static const String baseUrl = 'http://10.81.1.137:8000/api';

  Future<Profile> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    if (userId == null) {
      throw Exception('User ID not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/profile/$userId/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);

      final Map<String, String> contactInfo = {
        'email': (userData['email'] ?? '').toString(),
        'phone': (userData['phone_number'] ?? '').toString(),
        'location': (userData['user_location'] ?? '').toString(),
      };

      final Map<String, bool> privacySettings = {
        'showEmail': prefs.getBool('showEmail') ?? true,
        'showPhone': prefs.getBool('showPhone') ?? true,
        'showLocation': prefs.getBool('showLocation') ?? true,
      };

      String fitnessGoals = '';
      if (userData['fitness_goals'] != null) {
        try {
          if (userData['fitness_goals'] is String) {
            fitnessGoals = userData['fitness_goals'];
          } else {
            fitnessGoals = json.encode(userData['fitness_goals']);
          }
        } catch (e) {
          print('Error parsing fitness goals: $e');
          fitnessGoals = userData['fitness_goals']?.toString() ?? '';
        }
      }

      return Profile(
        userId: userId,
        name: userData['username'] ?? '',
        bio: fitnessGoals,
        imageUrl: userData['profile_image']?.toString() ?? '',
        workoutPreferences:
            _parseWorkoutPreferences(userData['workout_preferences']),
        contactInfo: contactInfo,
        privacySettings: privacySettings,
        fitnessHistory: [],
        groupGoals: [],
        groupActivities: [],
        role: userData['role'] ?? '',
      );
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }

  List<String> _parseWorkoutPreferences(dynamic preferences) {
    if (preferences == null) return [];
    try {
      if (preferences is List) {
        return List<String>.from(preferences.map((e) => e.toString()));
      }
    } catch (e) {
      print('Error parsing workout preferences: $e');
    }
    return [];
  }
}
