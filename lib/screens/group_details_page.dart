import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/edit_group_page.dart';
import '../components/chat/group_chat.dart';
import '../screens/notifications_page.dart';
import '../models/group_details.dart';
import '../services/group_service.dart';
import '../widgets/group_details/group_header.dart';
import '../widgets/group_details/schedule_location_card.dart';
import '../widgets/group_details/description_card.dart';
import '../widgets/group_details/organizer_contact_card.dart';
import '../widgets/group_details/members_list.dart';
import '../widgets/group_details/join_requests_list.dart';

class GroupDetailsPage extends StatefulWidget {
  final Map<String, dynamic> group;
  final String groupId;
  final bool isOrganizer;

  const GroupDetailsPage({
    super.key,
    required this.group,
    required this.groupId,
    this.isOrganizer = false,
  });

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage>
    with TickerProviderStateMixin {
  // Controllers
  TabController? _tabController;

  // State variables
  bool _isLoading = true;
  GroupDetails? _groupDetails;
  List<GroupMember> _members = [];
  String? _error;
  List<JoinRequest> _joinRequests = [];
  String? _joinRequestStatus;
  bool _isOrganizerOrMember = false;
  String? _currentUsername;
  List<Tab> _tabs = [];
  List<Widget> _tabViews = [];

  // Services
  final _groupService = GroupService();

  // Lifecycle methods
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // Data Loading Methods
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _currentUsername = await _groupService.getCurrentUsername();
      if (_currentUsername == null) {
        throw Exception('Authentication required');
      }

      final data = await _groupService.fetchGroupDetails(widget.groupId);

      setState(() {
        _groupDetails = data['details'] as GroupDetails;
        _members = data['members'] as List<GroupMember>;
        _isOrganizerOrMember = data['isOrganizerOrMember'] as bool;
        _isLoading = false;
      });

      _setupTabs();

      if (_groupDetails?.isOrganizer ?? false) {
        await _loadJoinRequests();
      }

      if (!(_groupDetails?.isOrganizer ?? false) && !_isOrganizerOrMember) {
        await _checkJoinRequestStatus();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkJoinRequestStatus() async {
    try {
      final status = await _groupService.checkJoinRequestStatus(widget.groupId);
      print('Received join request status: $status'); // Debug print
      if (mounted) {
        setState(() {
          _joinRequestStatus = status?.toLowerCase();
        });
      }
    } catch (e) {
      print('Error checking join request status: $e');
    }
  }

  Future<void> _sendJoinRequest() async {
    if (!_canSendJoinRequest()) return;

    try {
      await _groupService.sendJoinRequest(widget.groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Join request sent successfully')),
        );
        await _checkJoinRequestStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending join request: $e')),
        );
      }
    }
  }

  Future<void> _loadJoinRequests() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final requests = await _groupService.fetchJoinRequests(widget.groupId);

      if (mounted) {
        setState(() {
          _joinRequests =
              requests.where((request) => request.status == 'pending').toList();
          _isLoading = false;
        });

        final requestsTabIndex =
            _tabs.indexWhere((tab) => tab.text == 'Requests');
        if (requestsTabIndex != -1) {
          setState(() {
            _tabViews[requestsTabIndex] = _buildRequestsTab();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Tab Management
  void _setupTabs() {
    // Initialize tabs
    _tabs = [
      const Tab(text: 'Details'),
      const Tab(text: 'Members'),
    ];

    // Initialize tab views
    _tabViews = [
      _buildDetailsTab(),
      _buildMembersTab(),
    ];

    // Add Requests tab if user is organizer
    if (_groupDetails?.isOrganizer ?? false) {
      _tabs.add(const Tab(text: 'Requests'));
      _tabViews.add(_buildRequestsTab());
    }

    // Add Chat tab if user is organizer or member
    if (_isOrganizerOrMember) {
      _tabs.add(const Tab(text: 'Chat'));
      _tabViews.add(_buildChatTab());
    }

    // Initialize TabController
    _tabController?.dispose();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
    );

    // Add listener for tab changes
    _tabController!.addListener(() {
      if (_tabController!.index == 2 && (_groupDetails?.isOrganizer ?? false)) {
        _loadJoinRequests();
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  // UI Building Methods
  Widget _buildDetailsTab() {
    if (_groupDetails == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GroupHeader(groupData: _groupDetails!),
          const SizedBox(height: 16),
          ScheduleLocationCard(groupData: _groupDetails!),
          const SizedBox(height: 16),
          DescriptionCard(groupData: _groupDetails!),
          const SizedBox(height: 16),
          if (!widget.isOrganizer)
            OrganizerContactCard(groupData: _groupDetails!),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return MembersList(
      members: _members,
      organizerName: _groupDetails?.organizerName ?? '',
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadJoinRequests,
      child: JoinRequestsList(
        requests: _joinRequests,
        groupId: widget.groupId,
        onRequestHandled: () async {
          await _loadJoinRequests();
          await _loadData();
        },
      ),
    );
  }

  Widget _buildChatTab() {
    if (_currentUsername == null) {
      return const Center(child: Text('Authentication required'));
    }

    if (!_isOrganizerOrMember) {
      return const Center(child: Text('Join the group to participate in chat'));
    }

    return GroupChat(
      groupId: widget.groupId,
      groupName: _groupDetails?.name ?? '',
      isOrganizer: _groupDetails?.isOrganizer ?? false,
    );
  }

  String _getJoinButtonText() {
    print('Current join request status: $_joinRequestStatus'); // Debug print
    switch (_joinRequestStatus?.toLowerCase()) {
      case 'pending':
        return 'Request Pending';
      case 'approved':
        return 'Already Member';
      case 'rejected':
        return 'Request Again';
      default:
        return 'Join Group';
    }
  }

  Color _getButtonColor() {
    switch (_joinRequestStatus?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Theme.of(context).colorScheme.primary;
      case null:
        return Theme.of(context).colorScheme.primary;
      default:
        return Colors.grey;
    }
  }

  bool _canSendJoinRequest() {
    // Allow join request if status is null (never requested) or rejected
    return _joinRequestStatus == null ||
        _joinRequestStatus?.toLowerCase() == 'rejected';
  }

  void _navigateToEditPage() {
    if (_groupDetails == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditGroupPage(
          groupId: int.parse(widget.groupId),
          currentName: _groupDetails!.name,
          currentDescription: _groupDetails!.description,
          currentActivityType: _groupDetails!.activityType,
          currentSchedule: _groupDetails!.schedule,
        ),
      ),
    ).then((edited) {
      if (edited == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tabController == null || _tabs.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_groupDetails?.name ?? ''),
        actions: [
          if (_groupDetails?.isOrganizer ?? false)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEditPage,
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
      floatingActionButton:
          (!(_groupDetails?.isOrganizer ?? false) && !_isOrganizerOrMember)
              ? FloatingActionButton.extended(
                  onPressed: _canSendJoinRequest() ? _sendJoinRequest : null,
                  label: Text(_getJoinButtonText()),
                  icon: const Icon(Icons.group_add),
                  backgroundColor: _getButtonColor(),
                )
              : null,
    );
  }
}
