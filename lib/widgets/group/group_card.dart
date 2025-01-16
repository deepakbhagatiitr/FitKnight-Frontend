import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../screens/group_details_page.dart';

class GroupCard extends StatelessWidget {
  final Group group;

  const GroupCard({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: group.imageUrl.isNotEmpty
                  ? NetworkImage(group.imageUrl)
                  : null,
              child: group.imageUrl.isEmpty ? const Icon(Icons.group) : null,
            ),
            title: Text(group.name),
            subtitle: Text('${group.activity} • ${group.location}'),
            trailing: Text('${group.members} members'),
          ),
          ButtonBar(
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupDetailsPage(
                        group: group.toJson(),
                        groupId: group.id.toString(),
                      ),
                    ),
                  );
                },
                child: const Text('View Details'),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implement manage members
                },
                child: const Text('Manage Members'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 