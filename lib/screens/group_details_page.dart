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
  bool _isOrganizerOrMember = false;
  String? _currentUsername;
  List<Tab> _tabs = [];
  List<Widget> _tabViews = [];

  @override
  void initState() {
    super.initState();
    _getCurrentUsername();
    _loadGroupDetails();
  }

  void _setupTabs() {
    final isOrganizer = _groupDetails?['organizer_name'] == _currentUsername;

    // Initialize tabs
    _tabs = [
      const Tab(text: 'Details'),
      const Tab(text: 'Members'),
    ];

    // Initialize tab views
    _tabViews = [
      _buildDetailsTab(_groupDetails ?? widget.group),
      _buildMembersTab(),
    ];

    // Add Requests tab if user is organizer
    if (isOrganizer) {
      _tabs.add(const Tab(text: 'Requests'));
      _tabViews.add(_buildRequestsTab());
      // Load requests immediately if user is organizer
      _loadJoinRequests().then((_) {
        // Update the requests tab view after loading
        if (mounted) {
          setState(() {
            // Update the requests tab view with the latest data
            _tabViews[2] = _buildRequestsTab();
          });
        }
      });
    }

    // Add Chat tab if user is organizer or member
    if (_isOrganizerOrMember) {
      _tabs.add(const Tab(text: 'Chat'));
      _tabViews.add(_buildChatTab());
    }

    // Initialize TabController after tabs are set up
    _tabController?.dispose(); // Dispose old controller if it exists
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
    );

    // Add listener for tab changes
    _tabController!.addListener(() {
      // Check if this is the Requests tab and it's selected
      if (_tabController!.index == 2 && isOrganizer) {
        print('\n=== Requests Tab Selected ===');
        _loadJoinRequests().then((_) {
          // Update the requests tab view after loading
          if (mounted) {
            setState(() {
              // Update the requests tab view with the latest data
              _tabViews[2] = _buildRequestsTab();
            });
          }
        });
      }
    });

    if (mounted) {
      setState(() {});
    }
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
      _currentUsername = username; // Set current username immediately

      print('\n=== Loading Group Details ===');
      print('Current Username from SharedPrefs: $username');

      if (token == null || username == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('http://192.168.31.36:8000/api/groups/${widget.groupId}/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final organizerUsername = data['organizer_name'] ?? '';
        final isOrganizer = username == organizerUsername;

        // Process members list first
        final membersList =
            (data['members'] as List<dynamic>? ?? []).map((member) {
          String imageUrl = member['profile_image'] ?? '';
          if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
            imageUrl = 'http://192.168.31.36:8000$imageUrl';
          }
          return {
            'id': member['id'],
            'username': member['username'] ?? '',
            'profile_image': imageUrl,
            'role': member['username'] == organizerUsername
                ? 'Organizer'
                : 'Member',
          };
        }).toList();

        // Check if current user is a member
        final isMember =
            membersList.any((member) => member['username'] == username);

        print('\n=== Access Check ===');
        print('Username: $username');
        print('Organizer: $organizerUsername');
        print('Is Organizer: $isOrganizer');
        print('Is Member: $isMember');
        print('Members: ${membersList.map((m) => m['username']).toList()}');

        setState(() {
          _members = membersList;
          _isOrganizerOrMember =
              isOrganizer || isMember; // Set based on both conditions
          _groupDetails = {
            'id': data['id'],
            'name': data['name'] ?? '',
            'activity_type': data['activity_type'] ?? '',
            'location': data['location'] ?? '',
            'schedule': data['schedule'] ?? '',
            'description': data['description'] ?? '',
            'created_at': data['created_at'] ?? '',
            'organizer_name': organizerUsername,
            'is_organizer': isOrganizer,
          };
          _isLoading = false;
        });

        // Set up tabs after data is loaded and roles are determined
        _setupTabs();

        // Load join requests if user is organizer
        if (isOrganizer) {
          await _loadJoinRequests();
        }

        // Check join request status if user is neither organizer nor member
        if (!isOrganizer && !isMember) {
          await _checkJoinRequestStatus();
        }
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

      print('\n=== Checking Join Request Status ===');
      print('Group ID: ${widget.groupId}');

      final response = await http.get(
        Uri.parse('http://192.168.31.36:8000/api/groups/join-requests/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> requests = jsonDecode(response.body);

        final request = requests.firstWhere(
          (req) => req['group']['id'].toString() == widget.groupId,
          orElse: () => {'status': null},
        );

        setState(() {
          _joinRequestStatus = request['status'];
        });

        print('Join Request Status: $_joinRequestStatus');
      }
    } catch (e) {
      print('Error checking join request status: $e');
      setState(() {
        _joinRequestStatus = null;
      });
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
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('\n=== Loading Join Requests ===');
      print('Group ID: ${widget.groupId}');
      final url =
          'http://192.168.31.36:8000/api/groups/${widget.groupId}/request-join/';
      print('API URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      print('\n=== Join Requests API Response ===');
      print('Status Code: ${response.statusCode}');
      print('Raw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _joinRequests = data.map((request) {
              String imageUrl = request['user']['profile_image'] ?? '';
              if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                imageUrl = 'http://192.168.31.36:8000$imageUrl';
              }

              return {
                'id': request['id'],
                'user_id': request['user']['id'],
                'username': request['user']['username'],
                'profile_image': imageUrl,
                'status':
                    request['status']?.toString().toLowerCase() ?? 'pending',
                'created_at': request['created_at'],
              };
            }).toList();
            _isLoading = false;
          });

          // Force update the requests tab view
          final requestsTabIndex =
              _tabs.indexWhere((tab) => tab.text == 'Requests');
          if (requestsTabIndex != -1) {
            setState(() {
              _tabViews[requestsTabIndex] = _buildRequestsTab();
            });
          }
        }
      }
    } catch (e) {
      print('\n=== Error in Loading Join Requests ===');
      print('Error Details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _handleJoinRequest(String requestId, String action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Find the request in our list
      final request = _joinRequests.firstWhere(
        (req) => req['id'].toString() == requestId,
        orElse: () => throw Exception('Request not found'),
      );

      print('\n=== Handling Join Request ===');
      print('Request ID: $requestId');
      print('Request Data: $request');
      print('Action: $action');
      print('Group ID: ${widget.groupId}');
      print('Username: ${request['username']}');

      // Construct the URL with the correct format
      final url =
          'http://192.168.31.36:8000/api/groups/${widget.groupId}/requests/${request['username']}/';
      print('API URL: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'action': action}),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Request handled successfully');

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

        // Refresh data
        print('Refreshing data after successful action');
        await _loadJoinRequests(); // Reload requests
        await _loadGroupDetails(); // Reload group details to update members list
      } else {
        print('Failed to handle request');
        throw Exception(
            'Failed to ${action} request: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('\n=== Error in Handle Join Request ===');
      print('Error Details: $e');
      print('Stack Trace: ${StackTrace.current}');

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
          if (!widget.isOrganizer)
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
    if (_currentUsername == null) {
      return const Center(
        child: Text('Authentication required'),
      );
    }

    // Check if user is organizer
    final isOrganizer = _groupDetails?['organizer_name'] == _currentUsername;

    // Check if user is member
    final isMember =
        _members.any((member) => member['username'] == _currentUsername);

    print('\n=== Chat Access Check ===');
    print('Current Username: $_currentUsername');
    print('Organizer Name: ${_groupDetails?['organizer_name']}');
    print('Is Organizer: $isOrganizer');
    print('Is Member: $isMember');
    print('Members: ${_members.map((m) => m['username']).toList()}');

    if (!isOrganizer && !isMember) {
      return const Center(
        child: Text('Join the group to participate in chat'),
      );
    }

    return GroupChat(
      groupId: widget.groupId,
      groupName: _groupDetails?['name'] ?? '',
      isOrganizer: isOrganizer,
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    print('\n=== Building Requests Tab ===');
    print('Total Requests: ${_joinRequests.length}');

    // Filter only pending requests
    final pendingRequests = _joinRequests.where((request) {
      final status = request['status']?.toString().toLowerCase() ?? '';
      print(
          'Checking request - Username: ${request['username']}, Status: $status');
      return status == 'pending';
    }).toList();

    print('Found ${pendingRequests.length} pending requests');
    for (var request in pendingRequests) {
      print('Pending request from: ${request['username']}');
    }

    return RefreshIndicator(
      onRefresh: _loadJoinRequests,
      child: pendingRequests.isEmpty
          ? ListView(
              // Wrap empty message in ListView for RefreshIndicator
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No pending join requests',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              itemCount: pendingRequests.length, // Changed this line
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final request = pendingRequests[index];
                print(
                    'Building request item for: ${request['username']} with status: ${request['status']}');

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage:
                                  request['profile_image']?.isNotEmpty ?? false
                                      ? NetworkImage(request['profile_image'])
                                      : null,
                              child: request['profile_image']?.isEmpty ?? true
                                  ? const Icon(Icons.person)
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Requested: ${_formatDate(request['created_at'])}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'PENDING',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _handleJoinRequest(
                                request['id'].toString(),
                                'reject',
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () => _handleJoinRequest(
                                request['id'].toString(),
                                'approve',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tabController == null || _tabs.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
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
        ),
      );
    }

    final groupData = _groupDetails ?? widget.group;
    final isOrganizer = groupData['organizer_name'] == _currentUsername;

    return Scaffold(
      appBar: AppBar(
        title: Text(groupData['name'] ?? ''),
        actions: [
          if (isOrganizer)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Convert schedule to string safely
                String scheduleStr = '';
                if (groupData['schedule'] != null) {
                  scheduleStr = groupData['schedule'].toString();
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditGroupPage(
                      groupId: int.parse(widget.groupId),
                      currentName: groupData['name'] ?? '',
                      currentDescription: groupData['description'] ?? '',
                      currentActivityType: groupData['activity_type'] ?? '',
                      currentSchedule: scheduleStr,  // Pass as string
                    ),
                  ),
                ).then((edited) {
                  if (edited == true) {
                    _loadGroupDetails();
                  }
                });
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabViews,
      ),
      floatingActionButton: (!isOrganizer && !_isOrganizerOrMember)
          ? FloatingActionButton.extended(
              onPressed: _joinRequestStatus == null ? _sendJoinRequest : null,
              label: Text(_getJoinButtonText()),
              icon: const Icon(Icons.group_add),
              backgroundColor: _getButtonColor(),
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

  Color _getButtonColor() {
    switch (_joinRequestStatus) {
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case null:
        return Theme.of(context).colorScheme.primary;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('username');

      print('\n=== Getting Current Username ===');
      print('Username from SharedPreferences: $username');

      setState(() {
        _currentUsername = username;
      });
    } catch (e) {
      print('Error getting username: $e');
      setState(() {
        _error = 'Failed to get username';
      });
    }
  }
}
