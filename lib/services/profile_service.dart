import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/profile.dart';

class ProfileService {
  static const String baseUrl = 'http://10.81.1.209:8000/api';

  Future<Profile> loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final username = prefs.getString('username');

    if (username == null) {
      throw Exception('Username not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/profile/$username/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      if (responseData['status'] == 'success' && responseData['data'] != null) {
        final userData = responseData['data'];

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

        // Handle group organizer specific fields
        String groupName = '';
        String activityType = '';
        String schedule = '';
        if (userData['role'] == 'group_organizer') {
          groupName = userData['group_name'] ?? '';
          activityType = userData['activity_type'] ?? '';
          schedule = userData['schedule'] ?? '';
        }

        return Profile(
          userId: username,
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
          groupName: groupName,
          activityType: activityType,
          schedule: schedule,
        );
      } else {
        throw Exception('Invalid profile data format');
      }
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }

  List<String> _parseWorkoutPreferences(dynamic preferences) {
    if (preferences == null) return [];

    Set<String> uniquePreferences = {};

    try {
      if (preferences is List) {
        for (var pref in preferences) {
          if (pref is String) {
            if (pref.startsWith('[')) {
              // Parse nested JSON string
              List<dynamic> parsed = jsonDecode(pref);
              uniquePreferences.addAll(parsed.map((p) => p.toString()));
            } else {
              uniquePreferences.add(pref);
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing workout preferences: $e');
    }

    // Capitalize each preference
    return uniquePreferences
        .map((pref) => pref
            .toString()
            .trim()
            .split(' ')
            .map((word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                : '')
            .join(' '))
        .toList();
  }
}
