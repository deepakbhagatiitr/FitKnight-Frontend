import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/edit_group_page.dart';
import '../components/organizer_chat.dart';
import '../components/group_chat.dart';

class GroupDetailsPage extends StatefulWidget {
  final Map<String, dynamic> group;
  String groupId;
  final bool isOrganizer;

  GroupDetailsPage({
    super.key,
    required this.group,
    required this.groupId,
    this.isOrganizer = false,
  });

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _groupDetails;
  List<Map<String, dynamic>> _members = [];
  String? _error;
  TabController? _tabController;
  List<Map<String, dynamic>> _joinRequests = [];
  String? _joinRequestStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isOrganizer ? 4 : 3,
      vsync: this,
    );
    _loadGroupDetails();
    if (widget.isOrganizer) {
      _loadJoinRequests();
    } else {
      _checkJoinRequestStatus();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadGroupDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final username = prefs.getString('username');

      print('\n=== Loading Group Details ===');
      print('Group ID: ${widget.groupId}');
      print('Current Username: $username');
      print('Group Data: ${widget.group}');

      final response = await http.get(
        Uri.parse('http://192.168.31.36:8000/api/groups/${widget.groupId}/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _groupDetails = {
            'id': data['id'],
            'name': data['name'] ?? '',
            'activity_type': data['activity_type'] ?? '',
            'location': data['location'] ?? '',
            'schedule': data['schedule'] ?? '',
            'description': data['description'] ?? '',
            'created_at': data['created_at'] ?? '',
            'updated_at': data['updated_at'] ?? '',
            'organizer_name': data['organizer_name'] ?? '',
            'member_count': data['member_count'] ?? 0,
            'is_organizer': data['is_organizer'] ?? false,
            'current_username': username,
          };

          // Update members list from the same response
          _members = (data['members'] as List<dynamic>? ?? []).map((member) {
            String imageUrl = member['profile_image'] ?? '';
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = 'http://192.168.31.36:8000$imageUrl';
            }

            return {
              'id': member['id'],
              'username': member['username'] ?? '',
              'profile_image': imageUrl,
              'role': 'Member',
            };
          }).toList();

          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load group details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading group details: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkJoinRequestStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(
            'http://192.168.31.36:8000/api/groups/${widget.groupId}/join-status/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _joinRequestStatus = data['status'];
        });
      }
    } catch (e) {
      print('Error checking join status: $e');
    }
  }

  Future<void> _sendJoinRequest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse(
            'http://192.168.31.36:8000/api/groups/${widget.groupId}/request-join/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _joinRequestStatus = 'pending';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Join request sent successfully!')),
        );
      } else {
        throw Exception('Failed to send join request');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadJoinRequests() async {
    if (!widget.isOrganizer) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('\n=== Loading Join Requests ===');
      final response = await http.get(
        Uri.parse(
            'http://192.168.31.36:8000/api/groups/${widget.groupId}/request-join/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _joinRequests = data.map((request) {
            String imageUrl = request['user']['profile_image'] ?? '';
            if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
              imageUrl = 'http://192.168.31.36:8000$imageUrl';
            }

            return {
              'id': request['id'],
              'user_id': request['user']['id'],
              'username': request['user']['username'] ?? '',
              'profile_image': imageUrl,
              'status': request['status'] ?? 'pending',
              'created_at': request['created_at'] ?? '',
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading join requests: $e');
    }
  }

  Future<void> _handleJoinRequest(String requestId, String action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Get the username from the request data
      final request = _joinRequests.firstWhere(
        (req) => req['id'].toString() == requestId,
        orElse: () => throw Exception('Request not found'),
      );
      final username = request['username'];

      print('\n=== Handling Join Request ===');
      print('Group ID: ${widget.groupId}');
      print('Username: $username');
      print('Action: $action');

      final response = await http.post(
        Uri.parse(
            'http://192.168.31.36:8000/api/groups/${widget.groupId}/requests/$username/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'action': action}),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Update the local state
        setState(() {
          final index = _joinRequests
              .indexWhere((req) => req['id'].toString() == requestId);
          if (index != -1) {
            _joinRequests[index]['status'] = action;
          }
        });

        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'approve'
                ? 'Member approved successfully'
                : 'Request rejected successfully'),
            backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          ),
        );

        // Refresh the requests and group details (which includes members)
        _loadJoinRequests();
        _loadGroupDetails(); // This will update both group details and members list
      } else {
        throw Exception('Failed to ${action} request: ${response.statusCode}');
      }
    } catch (e) {
      print('Error handling join request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetailsTab(Map<String, dynamic> groupData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              groupData['activity_type'] ?? 'No Activity',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Organized by ${groupData['organizer_name'] ?? 'Unknown'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Schedule & Location Card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule & Location',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          context,
                          Icons.schedule,
                          'Schedule',
                          groupData['schedule'] ?? 'Not specified',
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailItem(
                          context,
                          Icons.location_on,
                          'Location',
                          groupData['location'] ?? 'Not specified',
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description Card
          if (groupData['description']?.isNotEmpty ?? false)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About This Group',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      groupData['description'] ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Contact Organizer Card
          if (!widget.isOrganizer) // Only show for non-organizers
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Organizer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                groupData['organizer_name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const Text('Group Organizer'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return const Center(
        child: Text('No members in this group yet'),
      );
    }

    return ListView.builder(
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        final isOrganizer =
            member['username'] == _groupDetails?['organizer_name'];

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: member['profile_image']?.isNotEmpty ?? false
                ? NetworkImage(member['profile_image'])
                : null,
            child: member['profile_image']?.isEmpty ?? true
                ? const Icon(Icons.person)
                : null,
          ),
          title: Row(
            children: [
              Text(member['username'] ?? 'Unknown'),
              if (isOrganizer) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Organizer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(isOrganizer ? 'Group Organizer' : 'Member'),
        );
      },
    );
  }

  Widget _buildChatTab() {
    // Only show chat if user is a member or organizer
    final isMember = _members.any(
        (member) => member['username'] == _groupDetails?['current_username']);

    if (!isMember && !widget.isOrganizer) {
      return const Center(
        child: Text('Join the group to participate in chat'),
      );
    }

    return GroupChat(
      groupId: widget.groupId,
      groupName: _groupDetails?['name'] ?? '',
      isOrganizer: widget.isOrganizer,
    );
  }

  Widget _buildRequestsTab() {
    if (_joinRequests.isEmpty) {
      return const Center(
        child: Text('No pending join requests'),
      );
    }

    return ListView.builder(
      itemCount: _joinRequests.length,
      itemBuilder: (context, index) {
        final request = _joinRequests[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage:
                          request['profile_image']?.isNotEmpty ?? false
                              ? NetworkImage(request['profile_image'])
                              : null,
                      child: request['profile_image']?.isEmpty ?? true
                          ? const Icon(Icons.person, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['username'] ?? 'Unknown User',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Requested: ${_formatDate(request['created_at'])}',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Status: ${request['status']?.toUpperCase() ?? 'PENDING'}',
                            style: TextStyle(
                              color: _getStatusColor(request['status']),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (request['status'] == 'pending') ...[
                      TextButton(
                        onPressed: () => _handleJoinRequest(
                            request['id'].toString(), 'reject'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _handleJoinRequest(
                            request['id'].toString(), 'approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approve'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupData = _groupDetails ?? widget.group;
    final isMember = _members.any(
        (member) => member['username'] == _groupDetails?['current_username']);

    if (_tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(groupData['name'] ?? ''),
        actions: [
          if (groupData['is_organizer'] == true)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditGroupPage(group: groupData),
                  ),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController!,
          tabs: [
            const Tab(text: 'Details'),
            const Tab(text: 'Members'),
            if (widget.isOrganizer) const Tab(text: 'Requests'),
            const Tab(text: 'Chat'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadGroupDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController!,
                  children: [
                    _buildDetailsTab(groupData),
                    _buildMembersTab(),
                    if (widget.isOrganizer) _buildRequestsTab(),
                    _buildChatTab(),
                  ],
                ),
      floatingActionButton: (!isMember && !widget.isOrganizer)
          ? FloatingActionButton.extended(
              onPressed: _joinRequestStatus == null ? _sendJoinRequest : null,
              label: Text(_getJoinButtonText()),
              icon: const Icon(Icons.group_add),
            )
          : null,
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : 'Not specified',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not available';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _getJoinButtonText() {
    switch (_joinRequestStatus) {
      case 'pending':
        return 'Request Pending';
      case 'approved':
        return 'Already Member';
      case 'rejected':
        return 'Request Rejected';
      default:
        return 'Join Group';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<bool> _isUserMember() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');
      return _members.any((member) => member['username'] == username);
    } catch (e) {
      print('Error checking member status: $e');
      return false;
    }
  }
}
