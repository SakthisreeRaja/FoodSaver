import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class DonorSettingsScreen extends StatelessWidget {
  const DonorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: <Widget>[
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            context,
            title: 'Edit Profile',
            icon: Icons.person,
            onTap: () => context.push('/edit-profile'), // To be created
          ),
          _buildSettingsTile(
            context,
            title: 'Change Password',
            icon: Icons.lock,
            onTap: () {
              // TODO: Navigate to Change Password Screen
            },
          ),
          const Divider(),
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: Text('Push Notifications', style: GoogleFonts.lato()),
            secondary: const Icon(Icons.notifications),
            value: true, // Dummy value
            onChanged: (bool value) {
              // Dummy implementation
            },
          ),
          SwitchListTile(
            title: Text('Email Notifications', style: GoogleFonts.lato()),
            secondary: const Icon(Icons.email),
            value: false, // Dummy value
            onChanged: (bool value) {
              // Dummy implementation
            },
          ),
          const Divider(),
          _buildSectionHeader('About'),
          _buildSettingsTile(
            context,
            title: 'Privacy Policy',
            icon: Icons.privacy_tip,
            onTap: () => context.push('/privacy-policy'), // To be created
          ),
          _buildSettingsTile(
            context,
            title: 'Terms & Conditions',
            icon: Icons.gavel,
            onTap: () => context.push('/terms-conditions'), // To be created
          ),
          _buildSettingsTile(
            context,
            title: 'About Us',
            icon: Icons.info,
            onTap: () => context.push('/about'), // To be created
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.lato(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required String title, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: GoogleFonts.lato()),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
