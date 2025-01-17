import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/buddy.dart';
import '../models/group.dart';

class BuddyFinderService {
  static const String baseUrl = 'http://10.81.1.137:8000/api';

  Future<List<Buddy>> loadRecommendedBuddies() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/profile/?role=workout_buddy&match_preferences=true'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('=== Recommended Buddies Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body:');
      final prettyJson =
          const JsonEncoder.withIndent('  ').convert(jsonDecode(response.body));
      print(prettyJson);
      print('===================================');

      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> data = jsonResponse['results'] ?? [];
      return data.map((profile) => Buddy.fromJson(profile)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expired');
    } else {
      print('Error Response:');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      throw Exception('Failed to load buddies: ${response.statusCode}');
    }
  }

  Future<List<Group>> loadFitnessGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/groups/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((group) => Group.fromJson(group)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expired');
    } else {
      throw Exception('Failed to load groups: ${response.statusCode}');
    }
  }

  Future<List<Group>> loadMyGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/my-groups/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status'] == 'success') {
        final List<dynamic> data = jsonResponse['groups'];
        return data.map((group) => Group.fromJson(group)).toList();
      }
      return [];
    } else if (response.statusCode == 401) {
      throw Exception('Session expired');
    } else {
      throw Exception('Failed to load groups: ${response.statusCode}');
    }
  }
}
