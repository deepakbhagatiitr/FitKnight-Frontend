import 'package:flutter/material.dart';
import '../../models/group_details.dart';

class MembersList extends StatelessWidget {
  final List<GroupMember> members;
  final String organizerName;

  const MembersList({
    super.key,
    required this.members,
    required this.organizerName,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Center(child: Text('No members in this group yet'));
    }

    return ListView.builder(
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        final isOrganizer = member.username == organizerName;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: member.profileImage.isNotEmpty
                ? NetworkImage(member.profileImage)
                : null,
            child: member.profileImage.isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          title: Row(
            children: [
              Text(member.username),
              if (isOrganizer) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Organizer',
                    style: TextStyle(color: Colors.white, fontSize: 12),
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
} 