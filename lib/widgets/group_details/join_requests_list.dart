import 'package:flutter/material.dart';
import '../../models/group_details.dart';
import '../../services/group_service.dart';

class JoinRequestsList extends StatelessWidget {
  final List<JoinRequest> requests;
  final String groupId;
  final Function() onRequestHandled;

  const JoinRequestsList({
    super.key,
    required this.requests,
    required this.groupId,
    required this.onRequestHandled,
  });

  Future<void> _handleJoinRequest(
      BuildContext context, JoinRequest request, String action) async {
    try {
      final groupService = GroupService();
      await groupService.handleJoinRequest(groupId, request.username, action);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'approve'
              ? 'Member approved successfully'
              : 'Request rejected successfully'),
          backgroundColor: action == 'approve' ? Colors.green : Colors.red,
        ),
      );

      // Wait for a moment to ensure the notification is processed
      await Future.delayed(const Duration(milliseconds: 500));
      onRequestHandled();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return ListView(
        children: const [
          Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No pending join requests',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: requests.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final request = requests[index];
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
                      backgroundImage: request.profileImage.isNotEmpty
                          ? NetworkImage(request.profileImage)
                          : null,
                      child: request.profileImage.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.username,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Requested: ${_formatDate(request.createdAt)}',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
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
                      onPressed: () =>
                          _handleJoinRequest(context, request, 'reject'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () =>
                          _handleJoinRequest(context, request, 'approve'),
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
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Not available';
    }
  }
}
