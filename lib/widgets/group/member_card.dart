import 'package:flutter/material.dart';
import '../../models/member.dart';

class MemberCard extends StatelessWidget {
  final Member member;

  const MemberCard({
    super.key,
    required this.member,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              member.imageUrl.isNotEmpty ? NetworkImage(member.imageUrl) : null,
          child: member.imageUrl.isEmpty ? const Icon(Icons.person) : null,
        ),
        title: Text(member.username),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goals: ${member.fitnessGoals}'),
            Text('Available: ${member.availability}'),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
} 