import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileImagePicker extends StatelessWidget {
  final File? profileImage;
  final Function(File) onImagePicked;

  const ProfileImagePicker({
    super.key,
    required this.profileImage,
    required this.onImagePicked,
  });

  Future<void> _pickImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        onImagePicked(File(image.path));
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (profileImage != null)
          Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: FileImage(profileImage!),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            width: 120,
            height: 120,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey,
            ),
            child: const Icon(
              Icons.person,
              size: 80,
              color: Colors.white,
            ),
          ),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.add_a_photo),
          label: Text(profileImage == null ? 'Upload Profile Picture' : 'Change Profile Picture'),
        ),
      ],
    );
  }
} 