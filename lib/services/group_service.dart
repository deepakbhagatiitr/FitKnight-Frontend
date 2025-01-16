import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/group_details.dart';
import '../models/group.dart';
import '../models/member.dart';

class GroupService {
  static const String _baseUrl = 'http://10.81.1.137:8000/api';

  Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Authentication required');
    }
    return token;
  }

  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  Future<List<Group>> loadManagedGroups() async {
    final token = await _getAuthToken();
    final username = await getCurrentUsername();

    if (username == null) {
      throw Exception('Authentication required');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/groups/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .where((group) => group['organizer_name'] == username)
          .map((group) => Group.fromJson(group))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expired');
    } else {
      throw Exception('Failed to load groups: ${response.statusCode}');
    }
  }

  Future<List<Member>> loadPotentialMembers() async {
    final token = await _getAuthToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/profile/?role=workout_buddy'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> profiles = data['results'] ?? [];
      return profiles.map((profile) => Member.fromJson(profile)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session expired');
    } else {
      throw Exception('Failed to load members: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchGroupDetails(String groupId) async {
    final token = await _getAuthToken();
    final username = await getCurrentUsername();

    if (username == null) {
      throw Exception('Authentication required');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/groups/$groupId/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final organizerUsername = data['organizer_name'] ?? '';
      final members = (data['members'] as List<dynamic>? ?? [])
          .map((member) => GroupMember.fromJson(member, organizerUsername))
          .toList();

      final isMember = members.any((member) => member.username == username);
      final isOrganizer = username == organizerUsername;

      return {
        'details': GroupDetails.fromJson(data, username),
        'members': members,
        'isOrganizerOrMember': isOrganizer || isMember,
      };
    } else {
      throw Exception('Failed to load group details: ${response.statusCode}');
    }
  }

  Future<String?> checkJoinRequestStatus(String groupId) async {
    try {
      final token = await _getAuthToken();

      final response = await http.get(
        Uri.parse('$_baseUrl/groups/$groupId/request-join/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          if (data['is_organizer']) {
            return null; // Organizers don't have join request status
          }

          final request = data['request'];
          if (request != null) {
            final status = request['status']?.toString().toLowerCase();
            print('Join request status: $status');
            return status;
          }
        }
        return null;
      }
      return null;
    } catch (e) {
      print('Error checking join request status: $e');
      return null;
    }
  }

  Future<void> sendJoinRequest(String groupId) async {
    final token = await _getAuthToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/groups/$groupId/request-join/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);
    if (data['status'] == 'error') {
      throw Exception(data['message']);
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send join request');
    }
  }

  Future<List<JoinRequest>> fetchJoinRequests(String groupId) async {
    final token = await _getAuthToken();

    final response = await http.get(
      Uri.parse('$_baseUrl/groups/$groupId/request-join/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['is_organizer']) {
        final List<dynamic> requests = data['requests'];
        return requests
            .map((request) => JoinRequest.fromJson(request))
            .toList();
      }
      return [];
    } else {
      throw Exception('Failed to load join requests: ${response.statusCode}');
    }
  }

  Future<void> handleJoinRequest(
      String groupId, String username, String action) async {
    final token = await _getAuthToken();

    final response = await http.post(
      Uri.parse('$_baseUrl/groups/$groupId/requests/$username/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'action': action}),
    );

    final data = jsonDecode(response.body);
    if (data['status'] == 'error') {
      throw Exception(data['message']);
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to $action request: ${response.statusCode}');
    }

    // Wait for a moment to ensure the notification is processed
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
