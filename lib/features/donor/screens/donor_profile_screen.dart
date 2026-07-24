import 'package:flutter/material.dart';
import 'package:foodsaver/core/components/statistic_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class DonorProfileScreen extends StatelessWidget {
  const DonorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/donor-settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const CircleAvatar(
              radius: 50,
              // Replace with a network image in a real app
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'John Doe', // Dummy data
              style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'john.doe@example.com', // Dummy data
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
                  title: 'Completed Donations',
                  value: '12', // Dummy data
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                StatisticCard(
                  title: 'Active Donations',
                  value: '3', // Dummy data
                  icon: Icons.local_shipping,
                  color: Colors.blue,
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
            title: 'Donation History',
            onTap: () => context.push('/donation-history')),
        _buildMenuListItem(context,
            icon: Icons.edit,
            title: 'Edit Profile',
            onTap: () => context.push('/edit-profile')), // To be created
        _buildMenuListItem(context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => context.push('/help-support')), // To be created
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
