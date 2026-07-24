import 'package:flutter/material.dart';
import 'package:foodsaver/core/components/statistic_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class VolunteerProfileScreen extends StatelessWidget {
  const VolunteerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/volunteer-settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person_pin, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Jane Smith', // Dummy data
              style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'jane.smith@example.com', // Dummy data
              style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                StatisticCard(
                  title: 'Completed Pickups',
                  value: '28', // Dummy data
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                StatisticCard(
                  title: 'Community Rating',
                  value: '4.9/5', // Dummy data
                  icon: Icons.star,
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildMenuList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Column(
      children: [
        _buildMenuListItem(context,
            icon: Icons.history,
            title: 'Pickup History',
            onTap: () => context.push('/volunteer-history')),
        _buildMenuListItem(context,
            icon: Icons.edit,
            title: 'Edit Profile',
            onTap: () => context.push('/edit-profile')),
        _buildMenuListItem(context,
            icon: Icons.qr_code_scanner,
            title: 'Scan QR Code',
            onTap: () => context.push('/qr-scan')),
        _buildMenuListItem(context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => context.push('/help-support')),
        _buildMenuListItem(context,
            icon: Icons.logout, title: 'Logout', onTap: () => context.go('/login'), isLogout: true),
      ],
    );
  }

  Widget _buildMenuListItem(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      bool isLogout = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : Theme.of(context).primaryColor),
        title: Text(title, style: GoogleFonts.lato(fontWeight: FontWeight.w600, color: isLogout ? Colors.red : null)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
