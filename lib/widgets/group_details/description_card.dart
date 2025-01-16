import 'package:flutter/material.dart';
import '../../models/group_details.dart';

class DescriptionCard extends StatelessWidget {
  final GroupDetails groupData;

  const DescriptionCard({
    super.key,
    required this.groupData,
  });

  @override
  Widget build(BuildContext context) {
    if (groupData.description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
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
              groupData.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 