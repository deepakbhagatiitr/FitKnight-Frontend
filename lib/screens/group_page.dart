import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'group_details_page.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _groups = [];
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('\n=== Loading Groups ===');
      final response = await http.get(
        Uri.parse('http://192.168.31.36:8000/api/groups/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _groups = data.map((group) {
            String imageUrl = group['group_image'] ?? '';
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = 'http://192.168.31.36:8000$imageUrl';
            }

            return {
              'id': group['id'],
              'name': group['name'] ?? '',
              'activity': group['activity_type'] ?? '',
              'members': group['member_count'] ?? 0,
              'location': group['location'] ?? '',
              'image': imageUrl,
              'schedule': group['schedule'] ?? '',
              'description': group['description'] ?? '',
              'created_at': group['created_at'] ?? '',
              'updated_at': group['updated_at'] ?? '',
              'organizer_name': group['organizer_name'] ?? '',
              'is_organizer': group['is_organizer'] ?? false,
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load groups: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading groups: $e');
      setState(() {
        _error = 'Failed to load groups';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredGroups() {
    if (_searchQuery.isEmpty) return _groups;

    return _groups.where((group) {
      final name = group['name'].toString().toLowerCase();
      final activity = group['activity'].toString().toLowerCase();
      final location = group['location'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) ||
          activity.contains(query) ||
          location.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredGroups = _getFilteredGroups();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Groups'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroups,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search groups by name, activity, or location',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Groups List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!,
                                  style: const TextStyle(color: Colors.red)),
                              TextButton(
                                onPressed: _loadGroups,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : filteredGroups.isEmpty
                          ? const Center(
                              child: Text('No groups found'),
                            )
                          : ListView.builder(
                              itemCount: filteredGroups.length,
                              itemBuilder: (context, index) {
                                final group = filteredGroups[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 16),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      radius: 30,
                                      backgroundImage:
                                          group['image']?.isNotEmpty ?? false
                                              ? NetworkImage(group['image'])
                                              : null,
                                      child: group['image']?.isEmpty ?? true
                                          ? const Icon(Icons.group, size: 30)
                                          : null,
                                    ),
                                    title: Text(
                                      group['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.fitness_center,
                                                size: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary),
                                            const SizedBox(width: 4),
                                            Text(group['activity']),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                size: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary),
                                            const SizedBox(width: 4),
                                            Text(group['location']),
                                          ],
                                        ),
                                        if (group['schedule']?.isNotEmpty ??
                                            false) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.schedule,
                                                  size: 16,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondary),
                                              const SizedBox(width: 4),
                                              Text(group['schedule']),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${group['members']}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                        const Text('members'),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              GroupDetailsPage(
                                            group: group,
                                            groupId: group['id'].toString(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
