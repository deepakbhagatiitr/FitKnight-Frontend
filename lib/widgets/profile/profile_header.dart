import 'package:flutter/material.dart';
import '../../models/profile.dart';

class ProfileHeader extends StatelessWidget {
  final Profile profile;
  final ImageProvider Function(String) getProfileImage;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.getProfileImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: getProfileImage(profile.imageUrl),
            onBackgroundImageError: (exception, stackTrace) {
              print('Error loading profile image: $exception');
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (profile.bio.isNotEmpty)
                  Text(
                    profile.bio,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
