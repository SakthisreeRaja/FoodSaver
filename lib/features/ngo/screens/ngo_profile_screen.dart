import 'package:flutter/material.dart';
import 'package:foodsaver/core/components/statistic_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class NgoProfileScreen extends StatelessWidget {
  const NgoProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NGO Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/ngo-settings'),
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
              child: Icon(Icons.business, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Green Valley Community', // Dummy data
              style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'contact@greenvalley.org', // Dummy data
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
                  title: 'Donations Received',
                  value: '152', // Dummy data
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                StatisticCard(
                  title: 'Active Pickups',
                  value: '5', // Dummy data
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
            icon: Icons.bar_chart,
            title: 'View Statistics',
            onTap: () => context.push('/ngo-statistics')), // To be created
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
