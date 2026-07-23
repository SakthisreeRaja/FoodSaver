import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/primary_button.dart';
import '../../../core/components/custom_text_field.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                child: Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
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