import 'package:flutter/material.dart';
import '../../models/group_details.dart';

class OrganizerContactCard extends StatelessWidget {
  final GroupDetails groupData;

  const OrganizerContactCard({
    super.key,
    required this.groupData,
  });

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                  backgroundColor:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  child: Icon(Icons.person,
                      color: Theme.of(context).colorScheme.secondary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groupData.organizerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Text('Group Organizer'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            if (groupData.organizerPhone.isNotEmpty)
              _buildContactRow(Icons.phone, groupData.organizerPhone),
            if (groupData.organizerEmail.isNotEmpty)
              _buildContactRow(Icons.email, groupData.organizerEmail),
            if (groupData.organizerLocation.isNotEmpty)
              _buildContactRow(Icons.location_on, groupData.organizerLocation),
          ],
        ),
      ),
    );
  }
}
