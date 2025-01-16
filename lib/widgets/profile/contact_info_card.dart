import 'package:flutter/material.dart';
import '../../models/profile.dart';

class ContactInfoCard extends StatelessWidget {
  final Profile profile;

  const ContactInfoCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildContactList(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactList() {
    final hasEmail = profile.contactInfo['email']?.isNotEmpty == true &&
        profile.privacySettings['showEmail'] == true;
    final hasPhone = profile.contactInfo['phone']?.isNotEmpty == true &&
        profile.privacySettings['showPhone'] == true;
    final hasLocation = profile.contactInfo['location']?.isNotEmpty == true &&
        profile.privacySettings['showLocation'] == true;

    if (!hasEmail && !hasPhone && !hasLocation) {
      return const Center(
        child: Text(
          'No contact information available',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: [
        if (hasEmail)
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(profile.contactInfo['email']!),
          ),
        if (hasPhone)
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Phone'),
            subtitle: Text(profile.contactInfo['phone']!),
          ),
        if (hasLocation)
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Location'),
            subtitle: Text(profile.contactInfo['location']!),
          ),
      ],
    );
  }
} 