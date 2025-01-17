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
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailsPage(
                group: group.toJson(),
                groupId: group.id,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              trailing: Text('${group.memberCount} members'),
            ),
            if (group.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  group.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
