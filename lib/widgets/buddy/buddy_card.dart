import 'package:flutter/material.dart';
import '../../models/buddy.dart';

class BuddyCard extends StatelessWidget {
  final Buddy buddy;

  const BuddyCard({
    super.key,
    required this.buddy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: buddy.imageUrl.isNotEmpty
                  ? NetworkImage(buddy.imageUrl)
                  : null,
              child: buddy.imageUrl.isEmpty
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              buddy.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              buddy.activity,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Available: ${buddy.availability}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
} 