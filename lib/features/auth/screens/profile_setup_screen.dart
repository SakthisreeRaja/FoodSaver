import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/components/primary_button.dart';
import '../../../core/components/custom_text_field.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _avatar;

  Future<void> _pickAvatar() async {
    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        setState(() => _avatar = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick a photo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: _avatar != null ? FileImage(File(_avatar!.path)) : null,
                  child: _avatar == null
                      ? const Icon(Icons.add_a_photo, size: 32, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CustomTextField(label: "Phone Number", icon: Icons.phone_outlined),
            const SizedBox(height: 16),
            const CustomTextField(label: "Organization / Location", icon: Icons.location_on_outlined),
            const SizedBox(height: 40),
            PrimaryButton(
              text: "Complete Setup",
              onPressed: () => context.go('/role-selection'),
            ),
          ],
        ),
      ),
    );
  }
}
