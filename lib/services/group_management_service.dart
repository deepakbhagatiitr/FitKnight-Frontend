import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GroupManagementService {
  static const String baseUrl = 'http://10.81.93.48:8000/api';

  Future<void> updateGroup(
    int groupId,
    Map<String, dynamic> requestBody,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Not authenticated');
    }

    // Update group
    final groupResponse = await http.put(
      Uri.parse('$baseUrl/groups/$groupId/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    print('Group Update Response Status: ${groupResponse.statusCode}');
    print('Group Update Response Body: ${groupResponse.body}');

    if (groupResponse.statusCode != 200) {
      throw Exception('Failed to update group: ${groupResponse.body}');
    }

    // Update organizer profile with the same details
    final profileResponse = await http.put(
      Uri.parse('$baseUrl/profile/update/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'group_name': requestBody['name'],
        'activity_type': requestBody['activity_type'],
        'schedule': requestBody['schedule'],
        'description': requestBody['description'],
      }),
    );

    print('Profile Update Response Status: ${profileResponse.statusCode}');
    print('Profile Update Response Body: ${profileResponse.body}');

    if (profileResponse.statusCode != 200) {
      print(
          'Warning: Failed to update organizer profile: ${profileResponse.body}');
      // Don't throw an error here as the group update was successful
    }
  }
}
